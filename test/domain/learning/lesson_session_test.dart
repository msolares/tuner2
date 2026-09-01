import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'learning_fixtures.dart';

void main() {
  test('session status exposes every closed E08 state', () {
    expect(LessonSessionStatus.values, hasLength(11));
    expect(LessonSessionStatus.values, contains(LessonSessionStatus.reentry));
    expect(LessonSessionStatus.values, contains(LessonSessionStatus.failure));
  });

  test('viewport is immutable, comparable and can clear its target', () {
    final events = <LessonEvent>[a2Note()];
    final slice = LessonViewportSlice(
      positionTicks: 0,
      windowStartTick: -960,
      windowEndTick: 3840,
      visibleEvents: events,
      currentTargetId: 'note-a2',
      status: LessonSessionStatus.waitingForTarget,
    );
    events.clear();

    expect(slice.visibleEvents, hasLength(1));
    expect(() => slice.visibleEvents.clear(), throwsUnsupportedError);
    expect(slice, slice.copyWith());
    expect(slice.copyWith(currentTargetId: null).currentTargetId, isNull);
  });

  test('viewport validates window, target and finite position', () {
    expect(
      () => LessonViewportSlice(
        positionTicks: 0,
        windowStartTick: 10,
        windowEndTick: 9,
        visibleEvents: const [],
        currentTargetId: null,
        status: LessonSessionStatus.ready,
      ),
      throwsRangeError,
    );
    expect(
      () => LessonViewportSlice(
        positionTicks: double.nan,
        windowStartTick: 0,
        windowEndTick: 0,
        visibleEvents: const [],
        currentTargetId: null,
        status: LessonSessionStatus.ready,
      ),
      throwsArgumentError,
    );
    expect(
      () => LessonViewportSlice(
        positionTicks: 0,
        windowStartTick: 0,
        windowEndTick: 0,
        visibleEvents: const [],
        currentTargetId: ' ',
        status: LessonSessionStatus.ready,
      ),
      throwsArgumentError,
    );
  });

  test('typed lesson errors use value equality', () {
    expect(LessonErrorCode.values, hasLength(16));
    expect(
      const LessonException(
        LessonErrorCode.lessonNotFound,
        context: 'lesson-a',
      ),
      const LessonException(
        LessonErrorCode.lessonNotFound,
        context: 'lesson-a',
      ),
    );
    expect(
      const LessonException(LessonErrorCode.lessonClockFailure).toString(),
      'LessonException(lessonClockFailure)',
    );
  });
}
