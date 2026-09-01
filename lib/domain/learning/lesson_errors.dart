import 'package:equatable/equatable.dart';

enum LessonErrorCode {
  lessonNotFound,
  lessonCatalogUnavailable,
  invalidLessonCatalog,
  invalidLessonDocument,
  unsupportedMusicXmlVersion,
  partNotFound,
  tablatureNotFound,
  invalidTuning,
  unsupportedRhythmResolution,
  unsupportedNavigation,
  inconsistentPitchAndFret,
  unsupportedChord,
  performanceAnalyzerUnavailable,
  audioPermissionDenied,
  lessonClockFailure,
  sessionInvariantViolation,
}

final class LessonException extends Equatable implements Exception {
  const LessonException(this.code, {this.context});

  final LessonErrorCode code;
  final String? context;

  @override
  List<Object?> get props => [code, context];

  @override
  String toString() {
    final suffix = context == null ? '' : ': $context';
    return 'LessonException(${code.name}$suffix)';
  }
}
