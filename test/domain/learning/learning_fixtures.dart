import 'package:afinador/domain/learning/learning.dart';

GuitarTuningSpec standardGuitarTuning() => GuitarTuningSpec([
      GuitarStringTuning(stringNumber: 1, openMidi: 64),
      GuitarStringTuning(stringNumber: 2, openMidi: 59),
      GuitarStringTuning(stringNumber: 3, openMidi: 55),
      GuitarStringTuning(stringNumber: 4, openMidi: 50),
      GuitarStringTuning(stringNumber: 5, openMidi: 45),
      GuitarStringTuning(stringNumber: 6, openMidi: 40),
    ]);

LessonNoteEvent a2Note({
  String id = 'note-a2',
  int startTick = 0,
  int durationTicks = lessonTicksPerQuarter,
}) {
  return LessonNoteEvent(
    id: id,
    startTick: startTick,
    durationTicks: durationTicks,
    required: true,
    position: FretPosition(stringNumber: 6, fret: 5),
    midi: 45,
  );
}

LessonChordEvent cMajorChord({
  String id = 'chord-c',
  int startTick = 0,
}) {
  return LessonChordEvent(
    id: id,
    startTick: startTick,
    durationTicks: lessonTicksPerQuarter,
    required: true,
    symbol: 'C',
    tones: [
      ChordToneTarget(
        position: FretPosition(stringNumber: 5, fret: 3),
        midi: 48,
      ),
      ChordToneTarget(
        position: FretPosition(stringNumber: 4, fret: 2),
        midi: 52,
      ),
      ChordToneTarget(
        position: FretPosition(stringNumber: 3, fret: 0),
        midi: 55,
      ),
    ],
    mutedStrings: const {1, 2, 6},
  );
}

LessonChart validLessonChart({
  List<LessonEvent>? events,
  List<LessonSection>? sections,
  List<TempoPoint>? tempoMap,
  List<MeterPoint>? meterMap,
  int totalTicks = lessonTicksPerQuarter * 4,
}) {
  return LessonChart(
    schemaVersion: 1,
    id: LessonId('lesson-a-minor'),
    title: 'Pentatonica menor de La',
    tuning: standardGuitarTuning(),
    tempoMap: tempoMap ?? [TempoPoint(tick: 0, bpm: 70)],
    meterMap: meterMap ?? [MeterPoint(tick: 0, numerator: 4, denominator: 4)],
    sections: sections ??
        [
          LessonSection(
            id: 'all',
            title: 'Completa',
            startTick: 0,
            endTick: totalTicks,
          ),
        ],
    events: events ?? [a2Note()],
    totalTicks: totalTicks,
  );
}
