use crate::detector::{detect_pitch, DetectorConfig};
use crate::input::validate_frame;
use crate::polyphonic::{PolyphonicChordAnalyzer, PolyphonicConfig, PolyphonicError};
use crate::smoothing::Smoother;
use std::collections::HashMap;
use std::panic::catch_unwind;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Mutex, OnceLock};

pub const PERFORMANCE_ABI_VERSION: u32 = 1;
pub const PERFORMANCE_MIN_FRAME_SAMPLES: usize = 256;
pub const PERFORMANCE_MAX_FRAME_SAMPLES: usize = 8192;

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PerformanceErrorCode {
    Ok = 0,
    NullPointer = 1,
    InvalidHandle = 2,
    InvalidFrame = 3,
    InvalidSampleRate = 4,
    UnsupportedAbiVersion = 5,
    InvalidStructSize = 6,
    InvalidSettings = 7,
    InvalidTarget = 8,
    NonMonotonicTimestamp = 9,
    InternalError = 10,
}

#[repr(u32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PerformanceObservationKind {
    None = 0,
    Note = 1,
    Chord = 2,
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct PerformanceConfigV1 {
    pub abi_version: u32,
    pub struct_size: u32,
    pub a4_hz: f32,
    pub noise_gate_db: f32,
    pub reserved: [u32; 4],
}

impl Default for PerformanceConfigV1 {
    fn default() -> Self {
        Self {
            abi_version: PERFORMANCE_ABI_VERSION,
            struct_size: size_of_u32::<Self>(),
            a4_hz: 440.0,
            noise_gate_db: -60.0,
            reserved: [0; 4],
        }
    }
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct PerformanceTargetV1 {
    pub abi_version: u32,
    pub struct_size: u32,
    pub target_kind: u32,
    pub midi: i32,
    pub pitch_class_count: u32,
    pub pitch_classes: [u8; 3],
    pub reserved_u8: u8,
    pub reserved: [u32; 4],
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct PerformanceResultV1 {
    pub abi_version: u32,
    pub struct_size: u32,
    pub error_code: i32,
    pub observation_kind: u32,
    pub timestamp_ms: u64,
    pub onset_sequence: u64,
    pub confidence: f32,
    pub hz: f32,
    pub cents: f32,
    pub midi: i32,
    pub pitch_class_strengths: [f32; 12],
    pub onset_confidence: f32,
    pub reserved: [u32; 3],
}

impl PerformanceResultV1 {
    fn empty(timestamp_ms: u64, onset_sequence: u64) -> Self {
        Self {
            abi_version: PERFORMANCE_ABI_VERSION,
            struct_size: size_of_u32::<Self>(),
            error_code: PerformanceErrorCode::Ok as i32,
            observation_kind: PerformanceObservationKind::None as u32,
            timestamp_ms,
            onset_sequence,
            confidence: 0.0,
            hz: 0.0,
            cents: 0.0,
            midi: -1,
            pitch_class_strengths: [0.0; 12],
            onset_confidence: 0.0,
            reserved: [0; 3],
        }
    }

    fn error(code: PerformanceErrorCode) -> Self {
        let mut result = Self::empty(0, 0);
        result.error_code = code as i32;
        result
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Target {
    Note(u8),
    Chord { pitch_classes: [u8; 3], count: u8 },
}

struct PerformanceHandle {
    a4_hz: f32,
    noise_gate_db: f32,
    target: Option<Target>,
    smoother: Smoother,
    chord_analyzer: PolyphonicChordAnalyzer,
    previous_rms: f32,
    samples_since_onset: u64,
    onset_sequence: u64,
    last_timestamp_ms: Option<u64>,
}

impl PerformanceHandle {
    fn new(config: PerformanceConfigV1) -> Self {
        Self {
            a4_hz: config.a4_hz,
            noise_gate_db: config.noise_gate_db,
            target: None,
            smoother: Smoother::default(),
            chord_analyzer: PolyphonicChordAnalyzer::new(PolyphonicConfig {
                noise_gate_db: config.noise_gate_db,
                ..PolyphonicConfig::default()
            }),
            previous_rms: 0.0,
            samples_since_onset: u64::MAX,
            onset_sequence: 0,
            last_timestamp_ms: None,
        }
    }

    fn update_onset(&mut self, pcm: &[f32], sample_rate: u32) {
        self.samples_since_onset = self.samples_since_onset.saturating_add(pcm.len() as u64);
        let rms = (pcm.iter().map(|sample| sample * sample).sum::<f32>() / pcm.len() as f32).sqrt();
        let confidence = ((rms - self.previous_rms).max(0.0) / (rms + 0.01) * 1.5).clamp(0.0, 1.0);
        self.previous_rms = rms;
        let refractory_samples = sample_rate as u64 * 50 / 1000;
        if confidence >= 0.45 && self.samples_since_onset >= refractory_samples {
            self.onset_sequence = self.onset_sequence.saturating_add(1);
            self.samples_since_onset = 0;
        }
    }

    fn replace_target(&mut self, target: Option<Target>) {
        if self.target == target {
            return;
        }
        self.target = target;
        self.smoother = Smoother::default();
        self.chord_analyzer.reset();
    }
}

static NEXT_PERFORMANCE_HANDLE: AtomicU64 = AtomicU64::new(1);
static PERFORMANCE_HANDLES: OnceLock<Mutex<HashMap<u64, PerformanceHandle>>> = OnceLock::new();

fn handles() -> &'static Mutex<HashMap<u64, PerformanceHandle>> {
    PERFORMANCE_HANDLES.get_or_init(|| Mutex::new(HashMap::new()))
}

#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn performance_init(config_ptr: *const PerformanceConfigV1) -> u64 {
    let result = catch_unwind(|| -> Result<u64, PerformanceErrorCode> {
        if config_ptr.is_null() {
            return Err(PerformanceErrorCode::NullPointer);
        }
        let config = unsafe { config_ptr.read_unaligned() };
        validate_header(
            config.abi_version,
            config.struct_size,
            size_of_u32::<PerformanceConfigV1>(),
        )?;
        if !config.a4_hz.is_finite()
            || !(415.0..=466.0).contains(&config.a4_hz)
            || !config.noise_gate_db.is_finite()
            || !(-100.0..=0.0).contains(&config.noise_gate_db)
        {
            return Err(PerformanceErrorCode::InvalidSettings);
        }
        let handle = NEXT_PERFORMANCE_HANDLE.fetch_add(1, Ordering::Relaxed);
        let mut guard = handles()
            .lock()
            .map_err(|_| PerformanceErrorCode::InternalError)?;
        guard.insert(handle, PerformanceHandle::new(config));
        Ok(handle)
    });
    match result {
        Ok(Ok(handle)) => handle,
        Ok(Err(_)) | Err(_) => 0,
    }
}

#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn performance_set_target(
    handle: u64,
    target_ptr: *const PerformanceTargetV1,
) -> i32 {
    let result = catch_unwind(|| -> Result<(), PerformanceErrorCode> {
        let target = if target_ptr.is_null() {
            None
        } else {
            Some(parse_target(unsafe { target_ptr.read_unaligned() })?)
        };
        let mut guard = handles()
            .lock()
            .map_err(|_| PerformanceErrorCode::InternalError)?;
        let state = guard
            .get_mut(&handle)
            .ok_or(PerformanceErrorCode::InvalidHandle)?;
        state.replace_target(target);
        Ok(())
    });
    status_code(result)
}

#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn performance_process_frame(
    handle: u64,
    pcm_ptr: *const f32,
    len: usize,
    sample_rate: u32,
    timestamp_ms: u64,
) -> PerformanceResultV1 {
    let result = catch_unwind(|| -> Result<PerformanceResultV1, PerformanceErrorCode> {
        if pcm_ptr.is_null() {
            return Err(PerformanceErrorCode::NullPointer);
        }
        if !(8_000..=192_000).contains(&sample_rate) {
            return Err(PerformanceErrorCode::InvalidSampleRate);
        }
        if !(PERFORMANCE_MIN_FRAME_SAMPLES..=PERFORMANCE_MAX_FRAME_SAMPLES).contains(&len) {
            return Err(PerformanceErrorCode::InvalidFrame);
        }
        if !(pcm_ptr as usize).is_multiple_of(std::mem::align_of::<f32>()) {
            return Err(PerformanceErrorCode::InvalidFrame);
        }
        let pcm = unsafe { std::slice::from_raw_parts(pcm_ptr, len) };
        if pcm.iter().any(|sample| !sample.is_finite()) {
            return Err(PerformanceErrorCode::InvalidFrame);
        }

        let mut guard = handles()
            .lock()
            .map_err(|_| PerformanceErrorCode::InternalError)?;
        let state = guard
            .get_mut(&handle)
            .ok_or(PerformanceErrorCode::InvalidHandle)?;
        if state
            .last_timestamp_ms
            .is_some_and(|previous| timestamp_ms < previous)
        {
            return Err(PerformanceErrorCode::NonMonotonicTimestamp);
        }

        let mut observation = match state.target {
            None => PerformanceResultV1::empty(timestamp_ms, state.onset_sequence),
            Some(Target::Note(_target_midi)) => {
                process_note(state, pcm, sample_rate, timestamp_ms)?
            }
            Some(Target::Chord { .. }) => process_chord(state, pcm, sample_rate, timestamp_ms)?,
        };
        state.update_onset(pcm, sample_rate);
        state.last_timestamp_ms = Some(timestamp_ms);
        observation.onset_sequence = state.onset_sequence;
        Ok(observation)
    });
    match result {
        Ok(Ok(observation)) => observation,
        Ok(Err(code)) => PerformanceResultV1::error(code),
        Err(_) => PerformanceResultV1::error(PerformanceErrorCode::InternalError),
    }
}

#[no_mangle]
pub extern "C" fn performance_dispose(handle: u64) -> i32 {
    let result = catch_unwind(|| -> Result<(), PerformanceErrorCode> {
        let mut guard = handles()
            .lock()
            .map_err(|_| PerformanceErrorCode::InternalError)?;
        guard
            .remove(&handle)
            .map(|_| ())
            .ok_or(PerformanceErrorCode::InvalidHandle)
    });
    status_code(result)
}

fn process_note(
    state: &mut PerformanceHandle,
    pcm: &[f32],
    sample_rate: u32,
    timestamp_ms: u64,
) -> Result<PerformanceResultV1, PerformanceErrorCode> {
    let frame = validate_frame(pcm, sample_rate).map_err(map_frame_error)?;
    let detection = detect_pitch(
        frame,
        DetectorConfig {
            min_hz: 50.0,
            max_hz: 1200.0,
            noise_gate_db: state.noise_gate_db,
        },
    )
    .map_err(map_frame_error)?;
    let smoothed = state.smoother.apply(detection);
    if smoothed.hz <= 0.0 {
        return Ok(PerformanceResultV1::empty(
            timestamp_ms,
            state.onset_sequence,
        ));
    }
    let (midi, cents) = hz_to_midi_and_cents(smoothed.hz, state.a4_hz);
    let mut result = PerformanceResultV1::empty(timestamp_ms, state.onset_sequence);
    result.observation_kind = PerformanceObservationKind::Note as u32;
    result.confidence = finite_unit(smoothed.confidence);
    result.hz = smoothed.hz;
    result.cents = cents;
    result.midi = midi;
    Ok(result)
}

fn process_chord(
    state: &mut PerformanceHandle,
    pcm: &[f32],
    sample_rate: u32,
    timestamp_ms: u64,
) -> Result<PerformanceResultV1, PerformanceErrorCode> {
    let evidence = state
        .chord_analyzer
        .process(pcm, sample_rate)
        .map_err(map_polyphonic_error)?;
    let mut result = PerformanceResultV1::empty(timestamp_ms, state.onset_sequence);
    result.observation_kind = PerformanceObservationKind::Chord as u32;
    result.confidence = finite_unit(evidence.confidence);
    result.pitch_class_strengths = evidence.pitch_class_strengths.map(finite_unit);
    result.onset_confidence = finite_unit(evidence.onset_confidence);
    Ok(result)
}

fn parse_target(raw: PerformanceTargetV1) -> Result<Target, PerformanceErrorCode> {
    validate_header(
        raw.abi_version,
        raw.struct_size,
        size_of_u32::<PerformanceTargetV1>(),
    )?;
    match raw.target_kind {
        value if value == PerformanceObservationKind::Note as u32 => {
            if !(0..=127).contains(&raw.midi) || raw.pitch_class_count != 0 {
                return Err(PerformanceErrorCode::InvalidTarget);
            }
            Ok(Target::Note(raw.midi as u8))
        }
        value if value == PerformanceObservationKind::Chord as u32 => {
            let count = raw.pitch_class_count as usize;
            if !(2..=3).contains(&count)
                || raw.pitch_classes[..count].iter().any(|value| *value > 11)
            {
                return Err(PerformanceErrorCode::InvalidTarget);
            }
            let mut unique = raw.pitch_classes[..count].to_vec();
            unique.sort_unstable();
            unique.dedup();
            if unique.len() != count || !is_supported_chord(&unique) {
                return Err(PerformanceErrorCode::InvalidTarget);
            }
            Ok(Target::Chord {
                pitch_classes: raw.pitch_classes,
                count: count as u8,
            })
        }
        _ => Err(PerformanceErrorCode::InvalidTarget),
    }
}

fn is_supported_chord(pitch_classes: &[u8]) -> bool {
    (0_u8..12).any(|root| {
        let mut major = vec![root, (root + 4) % 12, (root + 7) % 12];
        let mut minor = vec![root, (root + 3) % 12, (root + 7) % 12];
        let mut power = vec![root, (root + 7) % 12];
        major.sort_unstable();
        minor.sort_unstable();
        power.sort_unstable();
        pitch_classes == major || pitch_classes == minor || pitch_classes == power
    })
}

fn validate_header(
    version: u32,
    actual_size: u32,
    expected_size: u32,
) -> Result<(), PerformanceErrorCode> {
    if version != PERFORMANCE_ABI_VERSION {
        return Err(PerformanceErrorCode::UnsupportedAbiVersion);
    }
    if actual_size != expected_size {
        return Err(PerformanceErrorCode::InvalidStructSize);
    }
    Ok(())
}

fn map_frame_error(error: &str) -> PerformanceErrorCode {
    match error {
        "invalid_sample_rate" => PerformanceErrorCode::InvalidSampleRate,
        "invalid_frame" | "frame_too_short" => PerformanceErrorCode::InvalidFrame,
        _ => PerformanceErrorCode::InternalError,
    }
}

fn map_polyphonic_error(error: PolyphonicError) -> PerformanceErrorCode {
    match error {
        PolyphonicError::InvalidSampleRate => PerformanceErrorCode::InvalidSampleRate,
        PolyphonicError::EmptyFrame
        | PolyphonicError::FrameTooShort
        | PolyphonicError::NonFiniteSample => PerformanceErrorCode::InvalidFrame,
    }
}

fn hz_to_midi_and_cents(hz: f32, a4_hz: f32) -> (i32, f32) {
    let exact_midi = 69.0 + 12.0 * (hz / a4_hz).log2();
    let midi = exact_midi.round() as i32;
    let reference_hz = a4_hz * 2.0_f32.powf((midi - 69) as f32 / 12.0);
    (midi.clamp(0, 127), 1200.0 * (hz / reference_hz).log2())
}

fn finite_unit(value: f32) -> f32 {
    if value.is_finite() {
        value.clamp(0.0, 1.0)
    } else {
        0.0
    }
}

fn size_of_u32<T>() -> u32 {
    std::mem::size_of::<T>() as u32
}

fn status_code(
    result: Result<Result<(), PerformanceErrorCode>, Box<dyn std::any::Any + Send>>,
) -> i32 {
    match result {
        Ok(Ok(())) => PerformanceErrorCode::Ok as i32,
        Ok(Err(code)) => code as i32,
        Err(_) => PerformanceErrorCode::InternalError as i32,
    }
}
