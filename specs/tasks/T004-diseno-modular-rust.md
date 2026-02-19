# T004 - Diseno modular Rust

## Estado
- done

## Prioridad
- P0

## Epic
- E02

## Dependencias
- T001

## Objetivo
Definir modulos internos del engine Rust y responsabilidades.

## Entregables
- Mapa de modulos input, detector, smoothing, ffi.

## Criterios de aceptacion
- Cada modulo tiene responsabilidad unica.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Mapa modular y responsabilidades documentadas en:
- `rust/engine/README.md`
- Estructura de modulos creada en:
- `rust/engine/src/lib.rs`
- `rust/engine/src/input.rs`
- `rust/engine/src/detector.rs`
- `rust/engine/src/smoothing.rs`
- `rust/engine/src/ffi.rs`
- Verificacion de flujo interno por referencias:
- `ffi -> input -> detector -> smoothing` validado por imports y llamadas en `rust/engine/src/ffi.rs`.
- Nota: no se pudo ejecutar `cargo check` porque `cargo` no esta disponible en este entorno.

