# T039 - Paridad Web del detector profesional

## Estado
- done

## Prioridad
- P0

## Epic
- E03, E04

## Dependencias
- T025, T037, T038

## Objetivo
Llevar el motor Web/Dart a una paridad funcional real con el detector Rust profesional para evitar diferencias de nota, graves y confianza entre plataformas.

## Entradas
- `lib/data/engines/common/simple_pitch_detector.dart`
- `lib/data/engines/common/analysis_window_buffer.dart`
- `lib/data/engines/web/web_tuner_engine.dart`
- `test/data/engines/common/simple_pitch_detector_test.dart`
- `test/data/engines/web/web_tuner_engine_test.dart`
- `specs/quality/web-compat-matrix.md`

## Alcance
- Portar o aproximar de forma equivalente la logica del detector robusto definida en `T038`.
- Igualar el tratamiento de graves (`E2`, `A2`), candidatos fuertes y criterio de confianza util entre Web y movil.
- Consolidar el uso de ventana adaptativa/buffer de analisis en Web.
- Agregar pruebas de no regresion para tonos reales, armonicos ricos, ruido y casos de graves.

## Fuera de alcance
- Bloqueo temporal de cuerda y supresion de ataque (se cubre en `T040`).
- Cambio del contrato `TunerEngine`.
- Ajustes visuales del medidor.

## Entregables
- Detector Dart actualizado con comportamiento equivalente al motor Rust en escenarios cubiertos.
- Tests Dart/Web de regresion para graves y casos armonicos.
- Notas de compatibilidad actualizadas si algun navegador requiere ajuste especial.

## Criterios de aceptacion
- Web resuelve `E2` y `A2` con comportamiento equivalente al motor Rust dentro de la tolerancia definida en tests.
- Los casos de armonicos ricos y fuera de rango no divergen materialmente entre Web y movil.
- `flutter test` queda en verde para los modulos impactados.

## Riesgos
- El navegador puede penalizar CPU/latencia con ventanas largas si no se controla el buffer.
- La equivalencia exacta entre Rust y Dart puede requerir pequenas diferencias numericas.

## Plan de implementacion
1. Usar `T038` como referencia funcional del detector objetivo.
2. Portar candidatos, criterio de claridad y ventana adaptativa al detector Dart.
3. Integrar el nuevo detector en `WebTunerEngine`.
4. Agregar pruebas para graves, armonicos y ruido no instrumental.
5. Ajustar la tolerancia de paridad segun limitaciones numericas razonables.

## Evidencia de cierre
- Implementacion aplicada en:
  - `lib/data/engines/common/simple_pitch_detector.dart`
  - `test/data/engines/common/simple_pitch_detector_test.dart`
  - `test/data/engines/web/web_tuner_engine_test.dart`
- Cambios tecnicos clave:
  - Port de la logica del detector Rust a Dart usando `CMNDF` multicandidato (familia YIN).
  - Pasada adicional a media resolucion para reforzar graves en `E2` y `A2`.
  - Seleccion de candidato basada en `clarity`, separacion entre candidatos y coherencia de `zero crossing`.
  - Rechazo de pliegues fuera de rango y ajuste de `confidence` en Dart alineado con la nueva salida tonal.
- Pruebas Dart/Web agregadas o actualizadas:
  - `SimplePitchDetector`: rango, `G3` armonico rico, `E2` armonico rico, `A2` armonico rico y ruido broadband.
  - `WebTunerEngine`: flujo con detector real para `E2` armonico rico y no regresion de suavizado/rangos.
- Validacion ejecutada:
  - `flutter test test\\data\\engines\\common\\simple_pitch_detector_test.dart test\\data\\engines\\web\\web_tuner_engine_test.dart` (ok, 10 tests en verde)
