# T022 - Captura de audio Android/iOS

## Estado
- todo

## Prioridad
- P0

## Epic
- E01

## Dependencias
- T007, T021

## Objetivo
Implementar captura real de audio PCM en Android e iOS bajo los parametros definidos por plataforma.

## Entregables
- Fuente de frames PCM en `lib/data/audio/` para Android e iOS.
- Adaptacion a perfiles de captura (sample rate, buffer, mono) definidos en T007.
- Manejo de inicio/parada repetidos sin fugas de recursos.

## Criterios de aceptacion
- La captura abre microfono y produce frames continuos en Android/iOS.
- Se aplican parametros de T007 con fallback controlado de sample rate.
- `start/stop/start` no deja recursos colgados ni crashea.
- Errores de dispositivo no disponible se reportan como `audio_device_unavailable`.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Diferencias de buffer efectivo entre dispositivos que afecten latencia.

## Evidencia de cierre
- Pendiente.
