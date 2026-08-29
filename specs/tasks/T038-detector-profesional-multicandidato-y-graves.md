# T038 - Detector profesional multicandidato y estable en graves

## Estado
- done

## Prioridad
- P0

## Epic
- E02, E03, E04

## Dependencias
- T028, T037

## Objetivo
Reemplazar el detector base actual por un detector de pitch mas robusto para senales de guitarra, con mejor resolucion en graves (`E2`, `A2`), menor tendencia a subarmonicos/octavas falsas y senal interna suficiente para que capas superiores tomen decisiones mas fiables.

## Entradas
- `rust/engine/src/detector.rs`
- `rust/engine/src/input.rs`
- `rust/engine/src/smoothing.rs`
- `rust/engine/src/ffi.rs`
- `rust/engine/PITCH_PIPELINE.md`
- `specs/quality/rust-test-plan.md`
- `specs/quality/pitch-accuracy-protocol.md`

## Alcance
- Sustituir la seleccion actual de pitch por un algoritmo robusto orientado a guitarra (por ejemplo `MPM` o `YIN/CMNDF`) en la implementacion Rust.
- Extraer mas de un candidato fuerte por frame y una metrica de `clarity`/fiabilidad interna, sin romper el contrato publico FFI.
- Introducir ventana adaptativa o estrategia multirresolucion para mejorar especialmente `E2` y `A2`.
- Reducir errores por subarmonicos, octavas falsas y notas vecinas en senales ricas en armonicos.
- Agregar pruebas sinteticas para graves, armonicos de guitarra, senales fuera de rango y casos conocidos de sobreseleccion armonica.

## Fuera de alcance
- Portar todavia el nuevo detector a Web/Dart (se cubre en `T039`).
- Bloqueo temporal de cuerda, histeresis de cambio de nota o supresion de ataque (se cubre en `T040`).
- Rediseno visual del afinador.
- Cambio de firma publica FFI o de contratos de dominio.

## Entregables
- Detector Rust actualizado con estrategia robusta para fundamentales de guitarra.
- Tests Rust de regresion para `E2`, armonicos ricos y rechazo de pliegues a subarmonicos.
- Nota tecnica actualizada en `rust/engine/PITCH_PIPELINE.md`.

## Criterios de aceptacion
- `E2` sintetico y `E2` armonico rico convergen a la fundamental correcta con error compatible con `specs/quality/pitch-accuracy-protocol.md`.
- Una senal fuera de rango no se pliega a una lectura valida por subarmonico.
- La seleccion de pitch en senales de guitarra armonica reduce errores de octava/nota vecina frente al detector anterior.
- `cargo test` queda en verde para `rust/engine`.

## Riesgos
- El costo computacional del nuevo detector puede aumentar en dispositivos lentos.
- Una estrategia demasiado agresiva en graves puede degradar respuesta en cuerdas agudas.

## Plan de implementacion
1. Elegir e implementar el detector base robusto para Rust.
2. Incorporar seleccion multicandidata y metrica interna de claridad.
3. Añadir soporte de ventana adaptativa/multirresolucion para graves.
4. Conectar el nuevo resultado interno con la capa de smoothing/FFI sin cambiar contratos.
5. Agregar regresiones y comparar contra los casos problematicos conocidos.

## Evidencia de cierre
- Implementacion aplicada en:
  - `rust/engine/src/detector.rs`
  - `rust/engine/src/smoothing.rs`
  - `rust/engine/src/ffi.rs`
  - `rust/engine/PITCH_PIPELINE.md`
- Cambios tecnicos clave:
  - Sustitucion del detector base por una estrategia `CMNDF` multicandidata (familia YIN).
  - Seleccion interna de varios candidatos fuertes por frame con `clarity` y `candidate_count`.
  - Pasada adicional a media resolucion para reforzar graves (`E2`, `A2`).
  - Rechazo de folding fuera de rango usando coherencia con `zero crossing`.
  - Ajuste de `confidence` Rust para incorporar `clarity` y ambiguedad entre candidatos.
- Pruebas Rust agregadas/actualizadas:
  - `detector::tests::detects_harmonic_rich_e2_without_folding_to_upper_harmonic`
  - `detector::tests::resolves_low_a2_from_harmonic_rich_signal`
  - `ffi::tests::guitar_preset_resolves_harmonic_rich_e2_as_e2`
- Validaciones ejecutadas:
  - `cargo fmt --all` (ok)
  - `cargo clippy -- -D warnings` (ok)
  - `cargo test` (ok, 18 tests en verde)
