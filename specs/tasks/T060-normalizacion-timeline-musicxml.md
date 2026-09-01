# T060 - Normalizacion temporal y navegacion MusicXML

## Estado
- done

## Prioridad
- P0

## Epic
- E08

## Dependencias
- T059

## Objetivo
Convertir el DTO MusicXML a `LessonChart` canonico de 960 PPQ, sin duplicar pentagramas y con navegacion lineal determinista.

## Entradas
- `specs/learning/musicxml-profile.md`
- `specs/learning/domain-contracts.md`

## Alcance
- Cursor por voz con `backup`, `forward` y `chord`.
- Conversion exacta de divisions/tuplets.
- Fusion de ties y agrupacion de acordes.
- Grace notes opcionales.
- Repeats y endings 1/2.
- Tempo/meter maps, secciones, IDs de instancia y totalTicks.
- Normalizacion acotada de medidas irregulares del fixture real.

## Fuera de alcance
- D.S./Coda, audio o evaluacion musical.

## Criterios de aceptación
- Salida cumple todas las invariantes de T057.
- Repeticiones se expanden sin IDs duplicados.
- Tablatura estandar duplicada no crea eventos dobles.
- Resolucion no exacta y navegacion no soportada producen error.
- El fixture real alcanza los resultados normativos documentados.

## Evidencia de cierre
- Implementado `MusicXmlLessonChartDecoder` como adaptador de
  `LessonChartDecoder`: compone el decoder seguro de T059 con
  `MusicXmlTimelineNormalizer` y solo expone `LessonChart` al puerto de dominio.
- El normalizador conserva cursor temporal con `backup`, `forward`, voz y
  `chord`; las notas del pentagrama estandar solo aportan avance interno y no
  crean eventos educativos duplicados.
- Conversion exacta a `lessonTicksPerQuarter = 960`; ritmos no representables
  fallan con `unsupportedRhythmResolution`. Desviaciones de medida de hasta 120
  ticks se alinean al limite nominal y diferencias mayores fallan con
  `invalidLessonDocument`.
- Ties se fusionan, ataques simultaneos se agrupan en `LessonChordEvent`, grace
  notes se omiten, tecnicas se mapean a dominio y afinacion/capo se validan antes
  de construir el chart.
- Repeats y endings 1/2 se expanden a una secuencia lineal con IDs de instancia
  unicos; repeats anidados/solapados y navegacion incompleta fallan con
  `unsupportedNavigation`.
- Tempo/meter maps, seccion unica, `totalTicks` y colecciones inmutables se
  construyen mediante las entidades validadas de T057.
- Diagnosticos internos de Data registran `graceNoteIgnored` y
  `measureDurationNormalized` sin alterar el puerto ni filtrar DTOs/XML.
- Corregida una doble resta aritmetica en
  `specs/learning/musicxml-profile.md`: el fixture contiene 455 elementos de
  nota, 5 grace, 1 miembro chord y 12 tie stop, por lo que produce 437 eventos
  antes de navegacion y 874 despues (`455 - 5 - 1 - 12`).
- Fixture inicial: 23 `LessonNoteEvent`, ningun acorde, `totalTicks = 23040`,
  tempo 70 y compas 4/4.
- Fixture real P1: 82 medidas fuente, 874 eventos con IDs unicos,
  `totalTicks = 620160`, tempo inicial 124, meter 2/4 -> 4/4, acordes presentes,
  5 diagnosticos grace y 3 normalizaciones de medida.
- Fixture minimo nuevo cubre pentagrama estandar duplicado, `backup`, tie +
  chord, grace, repeat y endings 1/2; tambien se cubren resolucion no exacta,
  desviacion mayor de medida y repeat anidado.
- `dart format lib/data/learning/musicxml test/data/learning` -> limpio.
- `flutter test test/data/learning` -> 19 pruebas superadas.
- `flutter test` -> 169 pruebas superadas y 1 skip preexistente del harness
  multiplataforma de `TunerEngine`.
- `flutter analyze --no-fatal-infos` -> exit 0; 29 infos preexistentes fuera de
  T060, sin errores ni warnings.
- `git diff --check` y busqueda de whitespace en archivos nuevos -> limpios.
- Arquitectura preservada: Domain, Presentation, App, Rust/FFI,
  `TunerEngine` y `MetronomeEngine` no se modificaron por T060; los DTOs,
  diagnosticos y parser permanecen en Data.
