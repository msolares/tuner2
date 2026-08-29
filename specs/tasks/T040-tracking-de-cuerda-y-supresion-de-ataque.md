# T040 - Tracking de cuerda y supresion de ataque

## Estado
- done

## Prioridad
- P0

## Epic
- E02, E03, E04, E05

## Dependencias
- T037, T038, T039

## Objetivo
Eliminar los saltos espurios de nota durante la afinacion real introduciendo seguimiento temporal de cuerda/nota, bloqueo de cuerda probable y tratamiento especifico del ataque de la cuerda.

## Entradas
- `rust/engine/src/smoothing.rs`
- `rust/engine/src/ffi.rs`
- `lib/data/engines/mobile/mobile_ffi_tuner_engine.dart`
- `lib/data/engines/web/web_tuner_engine.dart`
- `lib/data/engines/common/pitch_reliability_gate.dart`
- `lib/data/engines/common/pitch_stabilizer.dart`
- `specs/quality/pitch-accuracy-protocol.md`
- `specs/quality/noise-rejection-protocol.md`

## Alcance
- Introducir una fase de clasificacion de cuerda probable por preset antes de estabilizacion fina.
- Implementar `lock` temporal de cuerda con histeresis de desbloqueo y confirmacion corta de cambio real.
- Penalizar o ignorar el transitorio inicial del ataque para evitar lecturas falsas al pulsar.
- Diferenciar cambio real de cuerda frente a microdesviacion de afinacion dentro de la misma cuerda.
- Agregar pruebas de secuencias temporales para ataques, cambios reales de cuerda y notas vecinas espurias.

## Fuera de alcance
- Cambio de UI o presentacion visual.
- Clasificacion ML avanzada de fuente de audio.
- Cambio de contratos BLoC, dominio o FFI publica.

## Entregables
- Capa de tracking temporal integrada en movil y Web.
- Parametrizacion por preset para lock, unlock y tratamiento de ataque.
- Tests de regresion para secuencias temporales reales/sinteticas.

## Criterios de aceptacion
- Durante la afinacion sostenida de una cuerda no aparecen saltos frecuentes a otra nota/cuerda incompatible.
- Un cambio real de cuerda hace lock en latencia compatible con el protocolo de precision.
- El ataque inicial deja de disparar lecturas equivocadas de nota en los casos cubiertos.
- No se degrada el rechazo de `voz`, aire y ventilador definido en `T037`.
- `flutter test` y `cargo test` quedan en verde para los modulos impactados.

## Riesgos
- Un lock demasiado rigido puede hacer que el afinador parezca lento al cambiar de cuerda.
- Parametros por preset insuficientes pueden dejar huecos entre guitarras, bajos y otros instrumentos.

## Plan de implementacion
1. Definir modelo temporal de `string lock` y reglas de desbloqueo.
2. Integrar penalizacion/supresion de ataque antes de exponer la lectura estable.
3. Conectar el tracking con las salidas de `T038` y `T039`.
4. Agregar pruebas de secuencia temporal y casos reales conocidos.
5. Ajustar parametros para equilibrio entre claridad y respuesta.

## Evidencia de cierre
- Implementacion aplicada en:
  - `lib/data/engines/common/pitch_reliability_profile.dart`
  - `lib/data/engines/common/pitch_reliability_gate.dart`
  - `lib/data/engines/common/pitch_stabilizer.dart`
  - `test/data/engines/common/pitch_reliability_gate_test.dart`
  - `test/data/engines/web/web_tuner_engine_test.dart`
- Cambios tecnicos clave:
  - El gate comun ahora mantiene `string lock` por preset usando el target mas cercano del instrumento.
  - Se añade confirmacion separada para lock inicial y cambio de cuerda sostenido.
  - Se evita filtrar una cuerda incorrecta puntual mientras hay lock activo, devolviendo silencio temporal para que el estabilizador sostenga la lectura previa.
  - Se normaliza `note/cents` al target bloqueado para reducir entradas espurias de nota vecina.
  - Se introduce supresion de ataque con ventana de estabilidad por cents y liberacion del lock tras varios frames silenciosos.
  - El `fast-path` del estabilizador ahora responde tambien a cambio real de nota/cuerda y salto relativo de `hz`, no solo a delta de cents.
- Validacion ejecutada:
  - `dart format lib\\data\\engines\\common\\pitch_reliability_profile.dart lib\\data\\engines\\common\\pitch_reliability_gate.dart test\\data\\engines\\common\\pitch_reliability_gate_test.dart test\\data\\engines\\web\\web_tuner_engine_test.dart`
  - `flutter test test\\data\\engines\\common\\pitch_reliability_gate_test.dart test\\data\\engines\\common\\pitch_stabilizer_test.dart test\\data\\engines\\common\\simple_pitch_detector_test.dart test\\data\\engines\\web\\web_tuner_engine_test.dart` (ok, 23 tests en verde)
- Alcance de plataforma:
  - No hubo cambios en `rust/engine`, por lo que no fue necesario ejecutar `cargo test` en esta task.
