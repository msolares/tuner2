import 'package:equatable/equatable.dart';

import 'lesson_chart.dart';

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
