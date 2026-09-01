# T061 - Catalogo y contenido inicial de lecciones

## Estado
- done

## Prioridad
- P1

## Epic
- E08

## Dependencias
- T060

## Objetivo
Crear el catalogo local y la primera clase MusicXML propia para validar el recorrido educativo nota a nota sin audio.

## Entradas
- `specs/epics/E08-aprendizaje-guitarra-musicxml.md`
- `specs/learning/musicxml-profile.md`

## Alcance
- Clase `Pentatonica menor de La - Posicion 1`.
- Recorrido ascendente y descendente de 23 negras en 4/4 a 70 BPM.
- Afinacion estandar, posiciones 5 y 8/7 de la primera posicion y un silencio final.
- Metadata local para UC-L00, documento para UC-L01 y tests de carga.

## Fuera de alcance
- Canciones, acordes, red, progreso, bloqueos, editor de lecciones o audio real.

## Criterios de aceptación
- Todo contenido es propio y parsea sin diagnosticos no esperados.
- Genera 23 `LessonNoteEvent`, `totalTicks = 23040` y ningun acorde o diagnostico.
- Pitch, cuerda y traste son coherentes en todas las notas.
- La clase define titulo, subtitulo, orden, duracion estimada y tipo ejercicio.
- El catalogo depende del puerto de dominio y no filtra rutas a UI.

## Evidencia de cierre
- Implementado `AssetLessonCatalog` en Data como adaptador de `LessonCatalog`,
  con `AssetBundle` inyectado y asociacion privada entre el ID de dominio y el
  asset MusicXML.
- Metadata normativa publicada: ID `pentatonic-a-minor-position-1`, titulo
  `Pentatonica menor de La`, subtitulo `Primera posicion · nota a nota`, indice
  0, duracion estimada 3 y tipo `exercise`; ninguna ruta aparece en
  `LessonSummary`.
- El fixture propio existente se declara como asset en `pubspec.yaml` y se carga
  como `LessonDocument` defensivo. ID desconocido produce `lessonNotFound` y un
  fallo del bundle produce `lessonCatalogUnavailable`.
- Integracion verificada mediante `ListLessonsUseCase`, `LoadLessonUseCase` y
  `MusicXmlLessonChartDecoder`: 23 `LessonNoteEvent`, ningun acorde,
  `totalTicks = 23040` y cero diagnosticos de importacion. Las invariantes del
  chart validan pitch, cuerda y traste para todas las notas.
- Tests nuevos cubren metadata/orden/inmutabilidad, ausencia de rutas, carga y
  decodificacion por puertos, cero diagnosticos y errores tipados.
- `dart format lib/data/learning/catalog test/data/learning/asset_lesson_catalog_test.dart`
  -> limpio.
- `flutter test test/data/learning/asset_lesson_catalog_test.dart` -> 4 pruebas
  superadas; `flutter test test/data/learning` -> 23 superadas.
- `flutter test` -> 173 pruebas superadas y 1 skip preexistente del harness de
  `TunerEngine`.
- `flutter analyze --no-fatal-infos` -> exit 0; 29 infos preexistentes fuera de
  T061, sin errores, warnings ni infos nuevas.
- `git diff --check` y busqueda de whitespace en archivos nuevos -> limpios.
- Arquitectura preservada: Domain, Presentation, App, Rust/FFI y contratos
  protegidos no se modificaron; Data depende del puerto de dominio y del bundle
  de plataforma, sin importar Presentation/App/XML.
