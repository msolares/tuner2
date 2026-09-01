# T067 - LessonBloc y lifecycle educativo

## Estado
- todo

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
- Pendiente.
