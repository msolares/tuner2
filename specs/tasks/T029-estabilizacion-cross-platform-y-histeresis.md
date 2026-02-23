# T029 - Estabilizacion cross-platform y histeresis de nota

## Estado
- todo

## Prioridad
- P0

## Epic
- E04

## Dependencias
- T028, T025

## Objetivo
Reducir oscilaciones bruscas de lectura para que la nota objetivo sea legible, manteniendo reaccion suficiente ante cambios reales de afinacion.

## Entradas
- `lib/data/engines/mobile/mobile_ffi_tuner_engine.dart`
- `lib/data/engines/web/web_tuner_engine.dart`
- `lib/data/engines/common/simple_pitch_detector.dart`
- `lib/domain/entities/pitch_sample.dart`
- `specs/quality/dart-test-plan.md`

## Alcance
- Extraer estabilizacion comun para Web y movil (cuando aplique fallback Dart).
- Implementar histeresis/confirmacion de cambio de nota para evitar flicker.
- Unificar rangos por preset en un punto comun para evitar divergencias entre engines.
- Mantener intacto el contrato `TunerEngine` y estados BLoC.
- Agregar/ajustar tests de estabilidad en Dart.

## Fuera de alcance
- Cambio de arquitectura de BLoC o dominio.
- Rediseno de UI no funcional.
- Cambios de contrato FFI.

## Entregables
- Componente de estabilizacion comun en `lib/data/engines/common/`.
- Engines Web/movil consumiendo la logica comun de estabilizacion.
- Tests de secuencias con jitter, baja confidence y cambios rapidos reales.

## Criterios de aceptacion
- En nota sostenida, la lectura no alterna entre notas vecinas por ruido leve.
- Cambios reales de nota se detectan con latencia compatible con MVP.
- No regresion en start/stop ni en manejo de errores.
- `flutter test` en verde para modulos impactados.

## Riesgos
- Histeresis excesiva puede introducir retardo percibido al cambiar de cuerda.
- Parametros distintos por preset pueden requerir ajuste fino.

## Plan de implementacion
1. Definir algoritmo comun de estabilizacion (smoothing + hold + histeresis).
2. Integrar algoritmo en `WebTunerEngine` y `MobileFfiTunerEngine`.
3. Unificar tabla de rangos por preset y su uso en ambos engines.
4. Agregar pruebas de comportamiento temporal y anti-flicker.
5. Ajustar parametros para balance entre fluidez y respuesta.

## Evidencia de cierre
- Pendiente.
