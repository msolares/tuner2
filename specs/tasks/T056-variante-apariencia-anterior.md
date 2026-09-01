# T056 - Variante con apariencia anterior

## Estado
- done

## Prioridad
- P1

## Epic
- E01, E04, E07

## Dependencias
- T055

## Objetivo
Crear una rama independiente que conserve toda la funcionalidad actual del afinador y el metronomo, recuperando la identidad visual azul y verde anterior al rediseño vigente.

## Alcance
- Trabajar en una rama y un worktree separados sin modificar la rama de apariencia original.
- Mantener motores, contratos, BLoC, audio, presets, metronomo, localizacion ES/EN y version `1.0.5+9`.
- Recuperar fondo azul, superficies, tipografia de sistema y acentos azul/verde de la apariencia anterior.
- Recuperar la composicion anterior del afinador y adaptar a ella el selector superior de preset.
- Mantener el selector inferior eliminado y no mostrar estado ni confidence duplicados en cabecera.
- Alinear visualmente navegacion y metronomo con la paleta anterior.

## Fuera de alcance
- Cambios en deteccion de pitch o captura de audio.
- Cambios en contratos Dart o Rust FFI.
- Cambios en comportamiento del metronomo, presets o localizacion.
- Modificar o limpiar cambios de la rama original.

## Criterios de aceptacion
- La rama original conserva exactamente su working tree.
- La variante compila y mantiene la suite funcional en verde.
- El selector de preset sigue en la cabecera y ofrece los cinco presets.
- La interfaz usa la apariencia azul/verde anterior en afinador, metronomo y navegacion.
- La version visible sigue siendo `v1.0.5+9`.
- El build Web se valida en navegador sin errores de consola.

## Evidencia de cierre
- Rama creada: `codex/funcionalidad-actual-apariencia-anterior` en el worktree separado `C:\Marcos\Apps\afinador-functional-old-ui`.
- La rama de apariencia original se mantuvo activa y sin modificaciones derivadas de esta variante.
- Se traslado el estado funcional actual: motores, audio, BLoC, cinco presets, metronomo, localizacion ES/EN y version `1.0.5+9`.
- Afinador recuperado con composicion, fondo azul, superficies y acentos azul/verde de la apariencia anterior.
- Selector superior conservado con sus cinco presets, marca activa, limpieza de resultado por cancion y soporte responsive a 320 px.
- Navegacion y metronomo alineados con la misma paleta anterior, sin cambiar su comportamiento.
- `flutter analyze --no-pub --no-fatal-infos`: sin errores ni warnings; solo avisos informativos preexistentes.
- `flutter test --no-pub`: 102 tests superados y 1 test historico omitido.
- `flutter build web --no-pub`: build Web correcto y dry run Wasm superado.
- Verificacion manual en `http://127.0.0.1:7364/`: apariencia anterior visible, `v1.0.5+9` y consola sin errores.
