# T008 - Pipeline de deteccion pitch

## Estado
- done

## Prioridad
- P0

## Epic
- E02

## Dependencias
- T004, T007

## Objetivo
Definir algoritmo y smoothing para salida estable.

## Entregables
- Diseno de detector y confidence.

## Criterios de aceptacion
- Precision objetivo y latencia objetivo definidas.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Diseno de detector y confidence documentado en:
- `rust/engine/PITCH_PIPELINE.md`
- Implementacion base del detector en:
- `rust/engine/src/detector.rs`
- Implementacion de smoothing temporal y confidence en:
- `rust/engine/src/smoothing.rs`
- Integracion de smoothing por handle (estado entre frames) en:
- `rust/engine/src/ffi.rs`
- Precision objetivo definida: error mediano <= +/- 5 cents en notas sostenidas (82-880 Hz).
- Latencia objetivo definida: <= 70 ms movil y <= 100 ms Web para lectura estable.

