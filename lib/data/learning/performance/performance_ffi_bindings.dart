import 'dart:typed_data';

import '../../../domain/learning/performance.dart';

enum PerformanceFfiObservationKind {
  none(0),
  note(1),
  chord(2);

  const PerformanceFfiObservationKind(this.rawValue);

  final int rawValue;

  static PerformanceFfiObservationKind? fromRaw(int value) {
    for (final kind in values) {
      if (kind.rawValue == value) {
        return kind;
      }
    }
    return null;
  }
}

final class PerformanceFfiTarget {
  const PerformanceFfiTarget.note(this.midi)
      : kind = PerformanceFfiObservationKind.note,
        pitchClasses = const [];

  PerformanceFfiTarget.chord(Iterable<int> pitchClasses)
      : kind = PerformanceFfiObservationKind.chord,
        midi = -1,
        pitchClasses = List.unmodifiable(pitchClasses.toList()..sort());

  final PerformanceFfiObservationKind kind;
  final int midi;
  final List<int> pitchClasses;
}

final class PerformanceFfiResult {
  const PerformanceFfiResult({
    required this.errorCode,
    required this.kind,
    required this.timestampMs,
    required this.onsetSequence,
    required this.confidence,
    required this.hz,
    required this.cents,
    required this.midi,
    required this.pitchClassStrengths,
    required this.onsetConfidence,
  });

  final int errorCode;
  final PerformanceFfiObservationKind? kind;
  final int timestampMs;
  final int onsetSequence;
  final double confidence;
  final double hz;
  final double cents;
  final int midi;
  final List<double> pitchClassStrengths;
  final double onsetConfidence;
}

abstract interface class PerformanceFfiBindings {
  int init(PerformanceAnalyzerSettings settings);

  int setTarget(int handle, PerformanceFfiTarget? target);

  PerformanceFfiResult processFrame(
    int handle,
    Float32List pcm,
    int sampleRateHz,
    int timestampMs,
  );

  int dispose(int handle);
}

abstract final class PerformanceFfiErrorCode {
  static const int ok = 0;
  static const int nullPointer = 1;
  static const int invalidHandle = 2;
  static const int invalidFrame = 3;
  static const int invalidSampleRate = 4;
  static const int unsupportedAbiVersion = 5;
  static const int invalidStructSize = 6;
  static const int invalidSettings = 7;
  static const int invalidTarget = 8;
  static const int nonMonotonicTimestamp = 9;
  static const int internalError = 10;
}
