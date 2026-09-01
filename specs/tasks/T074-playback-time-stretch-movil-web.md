# T074 - Playback con time-stretch movil y Web

## Estado
- todo

## Prioridad
- P1

## Epic
- E09

## Dependencias
- T073

## Objetivo
Implementar `LessonPlaybackEngine` en movil y Web con velocidad 50..100%, pitch preservado y posicion observable.

## Entradas
- `specs/epics/E09-audio-real-y-sincronizacion.md`
- `specs/quality/web-compat-matrix.md`

## Alcance
- Load/play/pause/seek/speed/stop.
- Time-stretch sin cambio tonal.
- Posicion y errores equivalentes.
- Pruebas de pitch, memoria, lifecycle y formatos admitidos.

## Fuera de alcance
- Streaming DRM, stems o sincronizacion de sesion.

## Criterios de aceptación
- Desviacion tonal <= 5 cents en rango.
- Stop libera recursos y setSpeed no reinicia pista.
- Movil/Web cumplen suite de conformidad.
- Limitaciones de formato quedan documentadas antes de cierre.

## Evidencia de cierre
- Pendiente.
