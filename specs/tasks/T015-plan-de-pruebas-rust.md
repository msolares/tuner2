# T015 - Plan de pruebas Rust

## Estado
- done

## Prioridad
- P0

## Epic
- E05

## Dependencias
- T004, T005, T008

## Objetivo
Definir pruebas de exactitud y robustez del engine.

## Entregables
- Casos de detector, noise y seguridad basica.

## Criterios de aceptacion
- Metricas minimas de precision definidas.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Plan de pruebas de exactitud y robustez documentado en:
- `specs/quality/rust-test-plan.md`
- Casos definidos para:
- `input`, `detector`, `smoothing`, `ffi`.
- Metricas minimas de precision/latencia explicitadas.

