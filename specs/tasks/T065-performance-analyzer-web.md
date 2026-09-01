# T065 - PerformanceAnalyzer Web con paridad

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057, T062, T025, T039

## Objetivo
Implementar en Dart/Web el mismo contrato y semantica de evidencia monofonica/polifonica usando el corpus compartido.

## Entradas
- `specs/learning/domain-contracts.md`
- `specs/quality/learning-mode-test-plan.md`
- `lib/data/audio/web_*`

## Alcance
- Analisis dirigido nota/acorde.
- Strengths C..B, onset y confidence equivalentes.
- Uso del audio session Web existente.
- Control de CPU/buffer y errores tipados.
- Suite de conformidad compartida.

## Fuera de alcance
- Rust/Wasm, UI o reglas de acierto.

## Criterios de aceptación
- Diferencia de corpus <= 5 puntos porcentuales respecto a movil.
- No bloquea render ni crece el buffer.
- Start/stop y permisos siguen la politica Web existente.
- Mismo target produce observaciones semanticamente equivalentes.

## Evidencia de cierre
- Pendiente.
