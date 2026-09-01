import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('performance targets', () {
    test('note target validates event and MIDI', () {
      final target = NotePerformanceTarget(eventId: 'a2', midi: 45);
      expect(target, target.copyWith());
      expect(() => target.copyWith(midi: 128), throwsRangeError);
      expect(
        () => NotePerformanceTarget(eventId: ' ', midi: 45),
        throwsArgumentError,
      );
    });

    test('chord target supports power chords and major/minor triads', () {
      expect(
        ChordPerformanceTarget(
          eventId: 'c5',
          requiredPitchClasses: const {0, 7},
        ).requiredPitchClasses,
        {0, 7},
      );
      expect(
        ChordPerformanceTarget(
          eventId: 'am',
          requiredPitchClasses: const {9, 0, 4},
        ),
        ChordPerformanceTarget(
          eventId: 'am',
          requiredPitchClasses: const {4, 9, 0},
        ),
      );
      expect(
        () => ChordPerformanceTarget(
          eventId: 'bad',
          requiredPitchClasses: const {0, 1, 2},
        ),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.unsupportedChord,
          ),
        ),
      );
      expect(
        () => ChordPerformanceTarget(
          eventId: 'bad',
          requiredPitchClasses: const {0, 12},
        ),
        throwsRangeError,
      );
    });
  });

  group('performance observations', () {
    test('note observation validates normalized evidence', () {
      final observation = NotePerformanceObservation(
        timestampMs: 10,
        onsetSequence: 1,
        confidence: 0.8,
        hz: 110,
        midi: 45,
        cents: -2.5,
      );

      expect(observation, observation.copyWith());
      expect(() => observation.copyWith(confidence: 1.1), throwsRangeError);
      expect(() => observation.copyWith(hz: 0), throwsRangeError);
      expect(
          () => observation.copyWith(cents: double.nan), throwsArgumentError);
      expect(() => observation.copyWith(timestampMs: -1), throwsRangeError);
    });

    test('chord observation requires twelve immutable strengths', () {
      final strengths = List<double>.filled(12, 0.5);
      final observation = ChordPerformanceObservation(
        timestampMs: 10,
        onsetSequence: 1,
        confidence: 0.75,
        pitchClassStrengths: strengths,
        onsetConfidence: 0.6,
      );
      strengths[0] = 1;

      expect(observation.pitchClassStrengths.first, 0.5);
      expect(
        () => observation.pitchClassStrengths.add(0.2),
        throwsUnsupportedError,
      );
      expect(
        () => observation.copyWith(pitchClassStrengths: const [0.5]),
        throwsArgumentError,
      );
      expect(
        () => observation.copyWith(
          pitchClassStrengths: [double.nan, ...List.filled(11, 0.5)],
        ),
        throwsRangeError,
      );
      expect(
        () => observation.copyWith(onsetConfidence: -0.1),
        throwsRangeError,
      );
    });
  });

  group('settings and evaluation policy', () {
    test('analyzer settings enforce the A4 range', () {
      expect(PerformanceAnalyzerSettings(a4Hz: 415).a4Hz, 415);
      expect(PerformanceAnalyzerSettings(a4Hz: 466).a4Hz, 466);
      expect(
        () => PerformanceAnalyzerSettings(a4Hz: 414.99),
        throwsRangeError,
      );
      expect(
        () => PerformanceAnalyzerSettings(a4Hz: double.infinity),
        throwsRangeError,
      );
    });

    test('defaults match E08 and copyWith revalidates', () {
      final policy = LessonEvaluationPolicy.defaults;

      expect(lessonMinSpeed, 0.50);
      expect(lessonMaxSpeed, 1.00);
      expect(lessonSpeedStep, 0.05);
      expect(lessonDefaultSpeed, 0.70);
      expect(policy.noteMinConfidence, 0.65);
      expect(policy.noteMaxAbsCents, 25);
      expect(policy.noteStableMs, 100);
      expect(policy.chordWindowMs, 700);
      expect(policy.chordMinOnsetConfidence, 0.45);
      expect(policy.chordMinToneStrength, 0.45);
      expect(policy.chordMinMeanStrength, 0.60);
      expect(policy.reentryTicks, lessonTicksPerQuarter);
      expect(policy, policy.copyWith());
      expect(() => policy.copyWith(noteStableMs: 0), throwsRangeError);
      expect(
        () => policy.copyWith(noteMaxAbsCents: double.nan),
        throwsRangeError,
      );
      expect(
        () => policy.copyWith(chordMinMeanStrength: 1.1),
        throwsRangeError,
      );
      expect(() => policy.copyWith(reentryTicks: -1), throwsRangeError);
    });

    test('clock tick allows count-in but requires finite monotonic data', () {
      final tick = LessonClockTick(
        positionTicks: -lessonTicksPerQuarter.toDouble(),
        monotonicTimestampMs: 0,
      );
      expect(tick.positionTicks, -960);
      expect(tick, tick.copyWith());
      expect(
        () => tick.copyWith(positionTicks: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => tick.copyWith(monotonicTimestampMs: -1),
        throwsRangeError,
      );
    });
  });
}
