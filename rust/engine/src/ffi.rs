use crate::detector::{detect_pitch, Detection, DetectorConfig};
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
    config: EngineConfig,
    smoother: Smoother,
}

static NEXT_HANDLE: AtomicU64 = AtomicU64::new(1);
static HANDLES: OnceLock<Mutex<HashMap<u64, EngineHandle>>> = OnceLock::new();

fn handles() -> &'static Mutex<HashMap<u64, EngineHandle>> {
    HANDLES.get_or_init(|| Mutex::new(HashMap::new()))
}

#[derive(Debug, Clone)]
struct EngineConfig {
    a4_hz: f32,
    instrument_preset: String,
    noise_gate_db: f32,
    smoothing: f32,
}

impl Default for EngineConfig {
    fn default() -> Self {
        Self {
            a4_hz: 440.0,
            instrument_preset: "chromatic".to_owned(),
            noise_gate_db: -60.0,
            smoothing: 0.2,
        }
    }
}

#[derive(Debug, Clone, Copy)]
struct PitchRange {
    min_hz: f32,
    max_hz: f32,
}

fn parse_config_ptr(config_json_ptr: *const c_char) -> Result<EngineConfig, ErrorCode> {
    if config_json_ptr.is_null() {
        return Err(ErrorCode::NullPointer);
    }
    let c_str = unsafe { CStr::from_ptr(config_json_ptr) };
    let config_text = c_str.to_str().map_err(|_| ErrorCode::InvalidUtf8)?;
    parse_engine_config(config_text)
}

fn parse_engine_config(config_text: &str) -> Result<EngineConfig, ErrorCode> {
    let mut parser = JsonParser::new(config_text);
    let mut config = EngineConfig::default();

    parser.consume_byte(b'{')?;
    parser.skip_whitespace();
    if parser.try_consume_byte(b'}') {
        return Ok(config);
    }

    loop {
        let key = parser.parse_string()?;
        parser.skip_whitespace();
        parser.consume_byte(b':')?;
        parser.skip_whitespace();

        match key.as_str() {
            "a4Hz" => {
                config.a4_hz = parser.parse_number()?;
            }
            "instrumentPreset" => {
                config.instrument_preset = parser.parse_string()?;
            }
            "noiseGateDb" => {
                config.noise_gate_db = parser.parse_number()?;
            }
            "smoothing" => {
                config.smoothing = parser.parse_number()?;
            }
            _ => parser.skip_value()?,
        }

        parser.skip_whitespace();
        if parser.try_consume_byte(b',') {
            parser.skip_whitespace();
            continue;
        }
        parser.consume_byte(b'}')?;
        break;
    }

    parser.skip_whitespace();
    if !parser.is_end() {
        return Err(ErrorCode::InvalidJson);
    }
    if !config.a4_hz.is_finite()
        || !config.noise_gate_db.is_finite()
        || !config.smoothing.is_finite()
    {
        return Err(ErrorCode::InvalidJson);
    }

    Ok(config)
}

struct JsonParser<'a> {
    bytes: &'a [u8],
    index: usize,
}

impl<'a> JsonParser<'a> {
    fn new(text: &'a str) -> Self {
        Self {
            bytes: text.as_bytes(),
            index: 0,
        }
    }

    fn is_end(&self) -> bool {
        self.index >= self.bytes.len()
    }

    fn skip_whitespace(&mut self) {
        while let Some(byte) = self.peek_byte() {
            if matches!(byte, b' ' | b'\n' | b'\r' | b'\t') {
                self.index += 1;
            } else {
                break;
            }
        }
    }

    fn peek_byte(&self) -> Option<u8> {
        self.bytes.get(self.index).copied()
    }

    fn consume_byte(&mut self, expected: u8) -> Result<(), ErrorCode> {
        match self.peek_byte() {
            Some(found) if found == expected => {
                self.index += 1;
                Ok(())
            }
            _ => Err(ErrorCode::InvalidJson),
        }
    }

    fn try_consume_byte(&mut self, expected: u8) -> bool {
        if matches!(self.peek_byte(), Some(found) if found == expected) {
            self.index += 1;
            return true;
        }
        false
    }

    fn parse_string(&mut self) -> Result<String, ErrorCode> {
        self.consume_byte(b'"')?;
        let mut out = String::new();

        while let Some(byte) = self.peek_byte() {
            self.index += 1;
            match byte {
                b'"' => return Ok(out),
                b'\\' => {
                    let escaped = self.peek_byte().ok_or(ErrorCode::InvalidJson)?;
                    self.index += 1;
                    match escaped {
                        b'"' => out.push('"'),
                        b'\\' => out.push('\\'),
                        b'/' => out.push('/'),
                        b'b' => out.push('\u{0008}'),
                        b'f' => out.push('\u{000c}'),
                        b'n' => out.push('\n'),
                        b'r' => out.push('\r'),
                        b't' => out.push('\t'),
                        b'u' => {
                            for _ in 0..4 {
                                let hex = self.peek_byte().ok_or(ErrorCode::InvalidJson)?;
                                self.index += 1;
                                if !hex.is_ascii_hexdigit() {
                                    return Err(ErrorCode::InvalidJson);
                                }
                            }
                        }
                        _ => return Err(ErrorCode::InvalidJson),
                    }
                }
                other => out.push(other as char),
            }
        }
        Err(ErrorCode::InvalidJson)
    }

    fn parse_number(&mut self) -> Result<f32, ErrorCode> {
        let start = self.index;
        while let Some(byte) = self.peek_byte() {
            if byte.is_ascii_digit() || matches!(byte, b'+' | b'-' | b'.' | b'e' | b'E') {
                self.index += 1;
            } else {
                break;
            }
        }

        if self.index == start {
            return Err(ErrorCode::InvalidJson);
        }

        let token = std::str::from_utf8(&self.bytes[start..self.index])
            .map_err(|_| ErrorCode::InvalidJson)?;
        token.parse::<f32>().map_err(|_| ErrorCode::InvalidJson)
    }

    fn skip_value(&mut self) -> Result<(), ErrorCode> {
        self.skip_whitespace();
        match self.peek_byte() {
            Some(b'"') => {
                let _ = self.parse_string()?;
                Ok(())
            }
            Some(b'{') => self.skip_object(),
            Some(b'[') => self.skip_array(),
            Some(b't') => self.consume_literal(b"true"),
            Some(b'f') => self.consume_literal(b"false"),
            Some(b'n') => self.consume_literal(b"null"),
            Some(_) => {
                let _ = self.parse_number()?;
                Ok(())
            }
            None => Err(ErrorCode::InvalidJson),
        }
    }

    fn skip_object(&mut self) -> Result<(), ErrorCode> {
        self.consume_byte(b'{')?;
        self.skip_whitespace();
        if self.try_consume_byte(b'}') {
            return Ok(());
        }

        loop {
            let _ = self.parse_string()?;
            self.skip_whitespace();
            self.consume_byte(b':')?;
            self.skip_whitespace();
            self.skip_value()?;
            self.skip_whitespace();
            if self.try_consume_byte(b',') {
                self.skip_whitespace();
                continue;
            }
            self.consume_byte(b'}')?;
            return Ok(());
        }
    }

    fn skip_array(&mut self) -> Result<(), ErrorCode> {
        self.consume_byte(b'[')?;
        self.skip_whitespace();
        if self.try_consume_byte(b']') {
            return Ok(());
        }

        loop {
            self.skip_value()?;
            self.skip_whitespace();
            if self.try_consume_byte(b',') {
                self.skip_whitespace();
                continue;
            }
            self.consume_byte(b']')?;
            return Ok(());
        }
    }

    fn consume_literal(&mut self, literal: &[u8]) -> Result<(), ErrorCode> {
        for expected in literal {
            self.consume_byte(*expected)?;
        }
        Ok(())
    }
}

fn map_internal_err(err: &str) -> ErrorCode {
    match err {
        "invalid_frame" | "frame_too_short" => ErrorCode::InvalidFrame,
        "invalid_sample_rate" => ErrorCode::InvalidSampleRate,
        _ => ErrorCode::InternalError,
    }
}

fn process_frame_internal(
    pcm: &[f32],
    sample_rate: u32,
    config: &EngineConfig,
) -> Result<Detection, &'static str> {
    let frame = validate_frame(pcm, sample_rate)?;
    let range = range_for_preset(&config.instrument_preset);
    detect_pitch(
        frame,
        DetectorConfig {
            min_hz: range.min_hz,
            max_hz: range.max_hz,
            noise_gate_db: config.noise_gate_db,
        },
    )
}

fn range_for_preset(preset: &str) -> PitchRange {
    match preset {
        "guitar_standard" => PitchRange {
            min_hz: 70.0,
            max_hz: 420.0,
        },
        "bass_standard" => PitchRange {
            min_hz: 30.0,
            max_hz: 260.0,
        },
        "ukulele_standard" => PitchRange {
            min_hz: 180.0,
            max_hz: 500.0,
        },
        "violin_standard" => PitchRange {
            min_hz: 180.0,
            max_hz: 1200.0,
        },
        _ => PitchRange {
            min_hz: 50.0,
            max_hz: 2000.0,
        },
    }
}

fn hz_to_note_and_cents(hz: f32, a4_hz: f32) -> (String, f32) {
    if hz <= 0.0 {
        return ("--".to_owned(), 0.0);
    }
    let safe_a4 = a4_hz.clamp(430.0, 450.0);
    let midi = 69.0 + 12.0 * (hz / safe_a4).log2();
    let nearest_midi = midi.round() as i32;
    let nearest_hz = safe_a4 * 2.0_f32.powf((nearest_midi - 69) as f32 / 12.0);
    let cents = 1200.0 * (hz / nearest_hz).log2();
    let names = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
    ];
    let index = ((nearest_midi % 12) + 12) % 12;
    let octave = nearest_midi / 12 - 1;
    (format!("{}{}", names[index as usize], octave), cents)
}

#[no_mangle]
pub extern "C" fn tuner_init(config_json_ptr: *const c_char) -> u64 {
    let result = catch_unwind(|| -> Result<u64, ErrorCode> {
        let config = parse_config_ptr(config_json_ptr)?;
        let handle_id = NEXT_HANDLE.fetch_add(1, Ordering::Relaxed);
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        guard.insert(
            handle_id,
            EngineHandle {
                smoother: Smoother::new(config.smoothing),
                config,
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
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        let state = guard.get_mut(&handle).ok_or(ErrorCode::InvalidHandle)?;
        let detection =
            process_frame_internal(pcm, sample_rate, &state.config).map_err(map_internal_err)?;
        let smoothed: SmoothedPitch = state.smoother.apply(detection);
        let (note, cents) = hz_to_note_and_cents(smoothed.hz, state.config.a4_hz);
        Ok(PitchResult::ok(
            smoothed.hz,
            cents,
            smoothed.confidence,
            &note,
        ))
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
        let config = parse_config_ptr(config_json_ptr)?;
        let mut guard = handles().lock().map_err(|_| ErrorCode::InternalError)?;
        let state = guard.get_mut(&handle).ok_or(ErrorCode::InvalidHandle)?;
        state.smoother.set_smoothing(config.smoothing);
        state.config = config;
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

#[cfg(test)]
mod tests {
    use super::{
        parse_engine_config, tuner_dispose, tuner_init, tuner_process_frame, tuner_update_config,
        ErrorCode, PitchResult,
    };
    use std::f32::consts::PI;
    use std::ffi::CString;

    #[test]
    fn returns_real_note_and_cents_instead_of_fixed_values() {
        let config = CString::new(
            r#"{"a4Hz":440.0,"instrumentPreset":"chromatic","noiseGateDb":-60.0,"smoothing":0.2}"#,
        )
        .expect("valid cstring");
        let handle = tuner_init(config.as_ptr());
        assert_ne!(handle, 0);

        let frame = sine_wave(329.63, 48_000, 4096);
        let result = tuner_process_frame(handle, frame.as_ptr(), frame.len(), 48_000);

        assert_eq!(result.error_code, ErrorCode::Ok as i32);
        let note = note_from_result(result);
        assert_eq!(note, "E4");
        assert!(result.cents.abs() < 12.0);

        assert_eq!(tuner_dispose(handle), ErrorCode::Ok as i32);
    }

    #[test]
    fn update_config_changes_cents_in_hot_mode() {
        let config = CString::new(
            r#"{"a4Hz":440.0,"instrumentPreset":"chromatic","noiseGateDb":-60.0,"smoothing":0.2}"#,
        )
        .expect("valid cstring");
        let handle = tuner_init(config.as_ptr());
        assert_ne!(handle, 0);

        let frame = sine_wave(440.0, 48_000, 4096);
        let baseline = tuner_process_frame(handle, frame.as_ptr(), frame.len(), 48_000);
        assert_eq!(baseline.error_code, ErrorCode::Ok as i32);

        let updated = CString::new(
            r#"{"a4Hz":442.0,"instrumentPreset":"chromatic","noiseGateDb":-60.0,"smoothing":0.2}"#,
        )
        .expect("valid cstring");
        assert_eq!(
            tuner_update_config(handle, updated.as_ptr()),
            ErrorCode::Ok as i32
        );

        let adjusted = tuner_process_frame(handle, frame.as_ptr(), frame.len(), 48_000);
        assert_eq!(adjusted.error_code, ErrorCode::Ok as i32);
        assert_eq!(note_from_result(adjusted), "A4");
        assert!(adjusted.cents < -5.0);

        assert_eq!(tuner_dispose(handle), ErrorCode::Ok as i32);
    }

    #[test]
    fn rejects_invalid_json_in_update_config() {
        let config = CString::new(
            r#"{"a4Hz":440.0,"instrumentPreset":"chromatic","noiseGateDb":-60.0,"smoothing":0.2}"#,
        )
        .expect("valid cstring");
        let handle = tuner_init(config.as_ptr());
        assert_ne!(handle, 0);

        let invalid = CString::new("{invalid json").expect("valid cstring");
        let code = tuner_update_config(handle, invalid.as_ptr());
        assert_eq!(code, ErrorCode::InvalidJson as i32);

        assert_eq!(tuner_dispose(handle), ErrorCode::Ok as i32);
    }

    #[test]
    fn parser_accepts_partial_json_with_defaults() {
        let config =
            parse_engine_config(r#"{"instrumentPreset":"guitar_standard"}"#).expect("valid config");
        assert_eq!(config.instrument_preset, "guitar_standard");
        assert_eq!(config.a4_hz, 440.0);
        assert_eq!(config.noise_gate_db, -60.0);
        assert_eq!(config.smoothing, 0.2);
    }

    #[test]
    fn parser_ignores_unknown_fields() {
        let config = parse_engine_config(
            r#"{"a4Hz":441.0,"instrumentPreset":"chromatic","noiseGateDb":-55.0,"smoothing":0.3,"extra":{"x":[1,2,3]}}"#,
        )
        .expect("valid config");
        assert_eq!(config.a4_hz, 441.0);
        assert_eq!(config.instrument_preset, "chromatic");
        assert_eq!(config.noise_gate_db, -55.0);
        assert_eq!(config.smoothing, 0.3);
    }

    #[test]
    fn parser_rejects_wrong_value_type() {
        let error = parse_engine_config(r#"{"smoothing":"0.2"}"#).expect_err("must fail");
        assert_eq!(error, ErrorCode::InvalidJson);
    }

    #[test]
    fn guitar_preset_resolves_harmonic_rich_g3_as_g3() {
        let config = CString::new(
            r#"{"a4Hz":440.0,"instrumentPreset":"guitar_standard","noiseGateDb":-60.0,"smoothing":0.2}"#,
        )
        .expect("valid cstring");
        let handle = tuner_init(config.as_ptr());
        assert_ne!(handle, 0);

        let frame = harmonic_wave(
            196.0,
            48_000,
            4096,
            &[(1.0, 0.18), (2.0, 0.63), (3.0, 0.30), (4.0, 0.18)],
        );

        let mut result = PitchResult::err(ErrorCode::InternalError);
        for _ in 0..4 {
            result = tuner_process_frame(handle, frame.as_ptr(), frame.len(), 48_000);
            assert_eq!(result.error_code, ErrorCode::Ok as i32);
        }

        assert_eq!(note_from_result(result), "G3");
        assert!(result.cents.abs() < 20.0, "cents drift: {}", result.cents);

        assert_eq!(tuner_dispose(handle), ErrorCode::Ok as i32);
    }

    fn note_from_result(result: PitchResult) -> String {
        let len = result.note_len as usize;
        String::from_utf8_lossy(&result.note[..len]).to_string()
    }

    fn sine_wave(frequency_hz: f32, sample_rate: u32, len: usize) -> Vec<f32> {
        (0..len)
            .map(|i| {
                let phase = 2.0 * PI * frequency_hz * i as f32 / sample_rate as f32;
                phase.sin() * 0.6
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
            .map(|i| {
                harmonics
                    .iter()
                    .map(|(multiple, amplitude)| {
                        let phase =
                            2.0 * PI * (fundamental_hz * *multiple) * i as f32 / sample_rate as f32;
                        phase.sin() * *amplitude
                    })
                    .sum::<f32>()
            })
            .collect()
    }
}
