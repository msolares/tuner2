import 'package:equatable/equatable.dart';

import '../../../domain/learning/learning.dart';

sealed class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => const [];
}

final class LessonLoadRequested extends LessonEvent {
  const LessonLoadRequested({
    required this.lessonId,
    required this.importOptions,
    this.sectionId,
    this.speed = lessonDefaultSpeed,
  });

  final LessonId lessonId;
  final LessonImportOptions importOptions;
  final String? sectionId;
  final double speed;

  @override
  List<Object?> get props => [lessonId, importOptions, sectionId, speed];
}

final class LessonStartRequested extends LessonEvent {
  const LessonStartRequested();
}

final class LessonStopRequested extends LessonEvent {
  const LessonStopRequested();
}

final class LessonPauseRequested extends LessonEvent {
  const LessonPauseRequested();
}

final class LessonResumeRequested extends LessonEvent {
  const LessonResumeRequested();
}

final class LessonSpeedChanged extends LessonEvent {
  const LessonSpeedChanged(this.speed);

  final double speed;

  @override
  List<Object> get props => [speed];
}

final class LessonSectionSelected extends LessonEvent {
  const LessonSectionSelected(this.sectionId);

  final String sectionId;

  @override
  List<Object> get props => [sectionId];
}

final class LessonSectionRepeated extends LessonEvent {
  const LessonSectionRepeated();
}

final class LessonClockTickReceived extends LessonEvent {
  const LessonClockTickReceived(this.tick);

  final LessonClockTick tick;

  @override
  List<Object> get props => [tick];
}

final class LessonObservationReceived extends LessonEvent {
  const LessonObservationReceived(this.observation);

  final PerformanceObservation observation;

  @override
  List<Object> get props => [observation];
}

final class LessonClockStreamFailed extends LessonEvent {
  const LessonClockStreamFailed();
}

final class LessonAnalyzerStreamFailed extends LessonEvent {
  const LessonAnalyzerStreamFailed();
}

final class LessonBackgrounded extends LessonEvent {
  const LessonBackgrounded();
}

final class LessonForegrounded extends LessonEvent {
  const LessonForegrounded();
}
