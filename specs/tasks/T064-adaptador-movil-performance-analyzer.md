# T064 - Adaptador movil del PerformanceAnalyzer

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T063, T022

## Objetivo
Implementar en data el puerto `PerformanceAnalyzer` para Android/iOS usando captura PCM y el nuevo ABI.

## Entradas
- T063
- `lib/data/audio/`
- `specs/learning/domain-contracts.md`

## Alcance
- Ownership de captura y handle.
- Mapeo target/observaciones/errores.
- Stream compacto y broadcast segun contrato.
- Start/stop/setTarget idempotentes.
- Cancelacion y recuperacion por lifecycle.

## Fuera de alcance
- Web, evaluacion de acierto, BLoC o painter.

## Criterios de aceptación
- Data implementa dominio sin importar presentation.
- Ningun buffer/puntero escapa del adaptador.
- Stop libera captura, suscripciones y handle incluso tras error.
- Tests de conformidad y lifecycle en verde.

## Evidencia de cierre
- Inicio autorizado con T022 aun `todo`: existe el puerto `AudioFrameSource` y
  la implementacion `RecorderAudioFrameSource` reutilizable, por lo que el
  adaptador puede implementarse y probarse con fakes. La captura fisica en
  Android/iOS y su evidencia de dispositivo siguen perteneciendo a T022.
- Implementado `MobileFfiPerformanceAnalyzer` en Data: posee suscripcion de PCM,
  handle Rust y lifecycle serializado; el stream de observaciones es broadcast
  y no expone buffers, structs ni punteros FFI.
- `DartFfiPerformanceBindings` materializa exactamente los structs ABI v1,
  copia PCM a memoria nativa solo durante cada llamada y libera config, target y
  frame mediante `finally`. Carga `.so` en Android y el proceso en iOS.
- Mapeados targets nota/acorde (pitch classes ordenadas), resultados none/nota/
  acorde y los 12 valores C..B a entidades validadas de dominio. El adaptador no
  contiene umbrales ni decide acierto/fallo.
- Start repetido con los mismos settings, setTarget repetido y stop repetido son
  idempotentes. Cambio de settings reinicia de forma controlada; stop/restart no
  duplica suscripciones ni handles.
- Fallos de init, target, frame, captura o dispose se traducen a
  `LessonException`; permisos usan `audioPermissionDenied`. Toda ruta intenta
  cancelar suscripcion, detener captura y liberar handle, conservando el error
  original.
- `mobile_ffi_performance_analyzer_test.dart`: 9 tests pasan para nota/acorde,
  none, orden C..B, lifecycle, reinicio, ausencia de libreria y rollback tras
  fallos de captura/target/frame/dispose.
- El test de arquitectura existente recorre `lib/data/learning` y confirma que
  Data no importa Presentation ni App.
- `dart format lib/data/learning/performance test/data/learning/performance` ->
  limpio.
- `flutter analyze --no-fatal-infos` -> exit 0; 29 infos preexistentes, ninguno
  en T064.
- `flutter test` -> 182 passed, 1 skip preexistente.
- `cargo test --all-targets` -> 33 passed; 1 ignored correspondiente al corpus
  real aplazado de T062.
- `git diff --check` -> limpio (solo avisos LF/CRLF informativos existentes).
- Capas: cambios solo en Data, tests y specs; Domain, Presentation, App, Rust,
  `TunerEngine` y los modos existentes permanecen sin cambios en T064.
- Cierre autorizado por el propietario con T022 aplazada: la implementacion y
  todos los criterios de T064 estan completos. T022 permanece `todo`; los fakes
  de esta task no sustituyen su validacion fisica Android/iOS y esa deuda queda
  registrada para la auditoria final.
