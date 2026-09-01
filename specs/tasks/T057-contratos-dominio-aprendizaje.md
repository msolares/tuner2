# T057 - Contratos de dominio del modo educativo

## Estado
- todo

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T020, T051

## Objetivo
Implementar exactamente las entidades, value objects, errores y puertos cerrados en `specs/learning/domain-contracts.md`, sin modificar contratos del afinador o metronomo.

## Entradas
- `AGENTS.md`
- `specs/architecture/clean-architecture.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Entidades de chart, tuning, tempo, meter, seccion, nota y acorde.
- Targets y observaciones monofonicas/polifonicas.
- `LessonSummary`, `LessonCatalog`, `LessonChartDecoder`, `PerformanceAnalyzer`, `LessonClock`.
- Orden e invariantes del catalogo local.
- Politica de evaluacion, estados y errores tipados.
- Inmutabilidad, igualdad, copia y validacion.

## Fuera de alcance
- XML, DSP, FFI, clock concreto, BLoC o UI.

## Criterios de aceptación
- Todas las invariantes contractuales tienen tests de limites y rechazo.
- Domain no importa Flutter, data, XML, FFI ni plugins.
- `TunerEngine` y `MetronomeEngine` no cambian.
- Los nombres/unidades coinciden con la spec sin decisiones pendientes.

## Evidencia de cierre
- Pendiente.
