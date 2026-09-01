# T073 - Contratos de audio real y beat map

## Estado
- todo

## Prioridad
- P1

## Epic
- E09

## Dependencias
- T072

## Objetivo
Implementar los contratos E09 de backing track, beat map y playback sin modificar `LessonChart` ni casos de uso E08.

## Entradas
- `specs/epics/E09-audio-real-y-sincronizacion.md`

## Alcance
- Entidades, invariantes, errores y puertos.
- Conversion tick/audio mediante interpolacion monotona.
- Tests de beat maps incompletos, invalidos y variables.

## Fuera de alcance
- Reproductor concreto, UI o contenido comercial.

## Criterios de aceptación
- Domain permanece libre de plugins.
- E08 funciona sin construir estos puertos.
- Interpolacion/inversion tick-ms tiene tests de limites.

## Evidencia de cierre
- Pendiente.
