use crate::input::ValidatedFrame;

#[derive(Debug, Clone, Copy)]
pub struct Detection {
    pub hz: f32,
    pub signal_rms: f32,
    pub periodicity_hint: f32,
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

pub fn detect_pitch(frame: ValidatedFrame<'_>, config: DetectorConfig) -> Result<Detection, &'static str> {
    if frame.pcm.len() < 32 {
        return Err("frame_too_short");
    }

    let (min_hz, max_hz) = normalize_range(config.min_hz, config.max_hz);
    let sample_rate = frame.sample_rate as f32;
    let min_lag = (sample_rate / max_hz).floor().max(1.0) as usize;
    let max_lag = (sample_rate / min_hz)
        .ceil()
        .clamp((min_lag + 1) as f32, (frame.pcm.len() - 2) as f32) as usize;
    if max_lag <= min_lag {
        return Err("invalid_frame");
    }

    let len = frame.pcm.len() as f32;
    let rms = (frame.pcm.iter().map(|s| s * s).sum::<f32>() / len).sqrt();
    if rms <= 1e-8 {
        return Ok(zero_detection(rms, 0.0));
    }
    let rms_db = 20.0 * rms.max(1e-12).log10();
    if rms_db < config.noise_gate_db {
        return Ok(zero_detection(rms, 0.0));
    }

    let mean = frame.pcm.iter().sum::<f32>() / len;
    let centered: Vec<f32> = frame.pcm.iter().map(|s| s - mean).collect();
    let mut correlations = vec![0.0_f32; max_lag - min_lag + 1];
    for lag in min_lag..=max_lag {
        let mut corr = 0.0_f32;
        let mut left_energy = 0.0_f32;
        let mut right_energy = 0.0_f32;
        for i in 0..(centered.len() - lag) {
            let left = centered[i];
            let right = centered[i + lag];
            corr += left * right;
            left_energy += left * left;
            right_energy += right * right;
        }
        let normalizer = (left_energy * right_energy).sqrt();
        if normalizer > 1e-12 {
            corr /= normalizer;
        } else {
            corr = 0.0;
        }
        correlations[lag - min_lag] = corr;
    }

    let (best_index, best_corr) = select_peak(&correlations);
    if best_corr < 0.10 {
        return Ok(zero_detection(rms, best_corr.max(0.0)));
    }

    let corrected_index = apply_harmonic_correction(best_index, best_corr, &correlations);
    let lag = (min_lag + corrected_index) as f32;
    let refined_lag = refine_lag(lag, corrected_index, &correlations);
    let hz = sample_rate / refined_lag;
    if hz < min_hz || hz > max_hz {
        return Ok(zero_detection(rms, best_corr));
    }

    let periodicity_hint = best_corr.clamp(0.0, 1.0);

    Ok(Detection {
        hz,
        signal_rms: rms,
        periodicity_hint,
    })
}

fn zero_detection(signal_rms: f32, periodicity_hint: f32) -> Detection {
    Detection {
        hz: 0.0,
        signal_rms,
        periodicity_hint,
    }
}

fn normalize_range(min_hz: f32, max_hz: f32) -> (f32, f32) {
    let safe_min = min_hz.max(20.0);
    let safe_max = max_hz.max(safe_min + 1.0);
    (safe_min, safe_max)
}

fn select_peak(correlations: &[f32]) -> (usize, f32) {
    if correlations.is_empty() {
        return (0, 0.0);
    }
    if correlations.len() < 3 {
        let (index, value) = correlations
            .iter()
            .copied()
            .enumerate()
            .max_by(|a, b| a.1.total_cmp(&b.1))
            .unwrap_or((0, 0.0));
        return (index, value);
    }

    let mut best_index = 0usize;
    let mut best_value = -1.0_f32;
    let mut found_local_peak = false;
    for i in 1..(correlations.len() - 1) {
        let current = correlations[i];
        let is_local_peak = current > correlations[i - 1] && current >= correlations[i + 1];
        if is_local_peak && current > best_value {
            best_value = current;
            best_index = i;
            found_local_peak = true;
        }
    }

    if found_local_peak {
        (best_index, best_value)
    } else {
        correlations
            .iter()
            .copied()
            .enumerate()
            .max_by(|a, b| a.1.total_cmp(&b.1))
            .unwrap_or((0, 0.0))
    }
}

fn apply_harmonic_correction(best_index: usize, best_corr: f32, correlations: &[f32]) -> usize {
    let mut corrected_index = best_index;
    let base_lag = best_index + 1;
    for factor in 2..=8 {
        let candidate_lag = base_lag * factor;
        if candidate_lag == 0 || candidate_lag > correlations.len() {
            break;
        }
        let candidate_index = candidate_lag - 1;
        let candidate_corr = correlations[candidate_index];
        if candidate_corr >= best_corr * 0.82 {
            corrected_index = candidate_index;
        }
    }
    corrected_index
}

fn refine_lag(base_lag: f32, corrected_index: usize, correlations: &[f32]) -> f32 {
    if corrected_index == 0 || corrected_index + 1 >= correlations.len() {
        return base_lag;
    }
    let y1 = correlations[corrected_index - 1];
    let y2 = correlations[corrected_index];
    let y3 = correlations[corrected_index + 1];
    let denom = y1 - 2.0 * y2 + y3;
    if denom.abs() < 1e-6 {
        return base_lag;
    }
    let delta = (0.5 * (y1 - y3) / denom).clamp(-0.5, 0.5);
    (base_lag + delta).max(1.0)
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
        assert!(detection.periodicity_hint > 0.3);
    }

    #[test]
    fn detects_e2_with_small_error() {
        let sample_rate = 48_000_u32;
        let pcm = sine_wave(82.41, sample_rate, 4096);
        let frame = validate_frame(&pcm, sample_rate).expect("valid frame");
        let detection = detect_pitch(frame, DetectorConfig::default()).expect("detection");
        assert!((detection.hz - 82.41).abs() < 2.0);
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

    fn sine_wave(frequency_hz: f32, sample_rate: u32, len: usize) -> Vec<f32> {
        sine_wave_with_amplitude(frequency_hz, sample_rate, len, 0.5)
    }

    fn sine_wave_with_amplitude(frequency_hz: f32, sample_rate: u32, len: usize, amplitude: f32) -> Vec<f32> {
        (0..len)
            .map(|i| {
                let phase = 2.0 * PI * frequency_hz * i as f32 / sample_rate as f32;
                phase.sin() * amplitude
            })
            .collect()
    }
}
