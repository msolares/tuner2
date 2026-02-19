# T021 - Permisos de microfono runtime

## Estado
- todo

## Prioridad
- P0

## Epic
- E01

## Dependencias
- T009, T013

## Objetivo
Implementar solicitud y verificacion real de permisos de microfono en Android e iOS, reemplazando el flujo demo actual.

## Entregables
- Adaptador de permisos en `data` con API consumible por BLoC.
- Integracion de permisos reales en el flujo `StartListening`.
- Configuracion nativa minima para permisos en Android e iOS.

## Criterios de aceptacion
- La app solicita permiso de microfono en runtime al iniciar escucha por primera vez.
- Si el permiso es denegado, el estado de BLoC queda en `ErrorState` con `audio_permission_denied`.
- Si el permiso es concedido, el flujo continua sin usar botones demo.
- Android declara `RECORD_AUDIO` y iOS declara `NSMicrophoneUsageDescription`.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Inconsistencia entre estado de permiso del SO y estado interno del BLoC.

## Evidencia de cierre
- Pendiente.
