import 'package:afinador/data/learning/clock/monotonic_lesson_clock.dart';
import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonotonicLessonClock', () {
    test('derives position from absolute monotonic time and tempo', () async {
      final harness = _ClockHarness();
      final ticks = <LessonClockTick>[];
      final subscription = harness.clock.ticks().listen(ticks.add);

      await harness.clock.start(
        initialTick: -960,
        speed: 1,
        tempoMap: [TempoPoint(tick: 0, bpm: 120)],
      );
      harness.advance(const Duration(milliseconds: 500));

      expect(ticks.last.positionTicks, closeTo(0, 0.001));
      expect(ticks.last.monotonicTimestampMs, 500);
      await subscription.cancel();
    });

    test('crosses tempo changes without accumulating deltas', () async {
      final harness = _ClockHarness();
      final tick = harness.clock.ticks().firstWhere(
            (value) => value.monotonicTimestampMs == 1500,
          );
      await harness.clock.start(
        initialTick: 0,
        speed: 1,
        tempoMap: [
          TempoPoint(tick: 0, bpm: 60),
          TempoPoint(tick: 960, bpm: 120),
        ],
      );

      harness.advance(const Duration(milliseconds: 1500));

      expect((await tick).positionTicks, closeTo(1920, 0.001));
    });

    test('stays within 20 ms equivalent after ten minutes', () async {
      final harness = _ClockHarness();
      final values = <LessonClockTick>[];
      final subscription = harness.clock.ticks().listen(values.add);
      await harness.clock.start(
        initialTick: 0,
        speed: 0.7,
        tempoMap: [TempoPoint(tick: 0, bpm: 70)],
      );

      harness.advance(const Duration(minutes: 10));

      const expectedTicks = 70 * lessonTicksPerQuarter / 60 * 0.7 * 600;
      const ticksIn20Ms = 70 * lessonTicksPerQuarter / 60 * 0.7 * 0.020;
      expect(
        (values.last.positionTicks - expectedTicks).abs(),
        lessThanOrEqualTo(ticksIn20Ms),
      );
      await subscription.cancel();
    });

    test('speed change preserves position and applies the new rate', () async {
      final harness = _ClockHarness();
      final values = <LessonClockTick>[];
      final subscription = harness.clock.ticks().listen(values.add);
      await harness.clock.start(
        initialTick: 0,
        speed: 1,
        tempoMap: [TempoPoint(tick: 0, bpm: 60)],
      );
      harness.advance(const Duration(milliseconds: 500));

      await harness.clock.setSpeed(0.5);
      expect(values.last.positionTicks, closeTo(480, 0.001));
      harness.advance(const Duration(seconds: 1));
      expect(values.last.positionTicks, closeTo(960, 0.001));
      await subscription.cancel();
    });

    test('pause resume and seek are atomic and idempotent', () async {
      final harness = _ClockHarness();
      final values = <LessonClockTick>[];
      final subscription = harness.clock.ticks().listen(values.add);
      final tempoMap = [TempoPoint(tick: 0, bpm: 60)];
      await harness.clock.start(
        initialTick: 0,
        speed: 1,
        tempoMap: tempoMap,
      );
      await harness.clock.start(
        initialTick: 0,
        speed: 1,
        tempoMap: tempoMap,
      );
      expect(harness.scheduler.activeTasks, 1);

      harness.time.advance(const Duration(milliseconds: 250));
      await harness.clock.pause();
      await harness.clock.pause();
      expect(values.last.positionTicks, closeTo(240, 0.001));
      harness.time.advance(const Duration(seconds: 1));
      expect(values.last.positionTicks, closeTo(240, 0.001));

      await harness.clock.seek(-960);
      await harness.clock.resume();
      await harness.clock.resume();
      expect(harness.scheduler.activeTasks, 1);
      harness.advance(const Duration(seconds: 1));
      expect(values.last.positionTicks, closeTo(0, 0.001));

      await harness.clock.stop();
      await harness.clock.stop();
      expect(harness.scheduler.activeTasks, 0);
      await subscription.cancel();
    });

    test('late callbacks skip deadlines instead of emitting a burst', () async {
      final harness = _ClockHarness();
      final values = <LessonClockTick>[];
      final subscription = harness.clock.ticks().listen(values.add);
      await harness.clock.start(
        initialTick: 0,
        speed: 1,
        tempoMap: [TempoPoint(tick: 0, bpm: 60)],
      );

      harness.time.advance(const Duration(milliseconds: 500));
      harness.scheduler.runNext();

      expect(values, hasLength(2));
      expect(harness.scheduler.activeTasks, 1);
      expect(harness.scheduler.nextDeadlineUs, greaterThan(500000));
      await subscription.cancel();
    });

    test('rejects invalid speed and tempo map before scheduling', () async {
      final harness = _ClockHarness();

      await expectLater(
        harness.clock.start(
          initialTick: 0,
          speed: 0.49,
          tempoMap: [TempoPoint(tick: 0, bpm: 60)],
        ),
        throwsRangeError,
      );
      await expectLater(
        harness.clock.start(
          initialTick: 0,
          speed: 1,
          tempoMap: const [],
        ),
        throwsArgumentError,
      );
      expect(harness.scheduler.activeTasks, 0);
    });

    test('maps scheduler failures to lessonClockFailure', () async {
      final harness = _ClockHarness()..scheduler.scheduleError = StateError('x');

      await expectLater(
        harness.clock.start(
          initialTick: 0,
          speed: 1,
          tempoMap: [TempoPoint(tick: 0, bpm: 60)],
        ),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.lessonClockFailure,
          ),
        ),
      );
      expect(harness.scheduler.activeTasks, 0);
    });
  });
}

final class _ClockHarness {
  _ClockHarness()
      : time = _FakeMonotonicTimeSource(),
        scheduler = _FakeLessonClockScheduler() {
    scheduler.time = time;
    clock = MonotonicLessonClock(timeSource: time, scheduler: scheduler);
  }

  final _FakeMonotonicTimeSource time;
  final _FakeLessonClockScheduler scheduler;
  late final MonotonicLessonClock clock;

  void advance(Duration duration) {
    time.advance(duration);
    scheduler.runNext();
  }
}

final class _FakeMonotonicTimeSource implements MonotonicTimeSource {
  int currentUs = 0;

  @override
  int nowMicroseconds() => currentUs;

  void advance(Duration duration) => currentUs += duration.inMicroseconds;
}

final class _FakeLessonClockScheduler implements LessonClockScheduler {
  late _FakeMonotonicTimeSource time;
  final List<_FakeScheduledTask> _tasks = [];
  Object? scheduleError;

  int get activeTasks => _tasks.where((task) => !task.cancelled).length;

  int? get nextDeadlineUs {
    final active = _tasks.where((task) => !task.cancelled).toList()
      ..sort((left, right) => left.deadlineUs.compareTo(right.deadlineUs));
    return active.isEmpty ? null : active.first.deadlineUs;
  }

  @override
  LessonClockScheduledTask schedule(
    Duration delay,
    void Function() callback,
  ) {
    if (scheduleError case final error?) {
      throw error;
    }
    final task = _FakeScheduledTask(
      deadlineUs: time.currentUs + delay.inMicroseconds,
      callback: callback,
    );
    _tasks.add(task);
    return task;
  }

  void runNext() {
    final active = _tasks.where((task) => !task.cancelled).toList()
      ..sort((left, right) => left.deadlineUs.compareTo(right.deadlineUs));
    if (active.isEmpty) {
      return;
    }
    final task = active.first;
    task.cancelled = true;
    task.callback();
  }
}

final class _FakeScheduledTask implements LessonClockScheduledTask {
  _FakeScheduledTask({required this.deadlineUs, required this.callback});

  final int deadlineUs;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}
