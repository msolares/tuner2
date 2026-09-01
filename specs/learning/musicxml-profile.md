# Perfil MusicXML admitido para lecciones

## Fuente de referencia

- Fixture real: `docs/partituras/prueba-tablatura.xml`.
- Fixture educativo inicial: `docs/partituras/pentatonica-menor-la-posicion-1.musicxml`.
- Exportador observado: Guitar Pro 8.1.1, MusicXML 2.0 `score-partwise`.

El fixture real es una prueba de compatibilidad, no un archivo que deba cargarse entero en cada test unitario.

## Entrada admitida E08

- MusicXML `score-partwise` versiones 2.0, 3.0, 3.1 y 4.0.
- XML UTF-8, maximo 10 MiB y 200.000 nodos.
- DTD, entidades externas y acceso de red deshabilitados.
- Una unica parte de guitarra seleccionada mediante `partId` o, por defecto, la primera parte que contenga clave `TAB` y notas con `technical/string` + `technical/fret`.
- Exactamente seis cuerdas y trastes `0..24`.

## Elementos soportados

### Estructura

- `part-list`, `score-part`, `part`, `measure`.
- `attributes/divisions`, `key`, `time`, `staves`, `clef`.
- `staff-details/staff-lines`, `staff-tuning`, `capo`.
- `transpose`, incluido `octave-change` de guitarra.

### Tiempo

- `direction/sound@tempo`.
- `direction-type/metronome`.
- Cambios de tempo y compas en limites de posicion validos.
- `duration`, `backup`, `forward`, `voice`, `staff`.
- `time-modification` y `tuplet` cuando la duracion es representable en 960 PPQ.
- `chord`, `rest`, `grace`, `tie` y `tied`.

### Tablatura y tecnica

- `pitch/step`, `alter`, `octave`.
- `technical/string`, `technical/fret`.
- `hammer-on`, `slide`, `bend`, `harmonic`, `up-bow`, `down-bow` como metadatos visuales.
- `bend-alter`, `pre-bend` y `release` se conservan como extension de tecnica, pero E08 no los puntua.

### Navegacion

- Repeticion `forward/backward` con `times >= 2`.
- Primera y segunda terminacion mediante `ending number="1|2"`.
- Un nivel de repeticion; las repeticiones anidadas producen `unsupportedNavigation`.

## Elementos fuera de alcance E08

- `score-timewise`.
- D.C., D.S., Segno, Coda y saltos arbitrarios.
- Mas de dos terminaciones.
- Scordatura de mas o menos de seis cuerdas.
- Microtonalidad no expresable como semitonos para la evaluacion.
- Acordes que no sean power chord o triada mayor/menor objetivo.
- Evaluacion de letra, dinamica, palm mute, vibrato o articulaciones ornamentales.
- Identificacion de una grabacion de audio desde el XML.

Un elemento fuera de alcance que cambie el significado temporal o tonal produce error tipado. Un elemento puramente grafico desconocido se ignora y registra en diagnostico.

## Algoritmo normativo de importacion

1. Parsear de forma segura sin resolver DTD ni entidades.
2. Seleccionar la parte y localizar el staff TAB por su clef/presencia tecnica; no hardcodear `staff=2` o `voice=5`.
3. Leer afinacion/capo/transposicion vigentes.
4. Recorrer cada medida con cursor por voz respetando `backup`, `forward` y `chord`.
5. Convertir `duration/divisions` a 960 PPQ de forma exacta.
6. Excluir la duplicacion de partitura estandar.
7. Validar `pitch == openMidi + capo + fret`; aplicar transposicion donde corresponda.
8. Agrupar notas con `chord` en un evento simultaneo.
9. Fusionar segmentos ligados en un solo evento.
10. Ignorar grace notes en E08 y registrar diagnostico `graceNoteIgnored`; no generan evento visual ni obligatorio.
11. Expandir repeticiones y terminaciones a una secuencia lineal con IDs de instancia unicos.
12. Generar tempo/meter maps y `totalTicks`.
13. Validar el `LessonChart` completo o fallar sin resultado parcial.

## Politica ante compases irregulares del exportador

El fixture real contiene tres medidas cuya suma literal queda 1/8 de negra por debajo de la metrica alrededor de grace notes.

- El importer conserva el cursor literal de eventos dentro de la medida.
- El siguiente compas comienza en el limite nominal definido por el meter cuando la diferencia absoluta es `<= 120 ticks` (1/8 de negra).
- Se registra diagnostico `measureDurationNormalized`.
- Una discrepancia mayor produce `invalidLessonDocument`.

Esto evita deriva acumulada sin inventar duracion para una grace note.

## Resultado esperado del fixture real

Para la parte `P1`:

- 82 compases.
- Afinacion E2 A2 D3 G3 B3 E4.
- Tempo 124 BPM.
- Compas 1 en 2/4 y resto en 4/4.
- Repeticion 2..81 dos veces.
- 455 elementos de nota TAB con pitch y cuerda/traste coherentes: 454 ataques
  (uno de los elementos es miembro `chord`).
- 102 silencios, 5 grace notes y al menos un acorde simultaneo.
- Trastes 0..22.
- 437 eventos normalizados antes de navegacion y 874 eventos tras expandir la repeticion.
- `totalTicks = 620160` despues de normalizar limites de compas y expandir navegacion.

Estos valores son obligatorios para el perfil E08: de los 455 elementos, 5 grace
notes se ignoran, 1 miembro `chord` se agrupa con su ataque simultaneo y 12
segmentos `tie stop` se fusionan (`455 - 5 - 1 - 12 = 437`).

## Resultado esperado de la primera clase

Para `pentatonica-menor-la-posicion-1.musicxml`, parte `P1`:

- 6 compases en 4/4, `divisions = 1` y tempo 70 BPM.
- Afinacion estandar E2 A2 D3 G3 B3 E4.
- 23 negras requeridas y un silencio final de negra.
- Ascenso A2..C5 y descenso A4..A2, sin repetir la nota superior.
- Trastes 5, 7 y 8; ninguna cuerda abierta.
- Sin acordes, ligaduras, grace notes, repeticiones ni audio.
- 23 `LessonNoteEvent`, ningun diagnostico y `totalTicks = 23040`.

Entrada exacta del catalogo local:

- `id`: `pentatonic-a-minor-position-1`.
- `title`: `Pentatonica menor de La`.
- `subtitle`: `Primera posicion · nota a nota`.
- `sequenceIndex`: `0`.
- `estimatedMinutes`: `3`.
- `kind`: `exercise`.

La asociacion entre ese ID y el path del fixture pertenece al adaptador local de data y no cruza su puerto.
