# T037 - Captura raw y rechazo tonal de ruido no instrumental

## Estado
- todo

## Prioridad
- P0

## Epic
- E04, E05

## Dependencias
- T022, T023, T025, T028

## Objetivo
Reducir falsos positivos y locks espurios del afinador frente a `voz`, aire, ventilador y ruido sobrante, alineando primero la captura de audio por plataforma y despues el criterio comun de deteccion fiable.

## Entradas
- `lib/data/audio/recorder_audio_frame_source.dart`
- `lib/data/audio/audio_capture_profile.dart`
- `lib/data/engines/mobile/mobile_ffi_tuner_engine.dart`
- `lib/data/engines/web/web_tuner_engine.dart`
- `lib/data/engines/common/simple_pitch_detector.dart`
- `rust/engine/src/detector.rs`
- `rust/engine/src/smoothing.rs`
- `specs/quality/pitch-accuracy-protocol.md`
- `specs/quality/noise-rejection-protocol.md`

## Alcance
- Configurar captura de audio con el minimo procesado posible por plataforma cuando sea viable:
  - Android: priorizar fuente `UNPROCESSED` y definir fallback explicito.
  - iOS: usar modo de sesion orientado a medicion.
  - Web: solicitar y registrar `echoCancellation`, `autoGainControl` y `noiseSuppression`.
- Introducir una decision comun de `tono util` frente a `ruido/no instrumental`, separada del smoothing visual.
- Endurecer `confidence` para que no dependa solo de RMS + pitch bruto.
- Restringir mejor los candidatos validos por preset/instrumento para reducir detecciones humanas fuera de contexto.
- Agregar pruebas y fixtures de regresion para silencio, `voz`, aire, hum continuo y cuerda real/armonicos.
- Mantener intactos los contratos de dominio (`PitchSample`, `TunerSettings`, `TunerEngine`) y la firma FFI publica.

## Fuera de alcance
- Rediseno de UI.
- Clasificacion ML compleja de fuentes de audio.
- Cambio de contratos BLoC o FFI.
- Ajuste fino del suavizado temporal del medidor mas alla de lo necesario para exponer una senal fiable a `T029`.

## Entregables
- Configuracion de captura por plataforma documentada e implementable.
- Criterio comun de `tono fiable` integrado en engines Rust/Dart donde aplique.
- Protocolo de validacion de ruido no instrumental ejecutable en `specs/quality/noise-rejection-protocol.md`.
- Tests y fixtures de regresion para falsos positivos y no-regresion de notas reales.

## Criterios de aceptacion
- En `guitar_standard`, `voz`, aire y ventilador no producen una lectura estable confiable durante >= 300 ms.
- No hay transiciones espurias a `InTune` en escenarios no instrumentales del protocolo oficial.
- Una cuerda real limpia sigue convergiendo con latencia compatible con MVP.
- No se degrada la precision objetivo definida en `specs/quality/pitch-accuracy-protocol.md`.
- `flutter test` y `cargo test` quedan en verde para los modulos impactados.

## Riesgos
- Algunos dispositivos pueden ignorar parte de la configuracion raw/noise suppression.
- Un filtro demasiado agresivo puede penalizar notas debiles o ataques suaves.
- El comportamiento de Web puede variar por navegador y permisos reales del track.

## Plan de implementacion
1. Medir baseline actual en escenarios no instrumentales y documentar sintomas.
2. Ajustar captura por plataforma para minimizar procesado no deseado y registrar flags efectivos.
3. Definir criterio comun de `tono fiable` (energia + periodicidad/claridad + rechazo de candidatos espurios).
4. Integrar el criterio en Rust y Dart fallback sin romper contratos.
5. Agregar regresiones automatizadas y protocolo de rechazo de ruido.
6. Recalibrar presets y rangos para balance entre rechazo de ruido y respuesta real de instrumento.

## Evidencia de cierre
- Pendiente.
