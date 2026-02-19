# Contrato FFI C ABI (T005)

Funciones exportadas:

- `tuner_init(config_json_ptr) -> handle`
- `tuner_process_frame(handle, pcm_ptr, len, sample_rate) -> pitch_result`
- `tuner_update_config(handle, config_json_ptr) -> error_code`
- `tuner_dispose(handle) -> error_code`

Mapeo Dart-Rust:

- `handle`:
- Rust: `u64`
- Dart FFI: `Uint64`
- `config_json_ptr`:
- Rust: `*const c_char` (UTF-8, null-terminated)
- Dart FFI: `Pointer<Utf8>`
- `pcm_ptr`:
- Rust: `*const f32`
- Dart FFI: `Pointer<Float>`
- `len`:
- Rust: `usize`
- Dart FFI: `IntPtr`
- `sample_rate`:
- Rust: `u32`
- Dart FFI: `Uint32`

Estructura `PitchResult`:

- `error_code: i32`
- `hz: f32`
- `cents: f32`
- `confidence: f32`
- `note_len: u8`
- `note: [u8; 8]` (ASCII, truncado si excede 8 bytes)

Codigos de error (`i32`):

- `0` `Ok`
- `1` `NullPointer`
- `2` `InvalidHandle`
- `3` `InvalidFrame`
- `4` `InvalidSampleRate`
- `5` `InvalidUtf8`
- `6` `InvalidJson`
- `7` `InternalError`

Notas de lifecycle:

1. `tuner_init` devuelve `0` cuando falla inicializacion.
2. `tuner_process_frame` valida handle + frame y devuelve `PitchResult.error_code`.
3. `tuner_update_config` permite cambio de config en caliente.
4. `tuner_dispose` libera handle y reporta error en handle invalido.
