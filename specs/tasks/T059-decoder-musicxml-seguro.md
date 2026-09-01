# T059 - Decoder MusicXML seguro y seleccion de tablatura

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T057

## Objetivo
Implementar el adaptador MusicXML hasta una representacion interna de data segura, seleccionando parte/staff TAB y rechazando entradas fuera del perfil.

## Entradas
- `specs/learning/musicxml-profile.md`
- `docs/partituras/prueba-tablatura.xml`

## Alcance
- Parseo sin DTD, entidades externas ni red.
- Limites de tamaño y nodos.
- Versiones `score-partwise` admitidas.
- Seleccion por `partId` o descubrimiento TAB.
- Afinacion, capo, transposicion, pitch, string/fret y elementos temporales.
- DTOs privados de data y errores tipados.

## Fuera de alcance
- Expansion de navegacion, entidades finales, DSP o UI.

## Criterios de aceptación
- Ningun tipo XML cruza fuera de data.
- No se hardcodean `P1`, staff 2 o voice 5.
- XML malicioso/externo se rechaza sin acceso de red.
- Pitch/string/fret inconsistentes fallan de forma tipada.
- Fixtures minimos cubren cada rama de parseo.

## Evidencia de cierre
- Implementado `MusicXmlDocumentDecoder` en `lib/data/learning/musicxml/` con
  decodificacion UTF-8 estricta, limite productivo de 10 MiB y 200.000 elementos,
  versiones `score-partwise` 2.0/3.0/3.1/4.0 y traduccion de fallos a
  `LessonException` tipada.
- La declaracion externa oficial de MusicXML presente en el fixture real se
  elimina antes de parsear sin resolverla ni acceder a red; subconjuntos DTD,
  entidades, declaraciones externas desconocidas y XML mal formado se rechazan.
- Seleccion implementada por `partId` o descubrimiento de la primera parte con
  clave TAB y posicion tecnica; part, staff y voice no se hardcodean.
- DTOs inmutables propiedad de Data conservan afinacion, capo, transposicion,
  pitch, string/fret, divisions, meter, tempo, backup/forward, chord, rest,
  grace, ties, tuplets, tecnicas, repeats y endings. Ningun `XmlNode` cruza el
  adaptador ni aparece fuera de Data.
- Pitch escrito mas transposicion se contrasta contra afinacion vigente, capo y
  traste; afinacion invalida, posicion inconsistente, navegacion no soportada y
  seleccion fallida conservan sus codigos de dominio.
- Fixtures minimos cubren seleccion dinamica y pitch inconsistente. El fixture
  real decodifica `P1`, descubre staff TAB 2, conserva 82 compases y obtiene 454
  ataques con pitch (455 elementos nota al incluir el miembro `chord`).
- Dependencia agregada: `xml: ^6.4.0`, resuelta por Pub como 6.6.1; el parser no
  aplica DTD y la politica previa del adaptador impide entidades/contenido externo.
- `flutter test test/data/learning` -> 13 pruebas superadas.
- `flutter test` -> 163 pruebas superadas y 1 skip preexistente del harness
  multiplataforma de `TunerEngine`.
- `flutter analyze --no-fatal-infos` -> exit 0; 29 infos preexistentes fuera de
  T059, sin errores ni warnings.
- `dart format lib/data/learning test/data/learning` y `git diff --check` ->
  limpios.
- Test de arquitectura confirma que tipos del parser XML no salen de Data y que
  el adaptador no importa Presentation/App. Domain, Presentation, App, Rust/FFI,
  `TunerEngine` y `MetronomeEngine` no se modificaron por T059.
