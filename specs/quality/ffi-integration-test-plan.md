# Plan de pruebas integracion FFI (T016)

## Objetivo

Validar flujo end-to-end Flutter <-> Rust con entradas PCM controladas y tolerancias numericas.

## Set de entradas PCM (referencia)

| ID | Descripcion | Sample rate | Duracion | Resultado esperado |
|---|---|---:|---:|---|
| `PCM_A4_CLEAN` | seno 440 Hz, amplitud estable | 48000 | 500 ms | `hz` ~ 440, `confidence` alta |
| `PCM_E2_CLEAN` | seno 82.41 Hz | 48000 | 500 ms | `hz` ~ 82.41 |
| `PCM_NOISE_LOW` | ruido blanco bajo | 48000 | 500 ms | `confidence` baja, sin crash |
| `PCM_SILENCE` | silencio | 48000 | 500 ms | `hz` 0 o invalido controlado |
| `PCM_SR_UNSUPPORTED` | frame valido con sample rate no soportado | 12345 | 300 ms | error `ffi_invalid_sample_rate` |

## Tolerancias numericas

- `abs(hz_obtenido - hz_esperado) <= 1.5 Hz` en senal limpia.
- `abs(cents_obtenido) <= 8` para nota objetivo estable.
- `confidence` en rango `[0.0, 1.0]`.

## Casos de errores controlados

- `handle = 0` o inexistente -> `ffi_invalid_handle`.
- `pcm_ptr = null` -> `NullPointer`.
- `len = 0` -> `InvalidFrame`.
- `config_json` invalido en init/update -> `InvalidJson`.

## Flujo de prueba E2E

1. `tuner_init` con config valida.
2. `tuner_process_frame` con set de PCM.
3. `tuner_update_config` en caliente (A4/preset).
4. `tuner_dispose`.
5. Repetir ciclo start/stop >= 20 iteraciones sin leak.
