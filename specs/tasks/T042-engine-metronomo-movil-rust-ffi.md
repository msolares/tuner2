# T042 - Engine móvil y salida de audio del metrónomo

## Estado
- in_progress

## Prioridad
- P0

## Epic
- E07, E03

## Dependencias
- T041

## Objetivo
Implementar en Android e iOS un engine de metrónomo estable, gobernado por reloj monotónico y desacoplado mediante un sink de audio.

## Entradas
- `specs/epics/E07-metronomo.md`
- `rust/engine/`
- `lib/data/engines/mobile/`

## Alcance
- Implementar scheduler absoluto sin `Timer.periodic`.
- Implementar síntesis WAV de clic fuerte/normal y silencios.
- Implementar pool de reproductores nativos de baja latencia.
- Implementar start, update en límite de compás, stop y dispose idempotentes.
- Adaptar eventos temporales a `Stream<MetronomeTick>`.
- Medir jitter, deriva y liberación de recursos.

## Fuera de alcance
- Engine Web, BLoC o UI.

## Entregables
- Implementación Dart en `data`, sink nativo y tests de contrato/temporización.

## Criterios de aceptación
- Cumple los presupuestos temporales de E07 en Android e iOS objetivo.
- Los cambios de configuración no duplican ni cortan pulsos.
- Start/stop repetido no deja hilos, handles ni streams activos.
- Los errores llegan a Dart de forma tipada y recuperable.
- Las pruebas Dart del adaptador quedan en verde y Android/iOS compilan.

## Riesgos
- La latencia del backend puede variar por dispositivo y requiere medición física.

## Evidencia de cierre
- Scheduler, síntesis y sink móvil implementados en `lib/data/metronome/`.
- Prueba automatizada de orden de ticks, acentos y cleanup en verde.
- `flutter build apk --debug --no-pub`: correcto; APK generado.
- Pendiente antes de marcar `done`: compilación y prueba física de audio en iOS.
