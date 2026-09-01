# T067 - LessonBloc y lifecycle educativo

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T058, T066

## Objetivo
Exponer los casos de uso educativos mediante un BLoC sin duplicar reglas de dominio.

## Entradas
- `specs/learning/use-cases.md`
- `specs/architecture/clean-architecture.md`

## Alcance
- Eventos de carga, start, stop, pausa, resume, velocidad, seccion, tick y observacion.
- Estado UI inmutable derivado de `LessonSessionState`.
- Suscripciones y errores recuperables.
- Background/foreground y dispose.

## Fuera de alcance
- Painter, XML, FFI, DSP o audio real.

## Criterios de aceptación
- BLoC importa solo domain.
- No calcula cents, acordes, ticks o reentrada.
- Cada suscripcion tiene cancelacion probada.
- Tests cubren todos los eventos y errores/lifecycle.

## Evidencia de cierre
- Implementados `LessonBloc`, eventos y estado inmutable bajo
  `lib/presentation/learning/bloc`; Presentation importa exclusivamente SDK,
  BLoC/Equatable, Domain y sus propios archivos, sin dependencias hacia Data,
  XML, FFI, plugins ni plataforma.
- El estado UI conserva la `LessonSessionState` como fuente de verdad y deriva
  de ella el estado educativo; carga y preparacion delegan en
  `LoadLessonUseCase` y `PrepareLessonSessionUseCase`.
- Start, stop, pausa, resume, velocidad, seleccion/repeticion de seccion, tick y
  observacion se serializan en una unica cola y se delegan a
  `LessonSessionController`; el BLoC no calcula cents, acordes, ticks, espera ni
  reentrada.
- Las suscripciones de `LessonClock` y `PerformanceAnalyzer` se crean sin
  duplicados y se cancelan en stop, background, error, recarga, cambio de
  seccion, final natural y dispose. Foreground conserva `ready` y nunca reinicia
  el microfono sin una accion explicita.
- Los fallos de carga/inicio/streams se exponen como `LessonException` tipada y
  recuperable; clock y analyzer conservan codigos diferenciados.
- Tests escritos en
  `test/presentation/learning/bloc/lesson_bloc_test.dart` para imports de capa,
  carga/error, todos los controles, ticks/observaciones, secciones, ambas
  cancelaciones, errores de streams, background/foreground y dispose.
- Validacion no ejecutada por la politica de validacion diferida. Comandos para
  el propietario:
  - `dart format lib/presentation/learning test/presentation/learning`
  - `flutter test test/presentation/learning/bloc/lesson_bloc_test.dart`
  - `flutter test`
  - `flutter analyze --no-fatal-infos`
  - `git diff --check`
- Si un comando falla, T067 vuelve a `in_progress` antes de continuar con una
  dependencia afectada.
