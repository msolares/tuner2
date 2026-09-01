import 'dart:collection';

import 'package:equatable/equatable.dart';

import 'lesson_chart.dart';
import 'lesson_errors.dart';
import 'performance.dart';

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

final class LessonEventResult extends Equatable {
  factory LessonEventResult({
    required String eventId,
    required int attempt,
    required int completedAtTimestampMs,
    required int onsetSequence,
  }) {
    if (eventId.trim().isEmpty) throw ArgumentError.value(eventId, 'eventId');
    if (attempt <= 0) throw RangeError.value(attempt, 'attempt');
    if (completedAtTimestampMs < 0) {
      throw RangeError.value(completedAtTimestampMs, 'completedAtTimestampMs');
    }
    if (onsetSequence < 0) {
      throw RangeError.value(onsetSequence, 'onsetSequence');
    }
    return LessonEventResult._(
      eventId,
      attempt,
      completedAtTimestampMs,
      onsetSequence,
    );
  }

  const LessonEventResult._(
    this.eventId,
    this.attempt,
    this.completedAtTimestampMs,
    this.onsetSequence,
  );

  final String eventId;
  final int attempt;
  final int completedAtTimestampMs;
  final int onsetSequence;

  LessonEventResult copyWith({
    String? eventId,
    int? attempt,
    int? completedAtTimestampMs,
    int? onsetSequence,
  }) {
    return LessonEventResult(
      eventId: eventId ?? this.eventId,
      attempt: attempt ?? this.attempt,
      completedAtTimestampMs:
          completedAtTimestampMs ?? this.completedAtTimestampMs,
      onsetSequence: onsetSequence ?? this.onsetSequence,
    );
  }

  @override
  List<Object> get props => [
        eventId,
        attempt,
        completedAtTimestampMs,
        onsetSequence,
      ];
}

final class LessonSessionState extends Equatable {
  factory LessonSessionState({
    required LessonChart chart,
    required LessonSection section,
    required LessonSessionStatus status,
    required double positionTicks,
    required double speed,
    required LessonEvent? currentTarget,
    required Map<String, LessonEventResult> results,
    required int attempt,
    LessonException? error,
    LessonSessionStatus? resumeStatus,
    int? waitStartedTimestampMs,
    int? feedbackUntilTimestampMs,
  }) {
    if (section.startTick < 0 || section.endTick > chart.totalTicks) {
      throw const LessonException(LessonErrorCode.sessionInvariantViolation);
    }
    if (!positionTicks.isFinite) {
      throw ArgumentError.value(positionTicks, 'positionTicks');
    }
    validateLessonSpeed(speed);
    if (attempt <= 0) throw RangeError.value(attempt, 'attempt');
    if (currentTarget != null && !chart.events.contains(currentTarget)) {
      throw const LessonException(LessonErrorCode.sessionInvariantViolation);
    }
    if (waitStartedTimestampMs != null && waitStartedTimestampMs < 0) {
      throw RangeError.value(waitStartedTimestampMs, 'waitStartedTimestampMs');
    }
    if (feedbackUntilTimestampMs != null && feedbackUntilTimestampMs < 0) {
      throw RangeError.value(
        feedbackUntilTimestampMs,
        'feedbackUntilTimestampMs',
      );
    }
    return LessonSessionState._(
      chart,
      section,
      status,
      positionTicks,
      speed,
      currentTarget,
      UnmodifiableMapView(Map.of(results)),
      attempt,
      error,
      resumeStatus,
      waitStartedTimestampMs,
      feedbackUntilTimestampMs,
    );
  }

  const LessonSessionState._(
    this.chart,
    this.section,
    this.status,
    this.positionTicks,
    this.speed,
    this.currentTarget,
    this.results,
    this.attempt,
    this.error,
    this.resumeStatus,
    this.waitStartedTimestampMs,
    this.feedbackUntilTimestampMs,
  );

  static const Object _notProvided = Object();

  final LessonChart chart;
  final LessonSection section;
  final LessonSessionStatus status;
  final double positionTicks;
  final double speed;
  final LessonEvent? currentTarget;
  final Map<String, LessonEventResult> results;
  final int attempt;
  final LessonException? error;
  final LessonSessionStatus? resumeStatus;
  final int? waitStartedTimestampMs;
  final int? feedbackUntilTimestampMs;

  LessonSessionState copyWith({
    LessonChart? chart,
    LessonSection? section,
    LessonSessionStatus? status,
    double? positionTicks,
    double? speed,
    Object? currentTarget = _notProvided,
    Map<String, LessonEventResult>? results,
    int? attempt,
    Object? error = _notProvided,
    Object? resumeStatus = _notProvided,
    Object? waitStartedTimestampMs = _notProvided,
    Object? feedbackUntilTimestampMs = _notProvided,
  }) {
    return LessonSessionState(
      chart: chart ?? this.chart,
      section: section ?? this.section,
      status: status ?? this.status,
      positionTicks: positionTicks ?? this.positionTicks,
      speed: speed ?? this.speed,
      currentTarget: identical(currentTarget, _notProvided)
          ? this.currentTarget
          : currentTarget as LessonEvent?,
      results: results ?? this.results,
      attempt: attempt ?? this.attempt,
      error: identical(error, _notProvided)
          ? this.error
          : error as LessonException?,
      resumeStatus: identical(resumeStatus, _notProvided)
          ? this.resumeStatus
          : resumeStatus as LessonSessionStatus?,
      waitStartedTimestampMs: identical(waitStartedTimestampMs, _notProvided)
          ? this.waitStartedTimestampMs
          : waitStartedTimestampMs as int?,
      feedbackUntilTimestampMs:
          identical(feedbackUntilTimestampMs, _notProvided)
              ? this.feedbackUntilTimestampMs
              : feedbackUntilTimestampMs as int?,
    );
  }

  @override
  List<Object?> get props => [
        chart,
        section,
        status,
        positionTicks,
        speed,
        currentTarget,
        results,
        attempt,
        error,
        resumeStatus,
        waitStartedTimestampMs,
        feedbackUntilTimestampMs,
      ];
}

void validateLessonSpeed(double speed) {
  if (!speed.isFinite || speed < lessonMinSpeed || speed > lessonMaxSpeed) {
    throw RangeError.value(
      speed,
      'speed',
      'Debe estar entre 0.50 y 1.00.',
    );
  }
  final steps = (speed / lessonSpeedStep).round();
  if ((steps * lessonSpeedStep - speed).abs() > 0.0000001) {
    throw ArgumentError.value(speed, 'speed', 'Debe usar pasos de 0.05.');
  }
}

final class LessonViewportSlice extends Equatable {
  factory LessonViewportSlice({
    required double positionTicks,
    required int windowStartTick,
    required int windowEndTick,
    required List<LessonEvent> visibleEvents,
    required String? currentTargetId,
    required LessonSessionStatus status,
  }) {
    if (!positionTicks.isFinite) {
      throw ArgumentError.value(positionTicks, 'positionTicks');
    }
    if (windowEndTick < windowStartTick) {
      throw RangeError('windowEndTick debe ser >= windowStartTick.');
    }
    if (currentTargetId != null && currentTargetId.trim().isEmpty) {
      throw ArgumentError.value(currentTargetId, 'currentTargetId');
    }
    return LessonViewportSlice._(
      positionTicks,
      windowStartTick,
      windowEndTick,
      List.unmodifiable(visibleEvents),
      currentTargetId,
      status,
    );
  }

  const LessonViewportSlice._(
    this.positionTicks,
    this.windowStartTick,
    this.windowEndTick,
    this.visibleEvents,
    this.currentTargetId,
    this.status,
  );

  static const Object _notProvided = Object();

  final double positionTicks;
  final int windowStartTick;
  final int windowEndTick;
  final List<LessonEvent> visibleEvents;
  final String? currentTargetId;
  final LessonSessionStatus status;

  LessonViewportSlice copyWith({
    double? positionTicks,
    int? windowStartTick,
    int? windowEndTick,
    List<LessonEvent>? visibleEvents,
    Object? currentTargetId = _notProvided,
    LessonSessionStatus? status,
  }) {
    return LessonViewportSlice(
      positionTicks: positionTicks ?? this.positionTicks,
      windowStartTick: windowStartTick ?? this.windowStartTick,
      windowEndTick: windowEndTick ?? this.windowEndTick,
      visibleEvents: visibleEvents ?? this.visibleEvents,
      currentTargetId: identical(currentTargetId, _notProvided)
          ? this.currentTargetId
          : currentTargetId as String?,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        positionTicks,
        windowStartTick,
        windowEndTick,
        visibleEvents,
        currentTargetId,
        status,
      ];
}
