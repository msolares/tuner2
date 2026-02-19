# T016 - Pruebas de integracion FFI

## Estado
- done

## Prioridad
- P0

## Epic
- E05

## Dependencias
- T005, T014, T015

## Objetivo
Definir casos end-to-end Flutter-Rust.

## Entregables
- Set de entradas PCM y salidas esperadas.

## Criterios de aceptacion
- Tolerancias numericas y errores controlados.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Plan E2E Flutter-Rust con entradas PCM y salidas esperadas:
- `specs/quality/ffi-integration-test-plan.md`
- Tolerancias numericas definidas para `hz`, `cents` y `confidence`.
- Errores controlados definidos (`invalid_handle`, `invalid_frame`, `invalid_sample_rate`, `invalid_json`).

