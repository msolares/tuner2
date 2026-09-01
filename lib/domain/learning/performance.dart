import 'package:equatable/equatable.dart';

import 'lesson_chart.dart';
import 'lesson_errors.dart';

const double lessonMinSpeed = 0.50;
const double lessonMaxSpeed = 1.00;
const double lessonSpeedStep = 0.05;
const double lessonDefaultSpeed = 0.70;

void _requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'No puede estar vacio.');
  }
}

void _requireMidi(int midi, String name) {
  if (midi < 0 || midi > 127) {
    throw RangeError.range(midi, 0, 127, name);
  }
}

void _requireUnitInterval(double value, String name) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw RangeError.range(value, 0, 1, name);
  }
}

bool _isSupportedChordPitchClasses(Set<int> pitchClasses) {
  if (pitchClasses.length == 2) {
    final values = pitchClasses.toList()..sort();
    final distance = (values[1] - values[0]) % 12;
    return distance == 5 || distance == 7;
  }
  if (pitchClasses.length != 3) {
    return false;
  }
  for (final root in pitchClasses) {
    final relative = pitchClasses.map((value) => (value - root) % 12).toSet();
    if (_setEquals(relative, const {0, 4, 7}) ||
        _setEquals(relative, const {0, 3, 7})) {
      return true;
    }
  }
  return false;
}

bool _setEquals<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}

sealed class PerformanceTarget extends Equatable {
  const PerformanceTarget(this.eventId);

  final String eventId;
}

final class NotePerformanceTarget extends PerformanceTarget {
  factory NotePerformanceTarget({required String eventId, required int midi}) {
    _requireText(eventId, 'eventId');
    _requireMidi(midi, 'midi');
    return NotePerformanceTarget._(eventId, midi);
  }

  const NotePerformanceTarget._(super.eventId, this.midi);

  final int midi;

  NotePerformanceTarget copyWith({String? eventId, int? midi}) {
    return NotePerformanceTarget(
      eventId: eventId ?? this.eventId,
      midi: midi ?? this.midi,
    );
  }

  @override
  List<Object> get props => [eventId, midi];
}

final class ChordPerformanceTarget extends PerformanceTarget {
  factory ChordPerformanceTarget({
    required String eventId,
    required Set<int> requiredPitchClasses,
  }) {
    _requireText(eventId, 'eventId');
    if (requiredPitchClasses.any((value) => value < 0 || value > 11)) {
      throw RangeError('requiredPitchClasses debe usar valores 0..11.');
    }
    if (!_isSupportedChordPitchClasses(requiredPitchClasses)) {
      throw const LessonException(LessonErrorCode.unsupportedChord);
    }
    return ChordPerformanceTarget._(
      eventId,
      Set.unmodifiable(requiredPitchClasses),
    );
  }

  const ChordPerformanceTarget._(
    super.eventId,
    this.requiredPitchClasses,
  );

  final Set<int> requiredPitchClasses;

  ChordPerformanceTarget copyWith({
    String? eventId,
    Set<int>? requiredPitchClasses,
  }) {
    return ChordPerformanceTarget(
      eventId: eventId ?? this.eventId,
      requiredPitchClasses: requiredPitchClasses ?? this.requiredPitchClasses,
    );
  }

  @override
  List<Object> get props => [eventId, requiredPitchClasses];
}

sealed class PerformanceObservation extends Equatable {
  const PerformanceObservation({
    required this.timestampMs,
    required this.onsetSequence,
    required this.confidence,
  });

  final int timestampMs;
  final int onsetSequence;
  final double confidence;
}

final class NotePerformanceObservation extends PerformanceObservation {
  factory NotePerformanceObservation({
    required int timestampMs,
    required int onsetSequence,
    required double confidence,
    required double hz,
    required int midi,
    required double cents,
  }) {
    _validateObservation(timestampMs, onsetSequence, confidence);
    if (!hz.isFinite || hz <= 0) {
      throw RangeError.value(hz, 'hz', 'Debe ser finito y positivo.');
    }
    _requireMidi(midi, 'midi');
    if (!cents.isFinite) {
      throw ArgumentError.value(cents, 'cents', 'Debe ser finito.');
    }
    return NotePerformanceObservation._(
      timestampMs: timestampMs,
      onsetSequence: onsetSequence,
      confidence: confidence,
      hz: hz,
      midi: midi,
      cents: cents,
    );
  }

  const NotePerformanceObservation._({
    required super.timestampMs,
    required super.onsetSequence,
    required super.confidence,
    required this.hz,
    required this.midi,
    required this.cents,
  });

  final double hz;
  final int midi;
  final double cents;

  NotePerformanceObservation copyWith({
    int? timestampMs,
    int? onsetSequence,
    double? confidence,
    double? hz,
    int? midi,
    double? cents,
  }) {
    return NotePerformanceObservation(
      timestampMs: timestampMs ?? this.timestampMs,
      onsetSequence: onsetSequence ?? this.onsetSequence,
      confidence: confidence ?? this.confidence,
      hz: hz ?? this.hz,
      midi: midi ?? this.midi,
      cents: cents ?? this.cents,
    );
  }

  @override
  List<Object> get props => [
        timestampMs,
        onsetSequence,
        confidence,
        hz,
        midi,
        cents,
      ];
}

final class ChordPerformanceObservation extends PerformanceObservation {
  factory ChordPerformanceObservation({
    required int timestampMs,
    required int onsetSequence,
    required double confidence,
    required List<double> pitchClassStrengths,
    required double onsetConfidence,
  }) {
    _validateObservation(timestampMs, onsetSequence, confidence);
    if (pitchClassStrengths.length != 12) {
      throw ArgumentError.value(
        pitchClassStrengths.length,
        'pitchClassStrengths',
        'Debe contener 12 valores C..B.',
      );
    }
    for (final strength in pitchClassStrengths) {
      _requireUnitInterval(strength, 'pitchClassStrengths');
    }
    _requireUnitInterval(onsetConfidence, 'onsetConfidence');
    return ChordPerformanceObservation._(
      timestampMs: timestampMs,
      onsetSequence: onsetSequence,
      confidence: confidence,
      pitchClassStrengths: List.unmodifiable(pitchClassStrengths),
      onsetConfidence: onsetConfidence,
    );
  }

  const ChordPerformanceObservation._({
    required super.timestampMs,
    required super.onsetSequence,
    required super.confidence,
    required this.pitchClassStrengths,
    required this.onsetConfidence,
  });

  final List<double> pitchClassStrengths;
  final double onsetConfidence;

  ChordPerformanceObservation copyWith({
    int? timestampMs,
    int? onsetSequence,
    double? confidence,
    List<double>? pitchClassStrengths,
    double? onsetConfidence,
  }) {
    return ChordPerformanceObservation(
      timestampMs: timestampMs ?? this.timestampMs,
      onsetSequence: onsetSequence ?? this.onsetSequence,
      confidence: confidence ?? this.confidence,
      pitchClassStrengths: pitchClassStrengths ?? this.pitchClassStrengths,
      onsetConfidence: onsetConfidence ?? this.onsetConfidence,
    );
  }

  @override
  List<Object> get props => [
        timestampMs,
        onsetSequence,
        confidence,
        pitchClassStrengths,
        onsetConfidence,
      ];
}

void _validateObservation(
  int timestampMs,
  int onsetSequence,
  double confidence,
) {
  if (timestampMs < 0) {
    throw RangeError.value(timestampMs, 'timestampMs');
  }
  if (onsetSequence < 0) {
    throw RangeError.value(onsetSequence, 'onsetSequence');
  }
  _requireUnitInterval(confidence, 'confidence');
}

final class PerformanceAnalyzerSettings extends Equatable {
  factory PerformanceAnalyzerSettings({required double a4Hz}) {
    if (!a4Hz.isFinite || a4Hz < 415 || a4Hz > 466) {
      throw RangeError.range(a4Hz, 415, 466, 'a4Hz');
    }
    return PerformanceAnalyzerSettings._(a4Hz);
  }

  const PerformanceAnalyzerSettings._(this.a4Hz);

  final double a4Hz;

  PerformanceAnalyzerSettings copyWith({double? a4Hz}) {
    return PerformanceAnalyzerSettings(a4Hz: a4Hz ?? this.a4Hz);
  }

  @override
  List<Object> get props => [a4Hz];
}

final class LessonEvaluationPolicy extends Equatable {
  factory LessonEvaluationPolicy({
    required double noteMinConfidence,
    required double noteMaxAbsCents,
    required int noteStableMs,
    required int chordWindowMs,
    required double chordMinOnsetConfidence,
    required double chordMinToneStrength,
    required double chordMinMeanStrength,
    required int reentryTicks,
  }) {
    _requireUnitInterval(noteMinConfidence, 'noteMinConfidence');
    if (!noteMaxAbsCents.isFinite ||
        noteMaxAbsCents < 0 ||
        noteMaxAbsCents > 100) {
      throw RangeError.range(noteMaxAbsCents, 0, 100, 'noteMaxAbsCents');
    }
    if (noteStableMs <= 0) {
      throw RangeError.value(noteStableMs, 'noteStableMs');
    }
    if (chordWindowMs <= 0) {
      throw RangeError.value(chordWindowMs, 'chordWindowMs');
    }
    _requireUnitInterval(
      chordMinOnsetConfidence,
      'chordMinOnsetConfidence',
    );
    _requireUnitInterval(chordMinToneStrength, 'chordMinToneStrength');
    _requireUnitInterval(chordMinMeanStrength, 'chordMinMeanStrength');
    if (reentryTicks < 0) {
      throw RangeError.value(reentryTicks, 'reentryTicks');
    }
    return LessonEvaluationPolicy._(
      noteMinConfidence,
      noteMaxAbsCents,
      noteStableMs,
      chordWindowMs,
      chordMinOnsetConfidence,
      chordMinToneStrength,
      chordMinMeanStrength,
      reentryTicks,
    );
  }

  const LessonEvaluationPolicy._(
    this.noteMinConfidence,
    this.noteMaxAbsCents,
    this.noteStableMs,
    this.chordWindowMs,
    this.chordMinOnsetConfidence,
    this.chordMinToneStrength,
    this.chordMinMeanStrength,
    this.reentryTicks,
  );

  final double noteMinConfidence;
  final double noteMaxAbsCents;
  final int noteStableMs;
  final int chordWindowMs;
  final double chordMinOnsetConfidence;
  final double chordMinToneStrength;
  final double chordMinMeanStrength;
  final int reentryTicks;

  static LessonEvaluationPolicy get defaults => LessonEvaluationPolicy(
        noteMinConfidence: 0.65,
        noteMaxAbsCents: 25,
        noteStableMs: 100,
        chordWindowMs: 700,
        chordMinOnsetConfidence: 0.45,
        chordMinToneStrength: 0.45,
        chordMinMeanStrength: 0.60,
        reentryTicks: lessonTicksPerQuarter,
      );

  LessonEvaluationPolicy copyWith({
    double? noteMinConfidence,
    double? noteMaxAbsCents,
    int? noteStableMs,
    int? chordWindowMs,
    double? chordMinOnsetConfidence,
    double? chordMinToneStrength,
    double? chordMinMeanStrength,
    int? reentryTicks,
  }) {
    return LessonEvaluationPolicy(
      noteMinConfidence: noteMinConfidence ?? this.noteMinConfidence,
      noteMaxAbsCents: noteMaxAbsCents ?? this.noteMaxAbsCents,
      noteStableMs: noteStableMs ?? this.noteStableMs,
      chordWindowMs: chordWindowMs ?? this.chordWindowMs,
      chordMinOnsetConfidence:
          chordMinOnsetConfidence ?? this.chordMinOnsetConfidence,
      chordMinToneStrength: chordMinToneStrength ?? this.chordMinToneStrength,
      chordMinMeanStrength: chordMinMeanStrength ?? this.chordMinMeanStrength,
      reentryTicks: reentryTicks ?? this.reentryTicks,
    );
  }

  @override
  List<Object> get props => [
        noteMinConfidence,
        noteMaxAbsCents,
        noteStableMs,
        chordWindowMs,
        chordMinOnsetConfidence,
        chordMinToneStrength,
        chordMinMeanStrength,
        reentryTicks,
      ];
}

final class LessonClockTick extends Equatable {
  factory LessonClockTick({
    required double positionTicks,
    required int monotonicTimestampMs,
  }) {
    if (!positionTicks.isFinite) {
      throw ArgumentError.value(positionTicks, 'positionTicks');
    }
    if (monotonicTimestampMs < 0) {
      throw RangeError.value(monotonicTimestampMs, 'monotonicTimestampMs');
    }
    return LessonClockTick._(positionTicks, monotonicTimestampMs);
  }

  const LessonClockTick._(this.positionTicks, this.monotonicTimestampMs);

  final double positionTicks;
  final int monotonicTimestampMs;

  LessonClockTick copyWith({
    double? positionTicks,
    int? monotonicTimestampMs,
  }) {
    return LessonClockTick(
      positionTicks: positionTicks ?? this.positionTicks,
      monotonicTimestampMs: monotonicTimestampMs ?? this.monotonicTimestampMs,
    );
  }

  @override
  List<Object> get props => [positionTicks, monotonicTimestampMs];
}
