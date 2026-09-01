import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'learning_fixtures.dart';

void main() {
  group('lesson chart value objects', () {
    test('validate identifiers, string numbers, frets and MIDI', () {
      expect(() => LessonId('  '), throwsArgumentError);
      expect(
        () => FretPosition(stringNumber: 0, fret: 0),
        throwsRangeError,
      );
      expect(
        () => FretPosition(stringNumber: 1, fret: 25),
        throwsRangeError,
      );
      expect(
        () => GuitarStringTuning(stringNumber: 1, openMidi: 128),
        throwsRangeError,
      );
    });

    test('use value equality and validated copyWith', () {
      final position = FretPosition(stringNumber: 6, fret: 5);
      expect(position, FretPosition(stringNumber: 6, fret: 5));
      expect(
          position.copyWith(fret: 8), FretPosition(stringNumber: 6, fret: 8));
      expect(() => position.copyWith(fret: -1), throwsRangeError);
    });

    test('requires exactly six ordered tuning entries', () {
      final source = standardGuitarTuning().strings.toList();
      expect(GuitarTuningSpec(source), standardGuitarTuning());
      expect(
        () => GuitarTuningSpec(source.take(5).toList()),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.invalidTuning,
          ),
        ),
      );
      expect(
        () => GuitarTuningSpec([source[1], source[0], ...source.skip(2)]),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => standardGuitarTuning().strings.add(source.first),
        throwsUnsupportedError,
      );
    });

    test('validates tempo and meter boundaries', () {
      expect(TempoPoint(tick: 0, bpm: 20), TempoPoint(tick: 0, bpm: 20));
      expect(() => TempoPoint(tick: -1, bpm: 70), throwsRangeError);
      expect(() => TempoPoint(tick: 0, bpm: double.nan), throwsRangeError);
      expect(() => TempoPoint(tick: 0, bpm: 301), throwsRangeError);
      expect(
        MeterPoint(tick: 0, numerator: 32, denominator: 32).denominator,
        32,
      );
      expect(
        () => MeterPoint(tick: 0, numerator: 0, denominator: 4),
        throwsRangeError,
      );
      expect(
        () => MeterPoint(tick: 0, numerator: 4, denominator: 3),
        throwsArgumentError,
      );
    });
  });

  group('lesson events', () {
    test('note is immutable, comparable and validates local ranges', () {
      final techniques = <GuitarTechnique>{GuitarTechnique.hammerOn};
      final note = LessonNoteEvent(
        id: 'a2',
        startTick: 0,
        durationTicks: 960,
        required: true,
        position: FretPosition(stringNumber: 6, fret: 5),
        midi: 45,
        techniques: techniques,
      );
      techniques.add(GuitarTechnique.slide);

      expect(note.techniques, {GuitarTechnique.hammerOn});
      expect(() => note.techniques.add(GuitarTechnique.bend),
          throwsUnsupportedError);
      expect(note, note.copyWith());
      expect(() => note.copyWith(durationTicks: 0), throwsRangeError);
      expect(() => note.copyWith(midi: -1), throwsRangeError);
    });

    test('accepts major/minor triads and power chords', () {
      expect(cMajorChord().requiredPitchClasses, {0, 4, 7});

      final powerChord = LessonChordEvent(
        id: 'c5',
        startTick: 0,
        durationTicks: 960,
        required: true,
        symbol: 'C5',
        tones: [
          ChordToneTarget(
            position: FretPosition(stringNumber: 5, fret: 3),
            midi: 48,
          ),
          ChordToneTarget(
            position: FretPosition(stringNumber: 4, fret: 5),
            midi: 55,
          ),
        ],
        mutedStrings: const {1, 2, 3, 6},
      );

      expect(powerChord.requiredPitchClasses, {0, 7});
      expect(powerChord, powerChord.copyWith());
    });

    test('rejects unsupported chords, duplicate strings and bad mute sets', () {
      LessonChordEvent build({
        required List<ChordToneTarget> tones,
        required Set<int> muted,
      }) {
        return LessonChordEvent(
          id: 'bad',
          startTick: 0,
          durationTicks: 960,
          required: true,
          symbol: 'bad',
          tones: tones,
          mutedStrings: muted,
        );
      }

      final duplicateString = [
        ChordToneTarget(
          position: FretPosition(stringNumber: 5, fret: 3),
          midi: 48,
        ),
        ChordToneTarget(
          position: FretPosition(stringNumber: 5, fret: 10),
          midi: 55,
        ),
      ];
      expect(
        () => build(tones: duplicateString, muted: const {1, 2, 3, 4, 6}),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => build(tones: cMajorChord().tones, muted: const {1, 2}),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => build(
          tones: [
            ChordToneTarget(
              position: FretPosition(stringNumber: 6, fret: 0),
              midi: 40,
            ),
            ChordToneTarget(
              position: FretPosition(stringNumber: 5, fret: 1),
              midi: 46,
            ),
          ],
          muted: const {1, 2, 3, 4},
        ),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.unsupportedChord,
          ),
        ),
      );
    });
  });

  group('LessonChart', () {
    test('builds an immutable value chart and preserves canonical PPQ', () {
      final events = <LessonEvent>[a2Note()];
      final chart = validLessonChart(events: events);
      events.add(a2Note(id: 'later', startTick: 960));

      expect(lessonTicksPerQuarter, 960);
      expect(chart.events, hasLength(1));
      expect(() => chart.events.add(a2Note()), throwsUnsupportedError);
      expect(chart, chart.copyWith());
      expect(chart.copyWith(title: 'Otra').title, 'Otra');
    });

    test('requires maps at zero with unique ascending ticks', () {
      expect(
        () => validLessonChart(tempoMap: [TempoPoint(tick: 1, bpm: 70)]),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => validLessonChart(
          meterMap: [
            MeterPoint(tick: 0, numerator: 4, denominator: 4),
            MeterPoint(tick: 0, numerator: 3, denominator: 4),
          ],
        ),
        throwsA(isA<LessonException>()),
      );
    });

    test('rejects duplicate IDs, unordered events and timeline overflow', () {
      expect(
        () => validLessonChart(events: [a2Note(), a2Note()]),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => validLessonChart(
          events: [
            a2Note(id: 'late', startTick: 960),
            a2Note(id: 'early', startTick: 0),
          ],
        ),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => validLessonChart(
          totalTicks: 100,
          sections: const [],
          events: [a2Note(durationTicks: 101)],
        ),
        throwsA(isA<LessonException>()),
      );
    });

    test('rejects pitch that disagrees with tuning and fret', () {
      final inconsistent = a2Note().copyWith(midi: 46);
      expect(
        () => validLessonChart(events: [inconsistent]),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.inconsistentPitchAndFret,
          ),
        ),
      );
    });

    test('rejects unsupported schema and invalid sections', () {
      final chart = validLessonChart();
      expect(
        () => chart.copyWith(schemaVersion: 2),
        throwsA(isA<LessonException>()),
      );
      expect(
        () => validLessonChart(
          sections: [
            LessonSection(
              id: 'too-long',
              title: 'Too long',
              startTick: 0,
              endTick: 5000,
            ),
          ],
        ),
        throwsA(isA<LessonException>()),
      );
    });
  });
}
