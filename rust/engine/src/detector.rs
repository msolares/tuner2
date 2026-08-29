use crate::input::ValidatedFrame;

const MAX_INTERNAL_CANDIDATES: usize = 6;

#[derive(Debug, Clone, Copy)]
pub struct Detection {
    pub hz: f32,
    pub signal_rms: f32,
    pub periodicity_hint: f32,
    pub clarity: f32,
    pub candidate_count: u8,
}

#[derive(Debug, Clone, Copy)]
pub struct DetectorConfig {
    pub min_hz: f32,
    pub max_hz: f32,
    pub noise_gate_db: f32,
}

impl Default for DetectorConfig {
    fn default() -> Self {
        Self {
            min_hz: 50.0,
            max_hz: 1200.0,
            noise_gate_db: -60.0,
        }
    }
}

#[derive(Debug, Clone, Copy, Default)]
struct Candidate {
    lag: f32,
    hz: f32,
    clarity: f32,
    score: f32,
}

impl Candidate {
    fn is_present(&self) -> bool {
        self.hz > 0.0 && self.clarity > 0.0
    }
}

#[derive(Debug, Clone, Copy)]
struct ResolutionResult {
    best: Candidate,
    second_score: f32,
    candidate_count: u8,
}

pub fn detect_pitch(
    frame: ValidatedFrame<'_>,
    config: DetectorConfig,
) -> Result<Detection, &'static str> {
    if frame.pcm.len() < 64 {
        return Err("frame_too_short");
    }

    let (min_hz, max_hz) = normalize_range(config.min_hz, config.max_hz);
    let sample_rate = frame.sample_rate as f32;

    let len = frame.pcm.len() as f32;
    let rms = (frame.pcm.iter().map(|sample| sample * sample).sum::<f32>() / len).sqrt();
    if rms <= 1e-8 {
        return Ok(zero_detection(rms));
    }

    let rms_db = 20.0 * rms.max(1e-12).log10();
    if rms_db < config.noise_gate_db {
        return Ok(zero_detection(rms));
    }

    let mean = frame.pcm.iter().sum::<f32>() / len;
    let centered: Vec<f32> = frame.pcm.iter().map(|sample| sample - mean).collect();
    let zero_crossing_rate = zero_crossing_rate(&centered);

    let primary_resolution = detect_resolution(&centered, sample_rate, min_hz, max_hz);
    let low_resolution = maybe_detect_low_resolution(&centered, sample_rate, min_hz, max_hz);
    let resolution = select_resolution(primary_resolution, low_resolution);
    let Some(best_candidate) = resolution.best.is_present().then_some(resolution.best) else {
        return Ok(zero_detection(rms));
    };

    if best_candidate.hz < min_hz || best_candidate.hz > max_hz {
        return Ok(zero_detection(rms));
    }

    let zero_crossing_pitch_hz = zero_crossing_rate * sample_rate * 0.5;
    if zero_crossing_pitch_hz > max_hz * 1.05 && zero_crossing_pitch_hz / best_candidate.hz > 1.7 {
        return Ok(zero_detection(rms));
    }

    let ambiguity_confidence = ambiguity_confidence(resolution.best.score, resolution.second_score);
    let periodicity_hint = (0.55 * best_candidate.clarity
        + 0.25 * ambiguity_confidence
        + 0.20 * zero_crossing_agreement(zero_crossing_rate, best_candidate.hz, frame.sample_rate))
    .clamp(0.0, 1.0);

    if periodicity_hint < 0.12 || best_candidate.clarity < 0.08 {
        return Ok(zero_detection(rms));
    }

    Ok(Detection {
        hz: best_candidate.hz,
        signal_rms: rms,
        periodicity_hint,
        clarity: best_candidate.clarity,
        candidate_count: resolution.candidate_count,
    })
}

fn zero_detection(signal_rms: f32) -> Detection {
    Detection {
        hz: 0.0,
        signal_rms,
        periodicity_hint: 0.0,
        clarity: 0.0,
        candidate_count: 0,
    }
}

fn normalize_range(min_hz: f32, max_hz: f32) -> (f32, f32) {
    let safe_min = min_hz.max(20.0);
    let safe_max = max_hz.max(safe_min + 1.0);
    (safe_min, safe_max)
}

fn detect_resolution(
    samples: &[f32],
    sample_rate: f32,
    min_hz: f32,
    max_hz: f32,
) -> ResolutionResult {
    if samples.len() < 64 || sample_rate <= 0.0 {
        return ResolutionResult {
            best: Candidate::default(),
            second_score: 0.0,
            candidate_count: 0,
        };
    }

    let min_lag = (sample_rate / max_hz).floor().max(2.0) as usize;
    let max_lag = (sample_rate / min_hz).ceil().clamp(
        (min_lag + 1) as f32,
        (samples.len().saturating_sub(2)) as f32,
    ) as usize;
    if max_lag <= min_lag {
        return ResolutionResult {
            best: Candidate::default(),
            second_score: 0.0,
            candidate_count: 0,
        };
    }

    let difference = difference_function(samples, max_lag);
    let cmndf = cumulative_mean_normalized_difference(&difference);
    let mut candidates = collect_candidates(&cmndf, min_lag, max_lag, sample_rate, min_hz, max_hz);
    if candidates.is_empty() {
        return ResolutionResult {
            best: Candidate::default(),
            second_score: 0.0,
            candidate_count: 0,
        };
    }

    let zero_crossing_rate = zero_crossing_rate(samples);
    score_candidates(
        &mut candidates,
        min_lag as f32,
        max_lag as f32,
        zero_crossing_rate,
        sample_rate,
    );
    candidates.sort_by(|left, right| {
        right
            .score
            .total_cmp(&left.score)
            .then_with(|| right.clarity.total_cmp(&left.clarity))
    });

    let best = candidates[0];
    let second_score = candidates.get(1).map_or(0.0, |candidate| candidate.score);
    ResolutionResult {
        best,
        second_score,
        candidate_count: candidates.len().min(u8::MAX as usize) as u8,
    }
}

fn maybe_detect_low_resolution(
    samples: &[f32],
    sample_rate: f32,
    min_hz: f32,
    max_hz: f32,
) -> Option<ResolutionResult> {
    if min_hz > 120.0 || samples.len() < 1024 || sample_rate < 16_000.0 {
        return None;
    }

    let decimated = decimate_by_two(samples);
    if decimated.len() < 256 {
        return None;
    }

    let decimated_result = detect_resolution(&decimated, sample_rate * 0.5, min_hz, max_hz);
    decimated_result
        .best
        .is_present()
        .then_some(decimated_result)
}

fn select_resolution(
    primary: ResolutionResult,
    low_resolution: Option<ResolutionResult>,
) -> ResolutionResult {
    let Some(low_resolution) = low_resolution else {
        return primary;
    };
    if !primary.best.is_present() {
        return low_resolution;
    }

    let primary_best = primary.best;
    let low_best = low_resolution.best;
    let harmonic_family = are_harmonic_family(primary_best.hz, low_best.hz);

    if low_best.hz <= 130.0 && low_best.score + 0.03 >= primary_best.score {
        return low_resolution;
    }

    if harmonic_family
        && low_best.hz < primary_best.hz
        && low_best.score + 0.10 >= primary_best.score
    {
        return low_resolution;
    }

    if low_best.score > primary_best.score {
        return low_resolution;
    }

    primary
}

fn difference_function(samples: &[f32], max_lag: usize) -> Vec<f32> {
    let mut difference = vec![0.0_f32; max_lag + 1];

    for lag in 1..=max_lag {
        let mut sum = 0.0_f32;
        for index in 0..(samples.len() - lag) {
            let delta = samples[index] - samples[index + lag];
            sum += delta * delta;
        }
        difference[lag] = sum;
    }

    difference
}

fn cumulative_mean_normalized_difference(difference: &[f32]) -> Vec<f32> {
    let mut cmndf = vec![1.0_f32; difference.len()];
    let mut running_sum = 0.0_f32;

    for lag in 1..difference.len() {
        running_sum += difference[lag];
        cmndf[lag] = if running_sum <= 1e-12 {
            1.0
        } else {
            (difference[lag] * lag as f32 / running_sum).clamp(0.0, 4.0)
        };
    }

    cmndf
}

fn collect_candidates(
    cmndf: &[f32],
    min_lag: usize,
    max_lag: usize,
    sample_rate: f32,
    min_hz: f32,
    max_hz: f32,
) -> Vec<Candidate> {
    if max_lag <= min_lag + 1 {
        return Vec::new();
    }

    let global_best = (min_lag..=max_lag)
        .min_by(|left, right| cmndf[*left].total_cmp(&cmndf[*right]))
        .unwrap_or(min_lag);
    let dynamic_threshold = (cmndf[global_best] * 1.45).clamp(0.08, 0.45);
    let mut candidates = Vec::with_capacity(MAX_INTERNAL_CANDIDATES);

    for lag in (min_lag + 1)..max_lag {
        let current = cmndf[lag];
        let is_local_minimum = current <= cmndf[lag - 1] && current < cmndf[lag + 1];
        if !is_local_minimum || current > dynamic_threshold {
            continue;
        }

        let refined_lag = refine_trough(lag, cmndf);
        let hz = sample_rate / refined_lag.max(1.0);
        if hz < min_hz || hz > max_hz {
            continue;
        }

        candidates.push(Candidate {
            lag: refined_lag,
            hz,
            clarity: (1.0 - current).clamp(0.0, 1.0),
            score: 0.0,
        });
    }

    if candidates.is_empty() {
        let refined_lag = refine_trough(global_best, cmndf);
        let hz = sample_rate / refined_lag.max(1.0);
        if (min_hz..=max_hz).contains(&hz) {
            candidates.push(Candidate {
                lag: refined_lag,
                hz,
                clarity: (1.0 - cmndf[global_best]).clamp(0.0, 1.0),
                score: 0.0,
            });
        }
    }

    candidates.sort_by(|left, right| {
        right
            .clarity
            .total_cmp(&left.clarity)
            .then_with(|| right.lag.total_cmp(&left.lag))
    });
    candidates.truncate(MAX_INTERNAL_CANDIDATES);
    candidates
}

fn score_candidates(
    candidates: &mut [Candidate],
    min_lag: f32,
    max_lag: f32,
    zero_crossing_rate: f32,
    sample_rate: f32,
) {
    let lag_span = (max_lag - min_lag).max(1.0);
    for candidate in candidates.iter_mut() {
        let zero_crossing =
            zero_crossing_agreement_for_rate(zero_crossing_rate, candidate.hz, sample_rate);
        let earliest_bonus = 1.0 - ((candidate.lag - min_lag) / lag_span).clamp(0.0, 1.0);
        candidate.score = (0.72 * candidate.clarity + 0.22 * zero_crossing + 0.06 * earliest_bonus)
            .clamp(0.0, 1.0);
    }
}

fn ambiguity_confidence(best_score: f32, second_score: f32) -> f32 {
    if best_score <= 1e-6 {
        return 0.0;
    }
    if second_score <= 1e-6 {
        return 1.0;
    }
    ((best_score - second_score) / best_score).clamp(0.0, 1.0)
}

fn are_harmonic_family(hz_a: f32, hz_b: f32) -> bool {
    let lower = hz_a.min(hz_b);
    let higher = hz_a.max(hz_b);
    if lower <= 0.0 {
        return false;
    }
    let ratio = higher / lower;
    (ratio - 2.0).abs() <= 0.14 || (ratio - 3.0).abs() <= 0.20
}

fn decimate_by_two(samples: &[f32]) -> Vec<f32> {
    let mut downsampled = Vec::with_capacity(samples.len() / 2);
    let mut index = 0usize;
    while index + 1 < samples.len() {
        downsampled.push((samples[index] + samples[index + 1]) * 0.5);
        index += 2;
    }
    downsampled
}

fn refine_trough(lag: usize, cmndf: &[f32]) -> f32 {
    if lag == 0 || lag + 1 >= cmndf.len() {
        return lag as f32;
    }
    let left = cmndf[lag - 1];
    let center = cmndf[lag];
    let right = cmndf[lag + 1];
    let denominator = left - 2.0 * center + right;
    if denominator.abs() < 1e-6 {
        return lag as f32;
    }
    let delta = (0.5 * (left - right) / denominator).clamp(-0.5, 0.5);
    (lag as f32 + delta).max(1.0)
}

fn zero_crossing_rate(samples: &[f32]) -> f32 {
    if samples.len() < 2 {
        return 0.0;
    }
    let mut crossings = 0usize;
    for index in 1..samples.len() {
        let previous = samples[index - 1];
        let current = samples[index];
        if (previous >= 0.0 && current < 0.0) || (previous < 0.0 && current >= 0.0) {
            crossings += 1;
        }
    }
    crossings as f32 / (samples.len() - 1) as f32
}

fn zero_crossing_agreement(zero_crossing_rate: f32, hz: f32, sample_rate: u32) -> f32 {
    zero_crossing_agreement_for_rate(zero_crossing_rate, hz, sample_rate as f32)
}

fn zero_crossing_agreement_for_rate(zero_crossing_rate: f32, hz: f32, sample_rate: f32) -> f32 {
    if hz <= 0.0 || sample_rate <= 0.0 {
        return 0.0;
    }
    let expected = (2.0 * hz / sample_rate).clamp(1e-6, 1.0);
    let ratio = zero_crossing_rate / expected;
    if !ratio.is_finite() || ratio <= 0.0 {
        return 0.0;
    }
    let distance = ratio.log2().abs();
    (1.0 - distance / 1.1).clamp(0.0, 1.0)
}

#[cfg(test)]
mod tests {
    use super::{detect_pitch, DetectorConfig};
    use crate::input::validate_frame;
    use std::f32::consts::PI;

    #[test]
    fn detects_a4_with_small_error() {
        let sample_rate = 48_000_u32;
        let pcm = sine_wave(440.0, sample_rate, 2048);
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(frame, DetectorConfig::default()).expect("detection");
        assert!((detection.hz - 440.0).abs() < 3.0);
        assert!(detection.periodicity_hint > 0.35);
        assert!(detection.clarity > 0.7);
    }

    #[test]
    fn detects_e2_with_small_error() {
        let sample_rate = 48_000_u32;
        let pcm = sine_wave(82.41, sample_rate, 4096);
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(frame, DetectorConfig::default()).expect("detection");
        assert!(
            (detection.hz - 82.41).abs() < 2.0,
            "detected hz: {}",
            detection.hz
        );
    }

    #[test]
    fn detects_harmonic_rich_e2_without_folding_to_upper_harmonic() {
        let sample_rate = 48_000_u32;
        let pcm = harmonic_wave(
            82.41,
            sample_rate,
            4096,
            &[(1.0, 0.16), (2.0, 0.82), (3.0, 0.32), (4.0, 0.16)],
        );
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(
            frame,
            DetectorConfig {
                min_hz: 70.0,
                max_hz: 420.0,
                ..DetectorConfig::default()
            },
        )
        .expect("detection");
        assert!(
            (detection.hz - 82.41).abs() < 3.0,
            "expected E2, got {} Hz",
            detection.hz
        );
        assert!(detection.candidate_count >= 1);
    }

    #[test]
    fn returns_zero_when_below_noise_gate() {
        let sample_rate = 48_000_u32;
        let pcm = sine_wave_with_amplitude(440.0, sample_rate, 2048, 0.000_01);
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(
            frame,
            DetectorConfig {
                noise_gate_db: -40.0,
                ..DetectorConfig::default()
            },
        )
        .expect("detection");
        assert_eq!(detection.hz, 0.0);
    }

    #[test]
    fn detects_fundamental_in_harmonic_rich_g3_signal() {
        let sample_rate = 48_000_u32;
        let pcm = harmonic_wave(
            196.0,
            sample_rate,
            4096,
            &[(1.0, 0.18), (2.0, 0.63), (3.0, 0.30), (4.0, 0.18)],
        );
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(
            frame,
            DetectorConfig {
                min_hz: 70.0,
                max_hz: 420.0,
                ..DetectorConfig::default()
            },
        )
        .expect("detection");
        assert!(
            (detection.hz - 196.0).abs() < 4.0,
            "detected hz: {}",
            detection.hz
        );
    }

    #[test]
    fn rejects_out_of_range_tone_instead_of_folding_to_subharmonic() {
        let sample_rate = 48_000_u32;
        let pcm = sine_wave(440.0, sample_rate, 4096);
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(
            frame,
            DetectorConfig {
                min_hz: 70.0,
                max_hz: 420.0,
                ..DetectorConfig::default()
            },
        )
        .expect("detection");
        assert_eq!(detection.hz, 0.0);
    }

    #[test]
    fn keeps_periodicity_low_for_broadband_noise() {
        let sample_rate = 48_000_u32;
        let pcm = broadband_noise(4096);
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(
            frame,
            DetectorConfig {
                min_hz: 70.0,
                max_hz: 420.0,
                ..DetectorConfig::default()
            },
        )
        .expect("detection");
        assert!(detection.periodicity_hint < 0.35);
    }

    #[test]
    fn resolves_low_a2_from_harmonic_rich_signal() {
        let sample_rate = 48_000_u32;
        let pcm = harmonic_wave(
            110.0,
            sample_rate,
            4096,
            &[(1.0, 0.20), (2.0, 0.68), (3.0, 0.24), (4.0, 0.10)],
        );
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(
            frame,
            DetectorConfig {
                min_hz: 70.0,
                max_hz: 420.0,
                ..DetectorConfig::default()
            },
        )
        .expect("detection");
        assert!(
            (detection.hz - 110.0).abs() < 3.0,
            "detected hz: {}",
            detection.hz
        );
    }

    fn sine_wave(frequency_hz: f32, sample_rate: u32, len: usize) -> Vec<f32> {
        sine_wave_with_amplitude(frequency_hz, sample_rate, len, 0.5)
    }

    fn sine_wave_with_amplitude(
        frequency_hz: f32,
        sample_rate: u32,
        len: usize,
        amplitude: f32,
    ) -> Vec<f32> {
        (0..len)
            .map(|index| {
                let phase = 2.0 * PI * frequency_hz * index as f32 / sample_rate as f32;
                phase.sin() * amplitude
            })
            .collect()
    }

    fn harmonic_wave(
        fundamental_hz: f32,
        sample_rate: u32,
        len: usize,
        harmonics: &[(f32, f32)],
    ) -> Vec<f32> {
        (0..len)
            .map(|index| {
                harmonics
                    .iter()
                    .map(|(multiple, amplitude)| {
                        let phase = 2.0 * PI * (fundamental_hz * *multiple) * index as f32
                            / sample_rate as f32;
                        phase.sin() * *amplitude
                    })
                    .sum::<f32>()
            })
            .collect()
    }

    fn broadband_noise(len: usize) -> Vec<f32> {
        (0..len)
            .map(|index| {
                let phase = (index * 17 % 31) as f32;
                ((phase / 15.0) - 1.0) * 0.3
            })
            .collect()
    }
}
