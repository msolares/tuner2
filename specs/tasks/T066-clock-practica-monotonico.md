# T066 - Clock de practica monotónico

## Estado
- todo

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
- Pendiente.
