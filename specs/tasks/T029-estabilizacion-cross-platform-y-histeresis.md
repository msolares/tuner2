# T029 - Estabilizacion cross-platform y histeresis de nota

## Estado
- done

## Prioridad
- P0

## Epic
- E04

## Dependencias
- T025, T037, T038, T039, T040

## Objetivo
Reducir oscilaciones bruscas de lectura para que la nota objetivo sea legible, manteniendo reaccion suficiente ante cambios reales de afinacion una vez que la senal de entrada ya venga robustecida por `T037`, `T038`, `T039` y `T040`.

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
- Corregir la ruta de respuesta rapida para cambios reales de cuerda/nota sin introducir retraso visible del medidor.
- Mantener intacto el contrato `TunerEngine` y estados BLoC.
- Agregar/ajustar tests de estabilidad en Dart.

## Fuera de alcance
- Cambio de arquitectura de BLoC o dominio.
- Rediseno de UI no funcional.
- Cambios de contrato FFI.
- Captura raw por plataforma y rechazo acustico de `voz`, aire o ventilador (se cubre en `T037`).
- Sustitucion del detector base Rust/Dart por otro algoritmo de pitch (se cubre en `T038` y `T039`).
- Bloqueo temporal de cuerda y supresion del ataque (se cubre en `T040`).

## Entregables
- Componente de estabilizacion comun en `lib/data/engines/common/`.
- Engines Web/movil consumiendo la logica comun de estabilizacion.
- Tests de secuencias con jitter, baja confidence y cambios rapidos reales.

## Criterios de aceptacion
- En nota sostenida, la lectura no alterna entre notas vecinas por ruido leve.
- Cambios reales de nota se detectan con latencia compatible con MVP.
- El medidor no queda rezagado por suavizado acumulado cuando hay salto real de cuerda.
- No regresion en start/stop ni en manejo de errores.
- `flutter test` en verde para modulos impactados.

## Riesgos
- Histeresis excesiva puede introducir retardo percibido al cambiar de cuerda.
- Parametros distintos por preset pueden requerir ajuste fino.

## Plan de implementacion
1. Definir algoritmo comun de estabilizacion (smoothing + hold + histeresis) sobre frames ya robustecidos y filtrados por `T037`, `T038`, `T039` y `T040`.
2. Integrar algoritmo en `WebTunerEngine` y `MobileFfiTunerEngine`.
3. Unificar tabla de rangos por preset y su uso en ambos engines.
4. Agregar pruebas de comportamiento temporal, anti-flicker y respuesta rapida ante salto real de nota.
5. Ajustar parametros para balance entre fluidez y respuesta.

## Evidencia de cierre
- Implementacion aplicada en:
  - `lib/data/engines/common/pitch_emission_gate.dart`
  - `lib/data/engines/common/pitch_stabilizer.dart`
  - `lib/data/engines/common/pitch_stabilization_profile.dart`
  - `lib/data/engines/web/web_tuner_engine.dart`
  - `lib/data/engines/mobile/mobile_ffi_tuner_engine.dart`
  - `lib/presentation/screens/tuner_screen.dart`
  - `test/data/engines/common/pitch_emission_gate_test.dart`
  - `test/data/engines/web/web_tuner_engine_test.dart`
  - `test/presentation/screens/tuner_screen_test.dart`
- Cambios tecnicos clave:
  - Se extrajo una politica comun de emision en `PitchEmissionGate` para Web y movil.
  - El pipeline ahora puede emitir antes del intervalo base cuando hay cambio real de nota/cuerda, salto grande de cents o transicion de/silencio.
  - Se redujo el lag del estabilizador ajustando `alpha` base, respuesta por delta y perfiles por preset.
  - Se redujo el suavizado extra de la barra de cents en UI para evitar retraso visual acumulado.
  - La estabilizacion temporal sigue siendo comun entre engines y mantiene la histeresis existente.
- Validaciones ejecutadas:
  - `flutter test test\\data\\engines\\common\\pitch_emission_gate_test.dart test\\data\\engines\\common\\pitch_reliability_gate_test.dart test\\data\\engines\\common\\pitch_stabilizer_test.dart test\\data\\engines\\common\\simple_pitch_detector_test.dart test\\data\\engines\\web\\web_tuner_engine_test.dart test\\presentation\\screens\\tuner_screen_test.dart` (ok)
  - `flutter test test\\presentation\\screens\\tuner_screen_test.dart` (ok)
- Alcance de plataforma:
  - No hubo cambios en `rust/engine`, por lo que no fue necesario ejecutar `cargo test` en esta task.
