import 'dart:math';
import 'dart:typed_data';

import 'package:afinador/data/audio/audio_pcm_frame.dart';
import 'package:afinador/data/learning/performance/web_performance_analysis_kernel.dart';
import 'package:afinador/domain/learning/performance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = PerformanceAnalyzerSettings(a4Hz: 440);

  group('WebPerformanceAnalysisKernel', () {
    test('emits a directed monophonic observation with a global onset',
        () async {
      final kernel = WebPerformanceAnalysisKernel();
      kernel.setTarget(NotePerformanceTarget(eventId: 'a4', midi: 69));

      final observation = await kernel.process(
        _frame(_sine(440, 4096), timestampMs: 100),
        settings,
      ) as NotePerformanceObservation;

      expect(observation.midi, 69);
      expect(observation.hz, closeTo(440, 3));
      expect(observation.onsetSequence, 1);
      expect(observation.confidence, inInclusiveRange(0, 1));
    });

    test('emits C..B chroma for major, minor and power chord targets',
        () async {
      final cases = <(Set<int>, List<int>)>[
        (const {0, 4, 7}, const [48, 52, 55, 60, 64]),
        (const {9, 0, 4}, const [45, 52, 57, 60, 64]),
        (const {4, 11}, const [40, 47, 52]),
      ];
      for (final (target, notes) in cases) {
        final kernel = WebPerformanceAnalysisKernel();
        kernel.setTarget(
          ChordPerformanceTarget(
            eventId: 'chord-$target',
            requiredPitchClasses: target,
          ),
        );
        final observation = await kernel.process(
          _frame(_guitarChord(notes, 8192), timestampMs: 100),
          settings,
        ) as ChordPerformanceObservation;

        expect(observation.pitchClassStrengths, hasLength(12));
        for (final pitchClass in target) {
          expect(
            observation.pitchClassStrengths[pitchClass],
            greaterThanOrEqualTo(0.28),
            reason: 'missing pitch class $pitchClass for $target',
          );
        }
        expect(observation.onsetSequence, 1);
        expect(observation.onsetConfidence, greaterThanOrEqualTo(0.45));
      }
    });

    test('accumulates a strum in 700 ms without an unbounded history',
        () async {
      final kernel = WebPerformanceAnalysisKernel();
      kernel.setTarget(
        ChordPerformanceTarget(
          eventId: 'c',
          requiredPitchClasses: const {0, 4, 7},
        ),
      );
      var timestamp = 0;
      ChordPerformanceObservation? observation;
      for (final midi in [48, 52, 55]) {
        observation = await kernel.process(
          _frame(_guitarChord([midi], 2048), timestampMs: timestamp += 43),
          settings,
        ) as ChordPerformanceObservation;
      }
      expect(webPerformanceMaxChromaFrames, 64);
      expect(observation!.pitchClassStrengths[0], greaterThanOrEqualTo(0.28));
      expect(observation.pitchClassStrengths[4], greaterThanOrEqualTo(0.28));
      expect(observation.pitchClassStrengths[7], greaterThanOrEqualTo(0.28));
    });

    test('does not emit without target and rejects malformed frames', () async {
      final kernel = WebPerformanceAnalysisKernel();
      expect(
        await kernel.process(
          _frame(_sine(440, 1024), timestampMs: 1),
          settings,
        ),
        isNull,
      );
      kernel.setTarget(NotePerformanceTarget(eventId: 'a4', midi: 69));
      expect(
        kernel.process(
          _frame(Float32List(32), timestampMs: 2),
          settings,
        ),
        throwsFormatException,
      );
    });

    test('caps oversized input and keeps work inside a fixed local budget',
        () async {
      final kernel = WebPerformanceAnalysisKernel();
      kernel.setTarget(
        ChordPerformanceTarget(
          eventId: 'c',
          requiredPitchClasses: const {0, 4, 7},
        ),
      );
      final oversized = _guitarChord(const [48, 52, 55], 16384);
      final stopwatch = Stopwatch()..start();
      final observation = await kernel.process(
        _frame(oversized, timestampMs: 100),
        settings,
      );
      stopwatch.stop();

      expect(observation, isA<ChordPerformanceObservation>());
      expect(webPerformanceMaxAnalysisSamples, 8192);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 750)));
    });
  });
}

AudioPcmFrame _frame(Float32List pcm, {required int timestampMs}) {
  return AudioPcmFrame(
    pcmFloat32: pcm,
    sampleRateHz: 48000,
    timestampMs: timestampMs,
  );
}

Float32List _sine(double frequency, int length) {
  return Float32List.fromList(
    List<double>.generate(
      length,
      (index) => sin(2 * pi * frequency * index / 48000) * 0.35,
    ),
  );
}

Float32List _guitarChord(List<int> notes, int length) {
  const harmonics = <(double, double)>[
    (1, 1),
    (2, 0.36),
    (3, 0.18),
    (4, 0.09),
  ];
  final scale = 0.35 / max(notes.length, 1);
  return Float32List.fromList(
    List<double>.generate(length, (index) {
      final attack = min(index / 240, 1);
      final decay = exp(-2.2 * index / length);
      var sample = 0.0;
      for (final midi in notes) {
        final hz = 440 * pow(2, (midi - 69) / 12);
        for (final (multiple, weight) in harmonics) {
          sample += sin(2 * pi * hz * multiple * index / 48000) * weight;
        }
      }
      return sample * scale * attack * decay;
    }),
  );
}
