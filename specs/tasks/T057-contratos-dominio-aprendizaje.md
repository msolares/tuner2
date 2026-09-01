# T057 - Contratos de dominio del modo educativo

## Estado
- done

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
- Contratos implementados en `lib/domain/learning/`: chart, contenido, performance, sesion, errores, puertos y barrel publico.
- Las colecciones de dominio se copian defensivamente y usan vistas no modificables; entidades/value objects usan igualdad por valor y `copyWith` validado.
- Invariantes cubiertas: 960 PPQ, afinacion de seis cuerdas, timeline/mapas, pitch-cuerda-traste, power chords/triadas, metadata, MIDI, confidence, A4, politica y viewport.
- Test de arquitectura confirma que Domain no importa Flutter, BLoC, data, presentation, app, XML, FFI ni APIs de plataforma.
- `flutter test test/domain/learning`: 29 pruebas superadas.
- `flutter test`: 131 pruebas superadas y 1 skip preexistente documentado por el harness multiplataforma.
- `flutter analyze --no-fatal-infos`: exit 0, sin errores/warnings y 29 infos preexistentes fuera de T057.
- `dart format lib/domain/learning test/domain/learning`: limpio.
- `git diff --check`: limpio.
- Rust/FFI no se modifico; `cargo test` no aplica a T057.
- `TunerEngine` y `MetronomeEngine` permanecen sin cambios.
- Contrato `LessonClock.start` completado en T066 con `tempoMap`: era necesario
  para convertir tiempo monotónico a los ticks del chart sin asumir BPM fijo.
