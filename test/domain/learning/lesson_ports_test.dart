import 'dart:async';

import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'learning_fixtures.dart';

void main() {
  test('content ports expose only domain models', () async {
    final catalog = _FakeCatalog();
    final decoder = _FakeDecoder();

    expect(await catalog.list(), hasLength(1));
    final document = await catalog.getById(LessonId('lesson'));
    expect(
      decoder.decode(document, LessonImportOptions()),
      validLessonChart(),
    );
  });

  test('runtime ports preserve the closed async and stream signatures',
      () async {
    final analyzer = _FakeAnalyzer();
    final clock = _FakeClock();

    await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
    await analyzer.setTarget(NotePerformanceTarget(eventId: 'a2', midi: 45));
    expect(
        await analyzer.observations().first, isA<NotePerformanceObservation>());
    await analyzer.stop();

    await clock.start(initialTick: -960, speed: 0.7);
    expect(await clock.ticks().first, isA<LessonClockTick>());
    await clock.pause();
    await clock.resume();
    await clock.seek(0);
    await clock.setSpeed(0.5);
    await clock.stop();
  });
}

final class _FakeCatalog implements LessonCatalog {
  @override
  Future<LessonDocument> getById(LessonId id) async {
    return LessonDocument(id: id, sourceName: 'lesson', bytes: const [1]);
  }

  @override
  Future<List<LessonSummary>> list() async {
    return [
      LessonSummary(
        id: LessonId('lesson'),
        title: 'Lesson',
        subtitle: 'First',
        sequenceIndex: 0,
        estimatedMinutes: 3,
        kind: LessonKind.exercise,
      ),
    ];
  }
}

final class _FakeDecoder implements LessonChartDecoder {
  @override
  LessonChart decode(
    LessonDocument document,
    LessonImportOptions options,
  ) {
    return validLessonChart();
  }
}

final class _FakeAnalyzer implements PerformanceAnalyzer {
  @override
  Stream<PerformanceObservation> observations() => Stream.value(
        NotePerformanceObservation(
          timestampMs: 1,
          onsetSequence: 1,
          confidence: 1,
          hz: 110,
          midi: 45,
          cents: 0,
        ),
      );

  @override
  Future<void> setTarget(PerformanceTarget? target) async {}

  @override
  Future<void> start(PerformanceAnalyzerSettings settings) async {}

  @override
  Future<void> stop() async {}
}

final class _FakeClock implements LessonClock {
  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(int tick) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> start({required int initialTick, required double speed}) async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<LessonClockTick> ticks() => Stream.value(
        LessonClockTick(positionTicks: 0, monotonicTimestampMs: 1),
      );
}
