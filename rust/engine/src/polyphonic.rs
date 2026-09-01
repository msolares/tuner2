use std::f32::consts::PI;

const PITCH_CLASS_COUNT: usize = 12;
const MIN_MIDI: i32 = 40;
const MAX_MIDI: i32 = 88;
const MAX_CHROMA_FRAMES: usize = 64;
const MAX_ANALYSIS_SAMPLES: usize = 8192;
const MIN_ANALYSIS_SAMPLES: usize = 256;

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ChordEvidence {
    pub pitch_class_strengths: [f32; PITCH_CLASS_COUNT],
    pub confidence: f32,
    pub onset_confidence: f32,
    pub onset_sequence: u64,
}

impl Default for ChordEvidence {
    fn default() -> Self {
        Self {
            pitch_class_strengths: [0.0; PITCH_CLASS_COUNT],
            confidence: 0.0,
            onset_confidence: 0.0,
            onset_sequence: 0,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PolyphonicError {
    EmptyFrame,
    FrameTooShort,
    InvalidSampleRate,
    NonFiniteSample,
}

#[derive(Debug, Clone, Copy)]
pub struct PolyphonicConfig {
    pub window_ms: u32,
    pub noise_gate_db: f32,
    pub onset_threshold: f32,
    pub onset_refractory_ms: u32,
}

impl Default for PolyphonicConfig {
    fn default() -> Self {
        Self {
            window_ms: 700,
            noise_gate_db: -60.0,
            onset_threshold: 0.45,
            onset_refractory_ms: 50,
        }
    }
}

#[derive(Debug, Clone, Copy)]
struct ChromaFrame {
    valid: bool,
    end_sample: u64,
    strengths: [f32; PITCH_CLASS_COUNT],
    confidence: f32,
}

impl ChromaFrame {
    const EMPTY: Self = Self {
        valid: false,
        end_sample: 0,
        strengths: [0.0; PITCH_CLASS_COUNT],
        confidence: 0.0,
    };
}

pub struct PolyphonicChordAnalyzer {
    config: PolyphonicConfig,
    frames: [ChromaFrame; MAX_CHROMA_FRAMES],
    next_frame: usize,
    total_samples: u64,
    previous_rms: f32,
    samples_since_onset: u64,
    onset_sequence: u64,
}

impl PolyphonicChordAnalyzer {
    pub fn new(config: PolyphonicConfig) -> Self {
        Self {
            config: sanitize_config(config),
            frames: [ChromaFrame::EMPTY; MAX_CHROMA_FRAMES],
            next_frame: 0,
            total_samples: 0,
            previous_rms: 0.0,
            samples_since_onset: u64::MAX,
            onset_sequence: 0,
        }
    }

    pub fn reset(&mut self) {
        self.frames = [ChromaFrame::EMPTY; MAX_CHROMA_FRAMES];
        self.next_frame = 0;
        self.total_samples = 0;
        self.previous_rms = 0.0;
        self.samples_since_onset = u64::MAX;
        self.onset_sequence = 0;
    }

    pub fn process(
        &mut self,
        pcm: &[f32],
        sample_rate: u32,
    ) -> Result<ChordEvidence, PolyphonicError> {
        validate_input(pcm, sample_rate)?;
        self.total_samples = self.total_samples.saturating_add(pcm.len() as u64);
        self.samples_since_onset = self.samples_since_onset.saturating_add(pcm.len() as u64);

        let analysis = &pcm[pcm.len().saturating_sub(MAX_ANALYSIS_SAMPLES)..];
        let rms = root_mean_square(analysis);
        let rms_db = 20.0 * rms.max(1.0e-12).log10();
        let onset_confidence = onset_confidence(self.previous_rms, rms);
        self.previous_rms = rms;

        let refractory_samples = sample_rate as u64 * self.config.onset_refractory_ms as u64 / 1000;
        if onset_confidence >= self.config.onset_threshold
            && self.samples_since_onset >= refractory_samples
        {
            self.onset_sequence = self.onset_sequence.saturating_add(1);
            self.samples_since_onset = 0;
        }

        let (strengths, confidence) = if rms_db >= self.config.noise_gate_db {
            spectral_chroma(analysis, sample_rate, rms)
        } else {
            ([0.0; PITCH_CLASS_COUNT], 0.0)
        };
        self.frames[self.next_frame] = ChromaFrame {
            valid: true,
            end_sample: self.total_samples,
            strengths,
            confidence,
        };
        self.next_frame = (self.next_frame + 1) % MAX_CHROMA_FRAMES;

        Ok(self.accumulated_evidence(sample_rate, onset_confidence))
    }

    fn accumulated_evidence(&self, sample_rate: u32, onset_confidence: f32) -> ChordEvidence {
        let window_samples = sample_rate as u64 * self.config.window_ms.clamp(1, 700) as u64 / 1000;
        let mut strengths = [0.0_f32; PITCH_CLASS_COUNT];
        let mut confidence = 0.0_f32;
        for frame in self.frames {
            if !frame.valid || self.total_samples.saturating_sub(frame.end_sample) > window_samples
            {
                continue;
            }
            for (combined, value) in strengths.iter_mut().zip(frame.strengths) {
                *combined = combined.max(value);
            }
            confidence = confidence.max(frame.confidence);
        }
        ChordEvidence {
            pitch_class_strengths: strengths.map(finite_unit),
            confidence: finite_unit(confidence),
            onset_confidence: finite_unit(onset_confidence),
            onset_sequence: self.onset_sequence,
        }
    }
}

impl Default for PolyphonicChordAnalyzer {
    fn default() -> Self {
        Self::new(PolyphonicConfig::default())
    }
}

fn sanitize_config(config: PolyphonicConfig) -> PolyphonicConfig {
    PolyphonicConfig {
        window_ms: config.window_ms.clamp(1, 700),
        noise_gate_db: if config.noise_gate_db.is_finite() {
            config.noise_gate_db.clamp(-100.0, 0.0)
        } else {
            PolyphonicConfig::default().noise_gate_db
        },
        onset_threshold: finite_unit(config.onset_threshold),
        onset_refractory_ms: config.onset_refractory_ms.clamp(1, 500),
    }
}

fn validate_input(pcm: &[f32], sample_rate: u32) -> Result<(), PolyphonicError> {
    if pcm.is_empty() {
        return Err(PolyphonicError::EmptyFrame);
    }
    if pcm.len() < MIN_ANALYSIS_SAMPLES {
        return Err(PolyphonicError::FrameTooShort);
    }
    if !(8_000..=192_000).contains(&sample_rate) {
        return Err(PolyphonicError::InvalidSampleRate);
    }
    if pcm.iter().any(|sample| !sample.is_finite()) {
        return Err(PolyphonicError::NonFiniteSample);
    }
    Ok(())
}

fn spectral_chroma(pcm: &[f32], sample_rate: u32, rms: f32) -> ([f32; PITCH_CLASS_COUNT], f32) {
    let mean = pcm.iter().sum::<f32>() / pcm.len() as f32;
    let mut note_energy = [0.0_f32; (MAX_MIDI - MIN_MIDI + 1) as usize];
    for midi in MIN_MIDI..=MAX_MIDI {
        let frequency = midi_frequency(midi);
        if frequency >= sample_rate as f32 * 0.48 {
            continue;
        }
        note_energy[(midi - MIN_MIDI) as usize] =
            goertzel_amplitude(pcm, sample_rate as f32, frequency, mean);
    }

    let raw = note_energy;
    for index in 0..note_energy.len() {
        let octave_parent = index
            .checked_sub(12)
            .map_or(0.0, |parent| raw[parent] * 0.42);
        let third_harmonic_parent = index
            .checked_sub(19)
            .map_or(0.0, |parent| raw[parent] * 0.22);
        note_energy[index] = (raw[index] - octave_parent - third_harmonic_parent).max(0.0);
    }

    let mut chroma = [0.0_f32; PITCH_CLASS_COUNT];
    for (index, energy) in note_energy.into_iter().enumerate() {
        let pitch_class = (MIN_MIDI as usize + index) % PITCH_CLASS_COUNT;
        chroma[pitch_class] = chroma[pitch_class].max(energy);
    }
    let mut sorted = chroma;
    sorted.sort_by(f32::total_cmp);
    let noise_floor = sorted[3] * 0.8;
    for value in &mut chroma {
        *value = (*value - noise_floor).max(0.0);
    }
    let peak = chroma.iter().copied().fold(0.0_f32, f32::max);
    if peak <= 1.0e-8 {
        return ([0.0; PITCH_CLASS_COUNT], 0.0);
    }
    for value in &mut chroma {
        *value = finite_unit(*value / peak);
    }
    let active_bins = chroma.iter().filter(|value| **value >= 0.35).count() as f32;
    let spectral_quality = (1.0 - ((active_bins - 3.0).abs() / 9.0)).clamp(0.35, 1.0);
    let level_confidence = (rms * 12.0).clamp(0.0, 1.0);
    (chroma, finite_unit(level_confidence * spectral_quality))
}

fn goertzel_amplitude(pcm: &[f32], sample_rate: f32, frequency: f32, mean: f32) -> f32 {
    let omega = 2.0 * PI * frequency / sample_rate;
    let coefficient = 2.0 * omega.cos();
    let denominator = (pcm.len().saturating_sub(1)).max(1) as f32;
    let mut previous = 0.0_f32;
    let mut previous_two = 0.0_f32;
    for (index, sample) in pcm.iter().enumerate() {
        let hann = 0.5 - 0.5 * (2.0 * PI * index as f32 / denominator).cos();
        let current = (*sample - mean) * hann + coefficient * previous - previous_two;
        previous_two = previous;
        previous = current;
    }
    let power =
        previous_two * previous_two + previous * previous - coefficient * previous * previous_two;
    finite_non_negative(power).sqrt() * 2.0 / pcm.len() as f32
}

fn root_mean_square(pcm: &[f32]) -> f32 {
    let mean_square = pcm.iter().map(|sample| sample * sample).sum::<f32>() / pcm.len() as f32;
    finite_non_negative(mean_square).sqrt()
}

fn onset_confidence(previous_rms: f32, rms: f32) -> f32 {
    let increase = (rms - previous_rms).max(0.0);
    finite_unit(increase / (rms + 0.01) * 1.5)
}

fn midi_frequency(midi: i32) -> f32 {
    440.0 * 2.0_f32.powf((midi as f32 - 69.0) / 12.0)
}

fn finite_non_negative(value: f32) -> f32 {
    if value.is_finite() {
        value.max(0.0)
    } else {
        0.0
    }
}

fn finite_unit(value: f32) -> f32 {
    if value.is_finite() {
        value.clamp(0.0, 1.0)
    } else {
        0.0
    }
}

#[cfg(test)]
mod tests {
    use super::{ChordEvidence, PolyphonicChordAnalyzer, PolyphonicError, MAX_CHROMA_FRAMES};
    use std::f32::consts::PI;
    use std::mem::size_of;
    use std::time::Instant;

    const SAMPLE_RATE: u32 = 48_000;

    #[test]
    fn extracts_major_minor_and_power_chord_pitch_classes() {
        let cases: &[(&[u8], &[i32])] = &[
            (&[0, 4, 7], &[48, 52, 55, 60, 64]),
            (&[9, 0, 4], &[45, 52, 57, 60, 64]),
            (&[7, 11, 2], &[43, 47, 50, 55, 59, 67]),
            (&[4, 8, 11], &[40, 47, 52, 56, 59, 64]),
            (&[2, 6, 9], &[50, 57, 62, 66]),
            (&[9, 0, 4], &[45, 52, 57, 60, 64]),
            (&[4, 7, 11], &[40, 47, 52, 55, 59, 64]),
            (&[2, 5, 9], &[50, 57, 62, 65]),
            (&[4, 11], &[40, 47, 52]),
        ];
        for (target, notes) in cases {
            for timbre in 0..2 {
                for amplitude in [0.12, 0.24, 0.42] {
                    let pcm = guitar_chord(notes, 8192, amplitude, timbre);
                    let mut analyzer = PolyphonicChordAnalyzer::default();
                    let evidence = analyzer.process(&pcm, SAMPLE_RATE).expect("evidence");
                    assert_required(target, evidence, 0.28);
                }
            }
        }
    }

    #[test]
    fn accumulates_a_strum_inside_the_bounded_window() {
        let mut analyzer = PolyphonicChordAnalyzer::default();
        for midi in [48, 52, 55] {
            let pcm = guitar_chord(&[midi], 2048, 0.35, 0);
            analyzer.process(&pcm, SAMPLE_RATE).expect("evidence");
        }
        let evidence = analyzer
            .process(&vec![0.0; 2048], SAMPLE_RATE)
            .expect("evidence");
        assert_required(&[0, 4, 7], evidence, 0.28);
    }

    #[test]
    fn reports_new_attacks_without_incrementing_on_sustain() {
        let mut analyzer = PolyphonicChordAnalyzer::default();
        let chord = guitar_chord(&[48, 52, 55], 4096, 0.35, 0);
        let first = analyzer.process(&chord, SAMPLE_RATE).expect("first");
        let sustained = analyzer.process(&chord, SAMPLE_RATE).expect("sustain");
        analyzer
            .process(&vec![0.0; 4096], SAMPLE_RATE)
            .expect("silence");
        let repeated = analyzer.process(&chord, SAMPLE_RATE).expect("repeat");

        assert_eq!(first.onset_sequence, 1);
        assert_eq!(sustained.onset_sequence, 1);
        assert_eq!(repeated.onset_sequence, 2);
        assert!(first.onset_confidence >= 0.45);
    }

    #[test]
    fn suppresses_harmonics_from_an_isolated_note() {
        let mut analyzer = PolyphonicChordAnalyzer::default();
        let note = guitar_chord(&[40], 8192, 0.4, 1);
        let evidence = analyzer.process(&note, SAMPLE_RATE).expect("evidence");
        assert!(evidence.pitch_class_strengths[4] >= 0.8);
        assert!(evidence.pitch_class_strengths[11] < 0.45);
    }

    #[test]
    fn handles_silence_noise_and_invalid_input_without_nan_or_panic() {
        let mut analyzer = PolyphonicChordAnalyzer::default();
        let silence = analyzer
            .process(&vec![0.0; 2048], SAMPLE_RATE)
            .expect("silence");
        assert!(silence
            .pitch_class_strengths
            .iter()
            .all(|value| *value == 0.0));
        assert!(silence.confidence.is_finite());

        let noise = deterministic_noise(4096, 0.03);
        let noisy = analyzer.process(&noise, SAMPLE_RATE).expect("noise");
        assert!(noisy
            .pitch_class_strengths
            .iter()
            .all(|value| value.is_finite() && (0.0..=1.0).contains(value)));
        assert_eq!(
            analyzer.process(&[], SAMPLE_RATE),
            Err(PolyphonicError::EmptyFrame)
        );
        assert_eq!(
            analyzer.process(&[0.0; 32], SAMPLE_RATE),
            Err(PolyphonicError::FrameTooShort)
        );
        assert_eq!(
            analyzer.process(&[0.0; 256], 0),
            Err(PolyphonicError::InvalidSampleRate)
        );
        let mut invalid = [0.0; 256];
        invalid[20] = f32::NAN;
        assert_eq!(
            analyzer.process(&invalid, SAMPLE_RATE),
            Err(PolyphonicError::NonFiniteSample)
        );
    }

    #[test]
    fn uses_fixed_memory_and_finishes_well_inside_the_observation_budget() {
        assert!(size_of::<PolyphonicChordAnalyzer>() < 16 * 1024);
        assert_eq!(MAX_CHROMA_FRAMES, 64);
        let chord = guitar_chord(&[48, 52, 55, 60, 64], 8192, 0.3, 0);
        let started = Instant::now();
        for _ in 0..20 {
            let mut analyzer = PolyphonicChordAnalyzer::default();
            let evidence = analyzer.process(&chord, SAMPLE_RATE).expect("evidence");
            assert!(evidence.confidence.is_finite());
        }
        assert!(
            started.elapsed().as_millis() < 750,
            "20 analyses took {:?}",
            started.elapsed()
        );
    }

    fn assert_required(target: &[u8], evidence: ChordEvidence, threshold: f32) {
        for pitch_class in target {
            assert!(
                evidence.pitch_class_strengths[*pitch_class as usize] >= threshold,
                "class {pitch_class} missing in {:?}",
                evidence.pitch_class_strengths
            );
        }
        assert!(evidence.confidence > 0.0);
    }

    fn guitar_chord(notes: &[i32], len: usize, amplitude: f32, timbre: usize) -> Vec<f32> {
        let harmonics: &[(f32, f32)] = if timbre == 0 {
            &[(1.0, 1.0), (2.0, 0.36), (3.0, 0.18), (4.0, 0.09)]
        } else {
            &[(1.0, 0.72), (2.0, 0.55), (3.0, 0.24), (5.0, 0.08)]
        };
        let scale = amplitude / notes.len().max(1) as f32;
        (0..len)
            .map(|index| {
                let attack = (index as f32 / 240.0).min(1.0);
                let decay = (-2.2 * index as f32 / len as f32).exp();
                notes
                    .iter()
                    .flat_map(|midi| {
                        harmonics.iter().map(move |(multiple, weight)| {
                            let hz = 440.0 * 2.0_f32.powf((*midi as f32 - 69.0) / 12.0);
                            let phase =
                                2.0 * PI * hz * *multiple * index as f32 / SAMPLE_RATE as f32;
                            phase.sin() * *weight
                        })
                    })
                    .sum::<f32>()
                    * scale
                    * attack
                    * decay
            })
            .collect()
    }

    fn deterministic_noise(len: usize, amplitude: f32) -> Vec<f32> {
        let mut state = 0x1234_5678_u32;
        (0..len)
            .map(|_| {
                state = state.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
                ((state >> 8) as f32 / 16_777_215.0 * 2.0 - 1.0) * amplitude
            })
            .collect()
    }
}
