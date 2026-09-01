use afinador_engine::ffi::{
    tuner_dispose, tuner_init, tuner_process_frame, tuner_update_config, PitchResult,
};
use afinador_engine::performance_ffi::{
    performance_dispose, performance_init, performance_process_frame, performance_set_target,
    PerformanceConfigV1, PerformanceErrorCode, PerformanceObservationKind, PerformanceResultV1,
    PerformanceTargetV1, PERFORMANCE_ABI_VERSION,
};
use std::f32::consts::PI;
use std::ffi::c_char;
use std::mem::{offset_of, size_of};

const SAMPLE_RATE: u32 = 48_000;

#[test]
fn v1_layout_and_legacy_tuner_signatures_are_stable() {
    assert_eq!(size_of::<PerformanceConfigV1>(), 32);
    assert_eq!(offset_of!(PerformanceConfigV1, a4_hz), 8);
    assert_eq!(size_of::<PerformanceTargetV1>(), 40);
    assert_eq!(offset_of!(PerformanceTargetV1, pitch_classes), 20);
    assert_eq!(size_of::<PerformanceResultV1>(), 112);
    assert_eq!(offset_of!(PerformanceResultV1, timestamp_ms), 16);
    assert_eq!(offset_of!(PerformanceResultV1, pitch_class_strengths), 48);
    assert_eq!(offset_of!(PerformanceResultV1, onset_confidence), 96);

    let _: extern "C" fn(*const c_char) -> u64 = tuner_init;
    let _: extern "C" fn(u64, *const f32, usize, u32) -> PitchResult = tuner_process_frame;
    let _: extern "C" fn(u64, *const c_char) -> i32 = tuner_update_config;
    let _: extern "C" fn(u64) -> i32 = tuner_dispose;
}

#[test]
fn note_target_produces_versioned_note_observation() {
    let config = PerformanceConfigV1::default();
    let handle = performance_init(&config);
    assert_ne!(handle, 0);
    let target = note_target(69);
    assert_eq!(
        performance_set_target(handle, &target),
        PerformanceErrorCode::Ok as i32
    );
    assert_eq!(
        performance_set_target(handle, &target),
        PerformanceErrorCode::Ok as i32
    );

    let pcm = sine_wave(440.0, 4096);
    let result = performance_process_frame(handle, pcm.as_ptr(), pcm.len(), SAMPLE_RATE, 100);
    assert_eq!(result.abi_version, PERFORMANCE_ABI_VERSION);
    assert_eq!(
        result.struct_size as usize,
        size_of::<PerformanceResultV1>()
    );
    assert_eq!(result.error_code, PerformanceErrorCode::Ok as i32);
    assert_eq!(
        result.observation_kind,
        PerformanceObservationKind::Note as u32
    );
    assert_eq!(result.timestamp_ms, 100);
    assert_eq!(result.midi, 69);
    assert!(result.cents.abs() < 12.0);
    assert!(result.confidence.is_finite());
    assert_eq!(result.onset_sequence, 1);

    assert_eq!(performance_dispose(handle), PerformanceErrorCode::Ok as i32);
    assert_eq!(
        performance_dispose(handle),
        PerformanceErrorCode::InvalidHandle as i32
    );
}

#[test]
fn chord_target_produces_twelve_finite_strengths() {
    let config = PerformanceConfigV1::default();
    let handle = performance_init(&config);
    assert_ne!(handle, 0);
    let target = chord_target([0, 4, 7]);
    assert_eq!(
        performance_set_target(handle, &target),
        PerformanceErrorCode::Ok as i32
    );

    let pcm = chord_wave(&[48, 52, 55, 60, 64], 8192);
    let result = performance_process_frame(handle, pcm.as_ptr(), pcm.len(), SAMPLE_RATE, 250);
    assert_eq!(result.error_code, PerformanceErrorCode::Ok as i32);
    assert_eq!(
        result.observation_kind,
        PerformanceObservationKind::Chord as u32
    );
    assert!(result
        .pitch_class_strengths
        .iter()
        .all(|value| value.is_finite() && (0.0..=1.0).contains(value)));
    for pitch_class in [0, 4, 7] {
        assert!(result.pitch_class_strengths[pitch_class] >= 0.28);
    }
    assert!((0.0..=1.0).contains(&result.onset_confidence));
    assert_eq!(result.onset_sequence, 1);

    assert_eq!(performance_dispose(handle), PerformanceErrorCode::Ok as i32);
}

#[test]
fn null_target_clears_observations_without_resetting_lifecycle() {
    let config = PerformanceConfigV1::default();
    let handle = performance_init(&config);
    let target = note_target(69);
    assert_eq!(
        performance_set_target(handle, &target),
        PerformanceErrorCode::Ok as i32
    );
    assert_eq!(
        performance_set_target(handle, std::ptr::null()),
        PerformanceErrorCode::Ok as i32
    );

    let pcm = sine_wave(440.0, 4096);
    let result = performance_process_frame(handle, pcm.as_ptr(), pcm.len(), SAMPLE_RATE, 10);
    assert_eq!(result.error_code, PerformanceErrorCode::Ok as i32);
    assert_eq!(
        result.observation_kind,
        PerformanceObservationKind::None as u32
    );
    assert_eq!(performance_dispose(handle), PerformanceErrorCode::Ok as i32);
}

#[test]
fn invalid_inputs_return_errors_without_panicking_or_mutating_target() {
    assert_eq!(performance_init(std::ptr::null()), 0);
    let invalid_config = PerformanceConfigV1 {
        abi_version: 99,
        ..PerformanceConfigV1::default()
    };
    assert_eq!(performance_init(&invalid_config), 0);
    let invalid_size = PerformanceConfigV1 {
        struct_size: 0,
        ..PerformanceConfigV1::default()
    };
    assert_eq!(performance_init(&invalid_size), 0);

    let config = PerformanceConfigV1::default();
    let handle = performance_init(&config);
    let mut invalid_target = chord_target([0, 4, 6]);
    assert_eq!(
        performance_set_target(handle, &invalid_target),
        PerformanceErrorCode::InvalidTarget as i32
    );
    invalid_target.abi_version = 2;
    assert_eq!(
        performance_set_target(handle, &invalid_target),
        PerformanceErrorCode::UnsupportedAbiVersion as i32
    );
    assert_eq!(
        performance_set_target(u64::MAX, std::ptr::null()),
        PerformanceErrorCode::InvalidHandle as i32
    );

    let pcm = sine_wave(440.0, 4096);
    assert_error(
        performance_process_frame(handle, std::ptr::null(), pcm.len(), SAMPLE_RATE, 0),
        PerformanceErrorCode::NullPointer,
    );
    assert_error(
        performance_process_frame(handle, pcm.as_ptr(), 32, SAMPLE_RATE, 0),
        PerformanceErrorCode::InvalidFrame,
    );
    let unaligned_storage = vec![0_u8; pcm.len() * size_of::<f32>() + 1];
    let unaligned_ptr = unsafe { unaligned_storage.as_ptr().add(1).cast::<f32>() };
    assert_error(
        performance_process_frame(handle, unaligned_ptr, pcm.len(), SAMPLE_RATE, 0),
        PerformanceErrorCode::InvalidFrame,
    );
    assert_error(
        performance_process_frame(handle, pcm.as_ptr(), pcm.len(), 0, 0),
        PerformanceErrorCode::InvalidSampleRate,
    );
    let mut corrupt = pcm.clone();
    corrupt[20] = f32::NAN;
    assert_error(
        performance_process_frame(handle, corrupt.as_ptr(), corrupt.len(), SAMPLE_RATE, 0),
        PerformanceErrorCode::InvalidFrame,
    );

    let target = note_target(69);
    assert_eq!(
        performance_set_target(handle, &target),
        PerformanceErrorCode::Ok as i32
    );
    let valid = performance_process_frame(handle, pcm.as_ptr(), pcm.len(), SAMPLE_RATE, 50);
    assert_eq!(valid.error_code, PerformanceErrorCode::Ok as i32);
    assert_error(
        performance_process_frame(handle, pcm.as_ptr(), pcm.len(), SAMPLE_RATE, 49),
        PerformanceErrorCode::NonMonotonicTimestamp,
    );
    assert_error(
        performance_process_frame(u64::MAX, pcm.as_ptr(), pcm.len(), SAMPLE_RATE, 0),
        PerformanceErrorCode::InvalidHandle,
    );
    assert_eq!(performance_dispose(handle), PerformanceErrorCode::Ok as i32);
}

fn note_target(midi: i32) -> PerformanceTargetV1 {
    PerformanceTargetV1 {
        abi_version: PERFORMANCE_ABI_VERSION,
        struct_size: size_of::<PerformanceTargetV1>() as u32,
        target_kind: PerformanceObservationKind::Note as u32,
        midi,
        pitch_class_count: 0,
        pitch_classes: [0; 3],
        reserved_u8: 0,
        reserved: [0; 4],
    }
}

fn chord_target(pitch_classes: [u8; 3]) -> PerformanceTargetV1 {
    PerformanceTargetV1 {
        abi_version: PERFORMANCE_ABI_VERSION,
        struct_size: size_of::<PerformanceTargetV1>() as u32,
        target_kind: PerformanceObservationKind::Chord as u32,
        midi: -1,
        pitch_class_count: 3,
        pitch_classes,
        reserved_u8: 0,
        reserved: [0; 4],
    }
}

fn assert_error(result: PerformanceResultV1, expected: PerformanceErrorCode) {
    assert_eq!(result.error_code, expected as i32);
    assert_eq!(
        result.observation_kind,
        PerformanceObservationKind::None as u32
    );
}

fn sine_wave(hz: f32, len: usize) -> Vec<f32> {
    (0..len)
        .map(|index| (2.0 * PI * hz * index as f32 / SAMPLE_RATE as f32).sin() * 0.4)
        .collect()
}

fn chord_wave(notes: &[i32], len: usize) -> Vec<f32> {
    let scale = 0.32 / notes.len() as f32;
    (0..len)
        .map(|index| {
            let attack = (index as f32 / 240.0).min(1.0);
            notes
                .iter()
                .map(|midi| {
                    let hz = 440.0 * 2.0_f32.powf((*midi as f32 - 69.0) / 12.0);
                    (2.0 * PI * hz * index as f32 / SAMPLE_RATE as f32).sin()
                })
                .sum::<f32>()
                * scale
                * attack
        })
        .collect()
}
