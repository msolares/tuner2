# T066 - Clock de practica monotónico

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057

## Objetivo
Implementar `LessonClock` independiente de UI con velocidad, pause, seek y ticks basados en objetivos absolutos.

## Entradas
- `specs/learning/domain-contracts.md`
- `specs/learning/use-cases.md`

## Alcance
- Implementacion movil/Web compatible.
- Velocidad 0.50..1.00.
- Pause/resume/seek atomicos.
- Fake clock determinista para tests.
- Deteccion de callbacks vencidos sin rafagas.

## Fuera de alcance
- Audio real, metronomo audible o painter.

## Criterios de aceptación
- Sin deriva acumulada > 20 ms en 10 minutos.
- No usa repaint ni `Timer.periodic` acumulativo como autoridad.
- Operaciones repetidas no duplican scheduler/streams.
- Cambio de velocidad conserva posicion musical.

## Evidencia de cierre
- El contrato `LessonClock.start` recibe ahora el `tempoMap` inmutable del chart;
  se actualizaron `domain-contracts.md`, E08, UC-L03, AGENTS y los casos de uso
  afectados para no asumir un BPM fijo.
- Implementado `MonotonicLessonClock` en Data con `Stopwatch` monotónico y
  callbacks one-shot compatibles con movil/Web. La posicion se deriva siempre
  desde ancla temporal/posicional absoluta y atraviesa cambios de tempo.
- Start/stop/pause/resume/seek/setSpeed son idempotentes. Pause, seek y cambio de
  velocidad cancelan el objetivo anterior y reanclan atomicamente; el cambio de
  velocidad conserva la posicion musical.
- Los callbacks vencidos saltan deadlines atrasados y programan solo el siguiente
  objetivo futuro, sin `Timer.periodic`, rafagas ni acumulacion de deltas.
- Añadido `DeterministicLessonClock` reutilizable bajo `test/support/learning`
  para BLoC/casos de uso sin reloj real.
- Tests escritos para tempo fijo/variable, cuenta con tick negativo, deriva de
  diez minutos, cambio de velocidad, pause/resume/seek, idempotencia, callbacks
  tardios, entradas invalidas y error tipado del scheduler.
- Validacion no ejecutada por la politica de validacion diferida. Comandos para
  el propietario:
  - `dart format lib/data/learning/clock lib/domain/learning test/data/learning/clock test/domain/learning/lesson_ports_test.dart test/domain/learning/lesson_use_cases_test.dart test/support/learning`
  - `flutter test test/data/learning/clock test/domain/learning/lesson_ports_test.dart test/domain/learning/lesson_use_cases_test.dart`
  - `flutter test`
  - `flutter analyze --no-fatal-infos`
  - `git diff --check`
- Si un comando falla, T066 vuelve a `in_progress` antes de continuar con su
  dependencia T067.
