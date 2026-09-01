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

Config JSON esperado:

- `a4Hz: number` (se normaliza internamente para conversion de nota/cents)
- `instrumentPreset: string` (`chromatic`, `guitar_standard`, `bass_standard`, `ukulele_standard`, `violin_standard`)
- `noiseGateDb: number` (umbral de energia en dB)
- `smoothing: number` (factor esperado en `[0.0, 1.0]`)

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

## PerformanceAnalyzer ABI v1 (T063)

Este ABI es independiente. No modifica firmas, layouts, simbolos ni codigos de
`tuner_*`.

Funciones exportadas:

```c
uint64_t performance_init(const PerformanceConfigV1 *config);
int32_t performance_set_target(uint64_t handle, const PerformanceTargetV1 *target);
PerformanceResultV1 performance_process_frame(
    uint64_t handle,
    const float *pcm,
    uintptr_t len,
    uint32_t sample_rate,
    uint64_t timestamp_ms);
int32_t performance_dispose(uint64_t handle);
```

`performance_set_target(handle, NULL)` limpia el target de forma idempotente.
Mientras no existe target, `process_frame` devuelve `Ok` con
`observation_kind = 0`; no produce una observacion de dominio. Repetir el mismo
target no reinicia el analyzer. Un cambio real limpia smoothing y acumulacion
cromatica, pero conserva `onset_sequence`, que nunca retrocede durante el handle.

Todos los structs usan C ABI, version `1`, little-endian en las plataformas
objetivo y campos de tamaño fijo. `struct_size` debe coincidir exactamente:

```c
typedef struct {                 // sizeof=32, align=4
  uint32_t abi_version;          // offset 0
  uint32_t struct_size;          // offset 4
  float a4_hz;                   // offset 8, 415..466
  float noise_gate_db;           // offset 12, -100..0
  uint32_t reserved[4];          // offset 16
} PerformanceConfigV1;

typedef struct {                 // sizeof=40, align=4
  uint32_t abi_version;          // offset 0
  uint32_t struct_size;          // offset 4
  uint32_t target_kind;          // offset 8: 1 note, 2 chord
  int32_t midi;                  // offset 12; note only, 0..127
  uint32_t pitch_class_count;    // offset 16; note=0, chord=2..3
  uint8_t pitch_classes[3];      // offset 20; unique C=0..B=11
  uint8_t reserved_u8;           // offset 23
  uint32_t reserved[4];          // offset 24
} PerformanceTargetV1;

typedef struct {                 // sizeof=112, align=8
  uint32_t abi_version;          // offset 0
  uint32_t struct_size;          // offset 4
  int32_t error_code;            // offset 8
  uint32_t observation_kind;     // offset 12: 0 none, 1 note, 2 chord
  uint64_t timestamp_ms;         // offset 16
  uint64_t onset_sequence;       // offset 24
  float confidence;              // offset 32
  float hz;                      // offset 36; note only
  float cents;                   // offset 40; note only
  int32_t midi;                  // offset 44; note only, otherwise -1
  float pitch_class_strengths[12]; // offset 48, chord only, C..B
  float onset_confidence;        // offset 96, chord only
  uint32_t reserved[3];          // offset 100
} PerformanceResultV1;
```

Los campos no aplicables y `reserved` salen a cero, salvo `midi = -1`. Un frame
aceptado contiene entre 256 y 8192 muestras finitas y sample rate 8000..192000.
El llamador conserva ownership de config, target y PCM durante cada llamada; un
puntero no nulo debe apuntar a memoria legible del tamaño declarado. El ABI
valida null, versión, tamaño, rangos y timestamps no decrecientes antes de usar
el estado del analyzer.

Codigos de error `performance_*`:

- `0` Ok.
- `1` NullPointer.
- `2` InvalidHandle.
- `3` InvalidFrame.
- `4` InvalidSampleRate.
- `5` UnsupportedAbiVersion.
- `6` InvalidStructSize.
- `7` InvalidSettings.
- `8` InvalidTarget.
- `9` NonMonotonicTimestamp.
- `10` InternalError.

`performance_init` devuelve `0` ante cualquier error. `dispose` libera una vez;
una repeticion devuelve `InvalidHandle` sin crash. Toda frontera captura panic y
lo traduce a `InternalError`. El ABI produce evidencia numérica y nunca decide
si el alumno ha acertado.
