# T028 - Correccion de precision de pitch en Rust/FFI

## Estado
- todo

## Prioridad
- P0

## Epic
- E02, E03

## Dependencias
- T008, T023

## Objetivo
Corregir el motor Rust expuesto por FFI para que entregue `hz`, `note`, `cents` y `confidence` reales, estables y consistentes con el contrato de dominio.

## Entradas
- `rust/engine/src/detector.rs`
- `rust/engine/src/smoothing.rs`
- `rust/engine/src/ffi.rs`
- `rust/engine/FFI_CONTRACT.md`
- `rust/engine/PITCH_PIPELINE.md`
- `specs/quality/rust-test-plan.md`

## Alcance
- Reemplazar deteccion base por un metodo robusto para frecuencia fundamental (autocorrelacion normalizada con refinamiento de pico).
- Calcular nota y cents reales desde `hz` y `a4Hz`.
- Parsear y aplicar `config_json` (`a4Hz`, `instrumentPreset`, `noiseGateDb`, `smoothing`) en procesamiento real.
- Mantener firma de C ABI intacta (`tuner_init`, `tuner_process_frame`, `tuner_update_config`, `tuner_dispose`).
- Agregar pruebas Rust para exactitud minima, estabilidad basica y manejo de errores.

## Fuera de alcance
- Cambios de firma en contratos Dart de dominio.
- Cambios visuales/UI en Flutter.
- Evidencia E2E con microfono real por plataforma (se cubre en T030/T026).

## Entregables
- Implementacion Rust actualizada en `detector`, `smoothing` y `ffi`.
- Capa de configuracion del handle aplicada a cada frame.
- Tests unitarios/integracion Rust para lifecycle FFI y precision minima.

## Criterios de aceptacion
- `PitchResult.note` no es constante y corresponde a la frecuencia detectada.
- `PitchResult.cents` refleja desviacion real (no fijo en 0).
- `tuner_update_config` modifica comportamiento en caliente sin reiniciar handle.
- Error mediano en senales sostenidas sinteticas (82-880 Hz) <= +/- 5 cents.
- `cargo test` en verde para modulo `rust/engine`.

## Riesgos
- Mayor costo computacional de autocorrelacion en dispositivos de gama baja.
- Parametros de detector/smoothing mal calibrados pueden aumentar latencia.

## Plan de implementacion
1. Introducir modelo de configuracion tipado y parseo JSON robusto.
2. Implementar detector robusto y conversion a nota/cents.
3. Conectar configuracion + smoothing por handle en FFI.
4. Agregar pruebas de exactitud y lifecycle de errores.
5. Ajustar umbrales para balance precision/latencia.

## Evidencia de cierre
- Pendiente.
