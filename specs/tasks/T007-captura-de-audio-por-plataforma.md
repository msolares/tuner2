# T007 - Captura de audio por plataforma

## Estado
- done

## Prioridad
- P0

## Epic
- E01

## Dependencias
- T003, T006

## Objetivo
Definir parametros de captura por Android, iOS y Web.

## Entregables
- Tabla de sample rate, buffer y restricciones.

## Criterios de aceptacion
- Parametros por plataforma cerrados.
- Se adjunta evidencia de cierre en esta misma task.

## Riesgos
- Cambios de contrato entre capas si no se respeta esta task.

## Evidencia de cierre
- Tabla de parametros y restricciones documentada en:
- `lib/data/audio/README.md`
- Parametros por plataforma definidos de forma ejecutable en:
- `lib/data/audio/audio_capture_profile.dart`
- Plataformas cerradas para MVP:
- Android: 48k/1024/mono/float32 con fallback a 44.1k.
- iOS: 48k/1024/mono/float32 con ajuste posible de buffer por AVAudioSession.
- Web: 48k/2048/mono/float32 con sample rate efectivo controlado por navegador.

