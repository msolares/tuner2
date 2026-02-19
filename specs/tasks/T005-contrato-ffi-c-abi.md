# T005 - Contrato FFI C ABI

## Estado
- done

## Prioridad
- P0

## Epic
- E03

## Dependencias
- T002, T004

## Objetivo
Definir firma de funciones FFI y codigos de error.

## Entregables
- API FFI con lifecycle y errores.

## Criterios de aceptacion
- Mapeo Dart-Rust completo y consistente.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- API FFI definida en `rust/engine/src/ffi.rs` con funciones:
- `tuner_init(config_json_ptr) -> handle`
- `tuner_process_frame(handle, pcm_ptr, len, sample_rate) -> PitchResult`
- `tuner_update_config(handle, config_json_ptr) -> error_code`
- `tuner_dispose(handle) -> error_code`
- Mapa Dart-Rust y codigos de error documentados en `rust/engine/FFI_CONTRACT.md`.
- Toolchain Rust habilitado con crate base en `rust/engine/Cargo.toml`.
- Validacion pendiente de compilacion en este entorno: `cargo check` falla por permisos de escritura del proceso `cargo` (`os error 5`).

