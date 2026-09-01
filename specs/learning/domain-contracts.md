# Contratos de dominio del modo educativo

## Estado y alcance

Contrato cerrado para E08. Solo puede cambiar mediante actualizacion previa del epic, tasks afectadas y `AGENTS.md` si altera una regla global.

E08 cubre ejercicios MusicXML, notas, acordes, velocidad educativa, espera hasta acierto y reentrada sin audio real obligatorio. E09 añade audio real sin cambiar las entidades centrales de E08.

## Unidad temporal canonica

- `ticksPerQuarter = 960`.
- Todos los inicios y duraciones persistidos son enteros no negativos.
- El adaptador MusicXML convierte `divisions` a ticks exactos.
- Una duracion no representable exactamente en 960 PPQ produce `unsupportedRhythmResolution`.
- Los milisegundos se derivan del mapa de tempo; nunca son autoridad en `LessonChart`.

## Entidades

```dart
const int lessonTicksPerQuarter = 960;

final class LessonId {
  final String value;
}

final class FretPosition {
  final int stringNumber; // 1 aguda .. 6 grave
  final int fret;         // 0 .. 24 en E08
}

final class GuitarStringTuning {
  final int stringNumber;
  final int openMidi;
}

final class GuitarTuningSpec {
  final List<GuitarStringTuning> strings; // exactamente 6 en E08
}

final class TempoPoint {
  final int tick;
  final double bpm; // 20.0 .. 300.0
}

final class MeterPoint {
  final int tick;
  final int numerator;   // 1 .. 32
  final int denominator; // 1, 2, 4, 8, 16 o 32
}

enum GuitarTechnique {
  hammerOn,
  slide,
  bend,
  harmonic,
  upStroke,
  downStroke,
}

sealed class LessonEvent {
  final String id;
  final int startTick;
  final int durationTicks;
  final bool required;
}

final class LessonNoteEvent extends LessonEvent {
  final FretPosition position;
  final int midi;
  final Set<GuitarTechnique> techniques;
}

final class ChordToneTarget {
  final FretPosition position;
  final int midi;
}

final class LessonChordEvent extends LessonEvent {
  final String symbol;
  final List<ChordToneTarget> tones;
  final Set<int> mutedStrings;
  final Set<GuitarTechnique> techniques;
}

final class LessonSection {
  final String id;
  final String title;
  final int startTick;
  final int endTick;
}

final class LessonChart {
  final int schemaVersion; // 1 en E08
  final LessonId id;
  final String title;
  final GuitarTuningSpec tuning;
  final List<TempoPoint> tempoMap;
  final List<MeterPoint> meterMap;
  final List<LessonSection> sections;
  final List<LessonEvent> events;
  final int totalTicks;
}
```

## Invariantes del chart

- Listas inmutables, ordenadas por tick y con IDs unicos.
- `tempoMap` y `meterMap` empiezan en tick 0.
- `totalTicks > 0` y ningun evento o seccion lo supera.
- Todo evento tiene `durationTicks > 0`; las grace notes no generan eventos obligatorios en E08.
- Una nota cumple `openMidi(string) + fret == midi`.
- Un acorde contiene entre 2 y 6 tonos y posiciones de cuerda unicas.
- `mutedStrings` contiene las cuerdas 1..6 ausentes del voicing, no se solapa con `tones` y solo sirve como instruccion visual.
- Las cuerdas silenciadas no forman parte de `requiredPitchClasses`.
- `requiredPitchClasses` se deriva como `midi % 12`, sin exigir duplicados de la misma clase.
- E08 admite acordes objetivo con 2 clases para power chords o 3 clases para triadas mayores/menores.
- Un acorde fuera de este perfil produce `unsupportedChord` durante la carga; no se degrada silenciosamente.
- Los eventos simultaneos se agrupan en un unico `LessonChordEvent`.
- Las notas ligadas se fusionan en un unico evento sostenido y no exigen un nuevo ataque.

### Construccion y rechazo

- IDs, titulos, subtitulos, simbolos y nombres de origen no pueden estar vacios ni contener solo whitespace.
- Todo MIDI esta en `0..127`; toda cuerda en `1..6`; todo traste en `0..24`.
- `GuitarTuningSpec` contiene exactamente una entrada por cuerda, ordenada 1..6 y sin duplicados.
- Ticks estructurales son enteros no negativos. Una seccion cumple `endTick > startTick`; un evento cumple `durationTicks > 0`.
- Tempo y meter tienen ticks unicos en orden ascendente y empiezan en 0. BPM es finito y esta en `20.0..300.0`.
- El denominador de meter pertenece a `{1, 2, 4, 8, 16, 32}` y el numerador a `1..32`.
- Eventos y secciones tienen IDs unicos, orden no decreciente por tick y terminan como maximo en `totalTicks`.
- `schemaVersion` solo admite `1` en E08.
- Un power chord tiene dos clases tonales separadas por cuarta/quinta justa. Una triada tiene tres clases con forma mayor `{0,4,7}` o menor `{0,3,7}` desde alguna fundamental.
- `mutedStrings` es exactamente el complemento de las cuerdas presentes en `tones` dentro de `1..6`.
- Invariantes locales de rango/formato lanzan `ArgumentError` o `RangeError`. Invariantes musicales tipadas lanzan `LessonException` con `invalidTuning`, `inconsistentPitchAndFret`, `unsupportedChord` o `sessionInvariantViolation` segun corresponda.

### Inmutabilidad, igualdad y copia

- Todas las entidades y value objects usan igualdad por valor.
- Toda lista, set, mapa o bytes recibidos se copian defensivamente y se exponen como colecciones no modificables.
- Los modelos con mas de un campo ofrecen `copyWith` y reconstruyen mediante el constructor validado.
- Los puertos no exponen DTOs, parsers ni tipos de plataforma.

## Documento y puertos de contenido

```dart
enum LessonKind {
  exercise,
  song,
}

final class LessonSummary {
  final LessonId id;
  final String title;
  final String subtitle;
  final int sequenceIndex;
  final int estimatedMinutes;
  final LessonKind kind;
}

final class LessonDocument {
  final LessonId id;
  final String sourceName;
  final List<int> bytes;
}

final class LessonImportOptions {
  final String? partId;
  final String? sectionTitle;
}

abstract interface class LessonCatalog {
  Future<List<LessonSummary>> list();
  Future<LessonDocument> getById(LessonId id);
}

abstract interface class LessonChartDecoder {
  LessonChart decode(
    LessonDocument document,
    LessonImportOptions options,
  );
}
```

Los puertos no mencionan XML. MusicXML es una implementacion de data de `LessonChartDecoder`.

Invariantes del catalogo E08:

- `list()` devuelve una lista inmutable ordenada por `sequenceIndex`, sin duplicados de `LessonId` ni indice.
- `sequenceIndex >= 0` y `estimatedMinutes > 0`.
- Todas las clases locales estan disponibles: progreso, bloqueos, estrellas, usuario y API quedan fuera de E08.
- `LessonSummary` no contiene rutas, nombres de assets, XML ni estado visual.
- `LessonDocument.sourceName` y `bytes` no estan vacios; cada byte esta en `0..255` y la lista se copia defensivamente.
- `LessonImportOptions.partId/sectionTitle`, cuando existen, no estan vacios. Su `copyWith` permite conservarlos o borrarlos explicitamente.

## Observaciones de interpretacion

```dart
sealed class PerformanceTarget {
  final String eventId;
}

final class NotePerformanceTarget extends PerformanceTarget {
  final int midi;
}

final class ChordPerformanceTarget extends PerformanceTarget {
  final Set<int> requiredPitchClasses;
}

sealed class PerformanceObservation {
  final int timestampMs;
  final int onsetSequence;
  final double confidence;
}

final class NotePerformanceObservation extends PerformanceObservation {
  final double hz;
  final int midi;
  final double cents;
}

final class ChordPerformanceObservation extends PerformanceObservation {
  final List<double> pitchClassStrengths; // 12 valores 0.0 .. 1.0
  final double onsetConfidence;
}

final class PerformanceAnalyzerSettings {
  final double a4Hz; // 415.0 .. 466.0
}

abstract interface class PerformanceAnalyzer {
  Future<void> start(PerformanceAnalyzerSettings settings);
  Future<void> setTarget(PerformanceTarget? target);
  Stream<PerformanceObservation> observations();
  Future<void> stop();
}
```

Invariantes:

- `pitchClassStrengths.length == 12` en orden C..B.
- MIDI esta en `0..127`; pitch classes en `0..11`; timestamps y `onsetSequence` son no negativos.
- Confidence, onset confidence y fortalezas cromaticas son finitas y estan en `0.0..1.0`; Hz es finito y positivo; cents es finito.
- Un target de acorde contiene 2 o 3 clases tonales unicas y cumple el mismo perfil power chord/triada del chart.
- `a4Hz` es finito y esta en `415.0..466.0`.
- El analyzer no decide `correct/incorrect`; produce evidencia.
- `setTarget` permite optimizacion dirigida, pero no altera la semantica de la observacion.
- `onsetSequence` aumenta solo ante un ataque nuevo y nunca retrocede durante una sesion.
- `start/stop` son idempotentes y no duplican streams ni recursos.
- `TunerEngine` no cambia y no implementa este contrato.

## Politica de evaluacion E08

```dart
final class LessonEvaluationPolicy {
  final double noteMinConfidence;          // default 0.65
  final double noteMaxAbsCents;            // default 25.0
  final int noteStableMs;                  // default 100
  final int chordWindowMs;                 // default 700
  final double chordMinOnsetConfidence;    // default 0.45
  final double chordMinToneStrength;       // default 0.45
  final double chordMinMeanStrength;       // default 0.60
  final int reentryTicks;                  // default 960
}
```

Todos los doubles de la politica son finitos. Confidences/strengths estan en `0.0..1.0`, `noteMaxAbsCents` en `0.0..100.0`, ventanas temporales son enteros positivos y `reentryTicks >= 0`. `LessonEvaluationPolicy.defaults` usa exactamente los valores indicados arriba y `copyWith` vuelve a validar.

La velocidad inicial de toda sesion E08 es `0.70` salvo eleccion explicita del usuario antes de comenzar.

- Una nota requiere MIDI correcto, confidence minima, cents dentro de tolerancia y estabilidad durante `noteStableMs`.
- Si dos objetivos consecutivos tienen el mismo MIDI, el segundo exige `onsetSequence` nuevo.
- Al entrar en espera solo son validas observaciones con timestamp posterior al inicio de espera y ataque no consumido.
- Un acorde acumula evidencia durante `chordWindowMs` desde un ataque valido.
- Cada clase requerida supera `chordMinToneStrength` y su media supera `chordMinMeanStrength`.
- Las clases no requeridas no invalidan por si solas E08; se registran para diagnostico. Su penalizacion pertenece a una evolucion contractual posterior.
- La posicion fisica mostrada es recomendada. E08 valida sonido, no identifica la cuerda realmente pulsada.

## Reloj de practica

```dart
final class LessonClockTick {
  final double positionTicks;
  final int monotonicTimestampMs;
}

abstract interface class LessonClock {
  Future<void> start({required int initialTick, required double speed});
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(int tick);
  Future<void> setSpeed(double speed);
  Stream<LessonClockTick> ticks();
  Future<void> stop();
}
```

- Constantes de velocidad E08: `lessonMinSpeed = 0.50`, `lessonMaxSpeed = 1.00`, `lessonSpeedStep = 0.05` y `lessonDefaultSpeed = 0.70`.
- E08 no produce audio; `LessonClock` solo gobierna tiempo musical y cuenta visual.
- El clock usa objetivos monotónicos absolutos; no acumula deltas de callbacks.
- El repaint interpola, pero nunca incrementa la posicion de dominio.
- `LessonClockTick.positionTicks` es finito y puede ser negativo solo para cuenta/reentrada transitoria; `monotonicTimestampMs >= 0`.

## Estado de sesion

```dart
enum LessonSessionStatus {
  idle,
  ready,
  countIn,
  running,
  waitingForTarget,
  validating,
  successFeedback,
  reentry,
  paused,
  completed,
  failure,
}
```

`LessonSessionState` contiene como minimo chart/section seleccionados, status, posicion, velocidad, evento objetivo, resultados por evento, intento actual y error tipado recuperable.

```dart
final class LessonViewportSlice {
  final double positionTicks;
  final int windowStartTick;
  final int windowEndTick;
  final List<LessonEvent> visibleEvents;
  final String? currentTargetId;
  final LessonSessionStatus status;
}
```

`LessonViewportSlice` es una salida de dominio sin coordenadas, colores, textos localizados ni tipos Flutter. Presentation la convierte a su propio `FretboardRenderModel`.

`LessonViewportSlice.positionTicks` es finito, `windowEndTick >= windowStartTick`, su lista es inmutable y `currentTargetId`, cuando existe, no esta vacio.

Transiciones no listadas en `use-cases.md` son invalidas y deben ignorarse o producir error de dominio tipado; nunca se inventa una transicion desde BLoC.

## Errores tipados

- `lessonNotFound`
- `lessonCatalogUnavailable`
- `invalidLessonCatalog`
- `invalidLessonDocument`
- `unsupportedMusicXmlVersion`
- `partNotFound`
- `tablatureNotFound`
- `invalidTuning`
- `unsupportedRhythmResolution`
- `unsupportedNavigation`
- `inconsistentPitchAndFret`
- `unsupportedChord`
- `performanceAnalyzerUnavailable`
- `audioPermissionDenied`
- `lessonClockFailure`
- `sessionInvariantViolation`

Los adaptadores traducen excepciones tecnicas a estos codigos antes de cruzar a dominio/presentation.
