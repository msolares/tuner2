use crate::detector::{detect_pitch, Detection};
use crate::input::validate_frame;
use crate::smoothing::{SmoothedPitch, Smoother};
use std::collections::HashMap;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::panic::catch_unwind;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Mutex, OnceLock};

const NOTE_CAPACITY: usize = 8;

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorCode {
    Ok = 0,
    NullPointer = 1,
    InvalidHandle = 2,
    InvalidFrame = 3,
    InvalidSampleRate = 4,
    InvalidUtf8 = 5,
    InvalidJson = 6,
    InternalError = 7,
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct PitchResult {
    pub error_code: i32,
    pub hz: f32,
    pub cents: f32,
    pub confidence: f32,
    pub note_len: u8,
    pub note: [u8; NOTE_CAPACITY],
}

impl PitchResult {
    fn ok(hz: f32, cents: f32, confidence: f32, note_str: &str) -> Self {
        let mut note = [0u8; NOTE_CAPACITY];
        let bytes = note_str.as_bytes();
        let len = bytes.len().min(NOTE_CAPACITY);
        note[..len].copy_from_slice(&bytes[..len]);
        Self {
            error_code: ErrorCode::Ok as i32,
            hz,
            cents,
            confidence,
            note_len: len as u8,
            note,
        }
    }

    fn err(code: ErrorCode) -> Self {
        Self {
            error_code: code as i32,
            hz: 0.0,
            cents: 0.0,
            confidence: 0.0,
            note_len: 0,
            note: [0u8; NOTE_CAPACITY],
        }
    }
}

#[derive(Debug, Clone)]
struct EngineHandle {
    config_json: String,
    smoother: Smoother,
}

static NEXT_HANDLE: AtomicU64 = AtomicU64::new(1);
static HANDLES: OnceLock<Mutex<HashMap<u64, EngineHandle>>> = OnceLock::new();

fn handles() -> &'static Mutex<HashMap<u64, EngineHandle>> {
    HANDLES.get_or_init(|| Mutex::new(HashMap::new()))
}

fn parse_json_ptr(config_json_ptr: *const c_char) -> Result<String, ErrorCode> {
    if config_json_ptr.is_null() {
        return Err(ErrorCode::NullPointer);
    }
    let c_str = unsafe { CStr::from_ptr(config_json_ptr) };
    let config = c_str.to_str().map_err(|_| ErrorCode::InvalidUtf8)?.to_owned();
    if !looks_like_json(&config) {
        return Err(ErrorCode::InvalidJson);
    }
    Ok(config)
}

fn looks_like_json(input: &str) -> bool {
    let trimmed = input.trim();
    (trimmed.starts_with('{') && trimmed.ends_with('}'))
        || (trimmed.starts_with('[') && trimmed.ends_with(']'))
}

fn map_internal_err(err: &str) -> ErrorCode {
    match err {
        "invalid_frame" | "frame_too_short" => ErrorCode::InvalidFrame,
        "invalid_sample_rate" => ErrorCode::InvalidSampleRate,
        _ => ErrorCode::InternalError,
    }
}

pub fn process_frame_internal(pcm: &[f32], sample_rate: u32) -> Result<Detection, &'static str> {
    let frame = validate_frame(pcm, sample_rate)?;
    detect_pitch(frame)
}

#[no_mangle]
pub extern "C" fn tuner_init(config_json_ptr: *const c_char) -> u64 {
    let result = catch_unwind(|| -> Result<u64, ErrorCode> {
        let config_json = parse_json_ptr(config_json_ptr)?;
        let handle_id = NEXT_HANDLE.fetch_add(1, Ordering::Relaxed);
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        guard.insert(
            handle_id,
            EngineHandle {
                config_json,
                smoother: Smoother::default(),
            },
        );
        Ok(handle_id)
    });

    match result {
        Ok(Ok(handle)) => handle,
        Ok(Err(_)) | Err(_) => 0,
    }
}

#[no_mangle]
pub extern "C" fn tuner_process_frame(
    handle: u64,
    pcm_ptr: *const f32,
    len: usize,
    sample_rate: u32,
) -> PitchResult {
    let result = catch_unwind(|| -> Result<PitchResult, ErrorCode> {
        if pcm_ptr.is_null() {
            return Err(ErrorCode::NullPointer);
        }
        if sample_rate == 0 {
            return Err(ErrorCode::InvalidSampleRate);
        }
        let pcm = unsafe { std::slice::from_raw_parts(pcm_ptr, len) };
        let detection = process_frame_internal(pcm, sample_rate).map_err(map_internal_err)?;
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        let state = guard.get_mut(&handle).ok_or(ErrorCode::InvalidHandle)?;
        let smoothed: SmoothedPitch = state.smoother.apply(detection);
        Ok(PitchResult::ok(smoothed.hz, 0.0, smoothed.confidence, "A4"))
    });

    match result {
        Ok(Ok(pitch)) => pitch,
        Ok(Err(code)) => PitchResult::err(code),
        Err(_) => PitchResult::err(ErrorCode::InternalError),
    }
}

#[no_mangle]
pub extern "C" fn tuner_update_config(handle: u64, config_json_ptr: *const c_char) -> i32 {
    let result = catch_unwind(|| -> Result<(), ErrorCode> {
        let config_json = parse_json_ptr(config_json_ptr)?;
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        let state = guard.get_mut(&handle).ok_or(ErrorCode::InvalidHandle)?;
        state.config_json = config_json;
        Ok(())
    });

    match result {
        Ok(Ok(())) => ErrorCode::Ok as i32,
        Ok(Err(code)) => code as i32,
        Err(_) => ErrorCode::InternalError as i32,
    }
}

#[no_mangle]
pub extern "C" fn tuner_dispose(handle: u64) -> i32 {
    let result = catch_unwind(|| -> Result<(), ErrorCode> {
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        if guard.remove(&handle).is_none() {
            return Err(ErrorCode::InvalidHandle);
        }
        Ok(())
    });

    match result {
        Ok(Ok(())) => ErrorCode::Ok as i32,
        Ok(Err(code)) => code as i32,
        Err(_) => ErrorCode::InternalError as i32,
    }
}
