# T058 - Casos de uso y maquina de sesion educativa

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057

## Objetivo
Implementar UC-L00..UC-L10 y una maquina de estados determinista, pura y comprobable con repositorio/clock/analyzer fake.

## Entradas
- `specs/learning/use-cases.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Carga/preparacion/inicio/parada.
- Listado ordenado del catalogo y sus errores.
- Tick musical y bloqueo por target.
- Evaluacion de nota y acorde.
- Pausa, velocidad, repetir seccion y reentrada.
- `LessonViewportSlice` acotado y libre de conceptos de UI.
- Errores y transiciones invalidas.
- Cierre determinista de los 250 ms de feedback mediante timestamp monotonico
  de tick, sin avance de posicion.

## Fuera de alcance
- Adaptadores reales, BLoC, Flutter y XML.

## Criterios de aceptación
- Matriz de estados cubierta con tests unitarios.
- UC-L00 valida catalogos vacios, duplicados, desordenados y fallos sin filtrar detalles de data.
- Observaciones antiguas o ataques consumidos no desbloquean.
- Dos notas iguales exigen ataques distintos; ties no.
- Reentrada conserva resultado y no reevalua el target acertado.
- Tests usan tiempo virtual y no contienen esperas reales.

## Evidencia de cierre
- Implementados UC-L00..UC-L10 en `lib/domain/learning/lesson_use_cases.dart`
  con modelos inmutables de sesion/resultado en `lesson_session.dart`.
- `ListLessonsUseCase` valida vacio, orden estricto, IDs/indices unicos y traduce
  fallos tecnicos sin filtrar detalles del catalogo; `LoadLessonUseCase` conserva
  errores tipados y nunca devuelve charts parciales.
- `LessonSessionController` cubre cuenta de un compas, bloqueo exacto, notas
  estables, acordes por ventana/maximos cromaticos, ataques consumidos, feedback
  virtual de 250 ms, reentrada, velocidad, pausa, repeticion y parada idempotente.
- La limpieza de UC-L09 intenta clock, target y analyzer de forma best-effort;
  permiso denegado y fallos de clock quedan como errores de dominio recuperables.
- `GetLessonViewportSliceUseCase` filtra solo los eventos solapados con la ventana
  y devuelve una coleccion inmutable sin tipos de UI.
- Clarificado el contrato en E08 y `use-cases.md`: cambio de velocidad durante
  `countIn` y cierre del feedback por timestamp monotonico sin avance musical.
- Tests con fakes y tiempo virtual, sin `Future.delayed` ni esperas reales:
  `flutter test test/domain/learning` -> 48 passed.
- Suite completa: `flutter test` -> 150 passed, 1 skip preexistente del harness
  multiplataforma de `TunerEngine`.
- `flutter analyze --no-fatal-infos` -> exit 0; 29 infos preexistentes y ninguno
  introducido por T058.
- `dart format lib/domain/learning test/domain/learning` -> limpio.
- `git diff --check` -> limpio.
- Test de arquitectura confirma que Domain no importa Flutter, data, XML, FFI,
  plugins, presentation ni app. Data, Presentation, App y Rust no se tocaron;
  `TunerEngine` y `MetronomeEngine` permanecen sin cambios.
