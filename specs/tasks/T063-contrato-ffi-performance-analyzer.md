# T063 - ABI FFI del PerformanceAnalyzer

## Estado
- done

## Prioridad
- P0

## Epic
- E08, E03

## Dependencias
- T057, T062

## Objetivo
Definir e implementar un ABI independiente para observaciones educativas monofonicas/polifonicas sin cambiar `tuner_*`.

## Entradas
- `rust/engine/FFI_CONTRACT.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Funciones `performance_init`, `performance_set_target`, `performance_process_frame`, `performance_dispose`.
- Structs C ABI versionados con tamaños/tipos fijos.
- Resultado discriminado nota/acorde, 12 strengths, onset y errores.
- Validacion de punteros, longitudes, sample rate y lifecycle.
- Documentacion y tests de integracion ABI.

## Fuera de alcance
- Captura de microfono, BLoC o UI.

## Criterios de aceptación
- `tuner_*` permanece binariamente igual.
- Layout ABI documentado y comprobado.
- Handle invalido y frames corruptos no causan crash.
- Start/setTarget/process/dispose repetido queda cubierto.

## Evidencia de cierre
- Inicio autorizado con T062 aun `in_progress`: su DSP y tests sinteticos estan
  disponibles; solo se aplaza el corpus grabado y sus metricas hasta la
  validacion final de la app sin musica.
- Implementado `rust/engine/src/performance_ffi.rs` como borde Rust independiente
  con `performance_init`, `performance_set_target`, `performance_process_frame`
  y `performance_dispose`; no importa lecciones ni decide acierto/fallo.
- ABI v1 documentado en `rust/engine/FFI_CONTRACT.md`: config de 32 bytes, target
  de 40 bytes y resultado discriminado de 112 bytes, con offsets, rangos,
  ownership, lifecycle y 11 codigos de error explicitos.
- Nota y acorde comparten timestamp monotonico y `onset_sequence` no decreciente.
  Target nulo limpia evaluacion, repetir target es idempotente y cambiarlo limpia
  solo smoothing/acumulacion. El resultado de acorde conserva 12 fortalezas C..B.
- Punteros nulos/desalineados, tamaños de frame fuera de 256..8192, sample rate
  fuera de 8..192 kHz, NaN, version/tamaño de struct, settings, target y timestamp
  invalidos se rechazan sin panic; todas las fronteras traducen panic interno.
- `rust/engine/tests/performance_ffi_abi.rs`: 5 pruebas de integración cubren
  layouts/offsets, firmas legacy, nota, acorde, target nulo, repetición y errores.
- `git diff --exit-code -- rust/engine/src/ffi.rs` -> limpio: `tuner_*` y
  `PitchResult` no cambiaron; sus firmas tambien se fijan en el test ABI.
- `cargo fmt --check` -> limpio.
- `cargo clippy --all-targets -- -D warnings` -> limpio.
- `cargo test --all-targets` -> 33 pruebas superadas; el unico ignored sigue
  siendo el corpus grabado pendiente de T062.
- `cargo build --release` -> limpio.
- `git diff --check` -> limpio (solo avisos informativos LF/CRLF existentes).
- Los gates Flutter ya vigentes siguen siendo 173 passed, 1 skip y analyze exit
  0 porque T063 no cambia Dart. El reintento del gate global quedo esperando al
  proceso Dart preexistente PID 28632 (iniciado antes de esta task) y se cancelo
  sin terminar dicho proceso ajeno.
- Capas preservadas: solo Rust/contrato/tests; sin cambios Domain, Data,
  Presentation o App y sin ampliar `TunerEngine`.
