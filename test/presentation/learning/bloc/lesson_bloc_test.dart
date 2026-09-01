import 'dart:async';
import 'dart:io';

import 'package:afinador/domain/learning/learning.dart';
import 'package:afinador/presentation/learning/bloc/lesson_bloc.dart';
import 'package:afinador/presentation/learning/bloc/lesson_event.dart';
import 'package:afinador/presentation/learning/bloc/lesson_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../domain/learning/learning_fixtures.dart';

void main() {
  group('LessonBloc architecture', () {
    test('presentation learning bloc imports domain but never data', () {
      final directory = Directory('lib/presentation/learning/bloc');
      final sources = directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync());

      for (final source in sources) {
        expect(source, isNot(contains('/data/')));
        expect(source, isNot(contains('package:afinador/data/')));
        expect(source, isNot(contains('dart:ffi')));
        expect(source, isNot(contains('package:xml/')));
      }
    });
  });

  group('LessonBloc events', () {
    test('loads and prepares an immutable UI state from domain', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.bloc.add(
        LessonLoadRequested(
          lessonId: harness.chart.id,
          importOptions: LessonImportOptions(),
          speed: 0.75,
        ),
      );
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.ready,
      );

      expect(harness.bloc.state.session?.chart, harness.chart);
      expect(harness.bloc.state.session?.speed, 0.75);
      expect(harness.bloc.state.error, isNull);
      expect(harness.bloc.state.canStart, isTrue);
    });

    test('surfaces a typed load error without a partial session', () async {
      final harness = _Harness(loadError: LessonErrorCode.lessonNotFound);
      addTearDown(harness.dispose);

      harness.load();
      await _waitFor(
        harness.bloc,
        (state) => state.error?.code == LessonErrorCode.lessonNotFound,
      );

      expect(harness.bloc.state.session, isNull);
      expect(harness.bloc.state.isLoading, isFalse);
    });

    test('surfaces start failure and cancels both subscriptions', () async {
      final harness = _Harness(analyzerStartFails: true);
      addTearDown(harness.dispose);
      await harness.loadAndWait();

      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) =>
            state.error?.code == LessonErrorCode.audioPermissionDenied,
      );

      expect(harness.bloc.state.status, LessonSessionStatus.failure);
      expect(harness.clock.cancelCount, 1);
      expect(harness.analyzer.cancelCount, 1);
    });

    test('routes start, ticks and observations through domain', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.loadAndWait();

      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );
      expect(harness.clock.listenCount, 1);
      expect(harness.analyzer.listenCount, 1);

      harness.clock.emit(positionTicks: 0, timestampMs: 10);
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.waitingForTarget,
      );
      harness.analyzer.emit(_note(timestampMs: 20));
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.validating,
      );
      harness.analyzer.emit(_note(timestampMs: 120));
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.successFeedback,
      );

      expect(harness.bloc.state.session?.results, contains('note-first'));
    });

    test('exposes raw chord evidence and clears it when stopping', () async {
      final chord = cMajorChord(id: 'chord-first', startTick: 0);
      final harness = _Harness(
        chart: validLessonChart(events: [chord]),
      );
      addTearDown(harness.dispose);
      await harness.loadAndWait();

      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );
      harness.clock.emit(positionTicks: 0, timestampMs: 10);
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.waitingForTarget,
      );
      final observation = ChordPerformanceObservation(
        timestampMs: 20,
        onsetSequence: 1,
        confidence: .9,
        pitchClassStrengths: const [
          .8, 0, 0, 0, .7, 0, 0, .75, 0, 0, 0, 0,
        ],
        onsetConfidence: .9,
      );
      harness.analyzer.emit(observation);
      await _waitFor(
        harness.bloc,
        (state) => state.latestObservation == observation,
      );

      expect(harness.bloc.state.latestObservation, same(observation));
      harness.bloc.add(const LessonStopRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.ready,
      );
      expect(harness.bloc.state.latestObservation, isNull);
    });

    test('routes pause, resume and speed without calculating them', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.loadAndWait();
      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );

      harness.bloc.add(const LessonPauseRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.paused,
      );
      harness.bloc.add(const LessonSpeedChanged(0.85));
      await _waitFor(harness.bloc, (state) => state.session?.speed == 0.85);
      harness.bloc.add(const LessonResumeRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );

      expect(harness.clock.setSpeedCalls, [0.85]);
      expect(harness.clock.pauseCalls, greaterThanOrEqualTo(1));
      expect(harness.clock.resumeCalls, greaterThanOrEqualTo(1));
    });

    test('selects and repeats a section through domain use cases', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.loadAndWait();

      harness.bloc.add(const LessonSectionSelected('second'));
      await _waitFor(
        harness.bloc,
        (state) => state.session?.section.id == 'second',
      );
      expect(harness.bloc.state.status, LessonSessionStatus.ready);

      harness.bloc.add(const LessonSectionRepeated());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );
      expect(harness.analyzer.startCalls, 1);
      expect(harness.clock.startCalls, 1);
    });

    test('stop cancels every subscription and returns ready', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.loadAndWait();
      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );

      harness.bloc.add(const LessonStopRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.ready,
      );

      expect(harness.clock.cancelCount, 1);
      expect(harness.analyzer.cancelCount, 1);
      expect(harness.clock.stopCalls, 1);
      expect(harness.analyzer.stopCalls, 1);
    });

    test('background stops and foreground never restarts automatically',
        () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.loadAndWait();
      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );

      harness.bloc.add(const LessonBackgrounded());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.ready,
      );
      harness.bloc.add(const LessonForegrounded());
      harness.bloc.add(const LessonSpeedChanged(0.80));
      await _waitFor(harness.bloc, (state) => state.session?.speed == 0.80);

      expect(harness.analyzer.startCalls, 1);
      expect(harness.clock.cancelCount, 1);
      expect(harness.analyzer.cancelCount, 1);

      harness.bloc.add(const LessonStartRequested());
      await _waitFor(harness.bloc, (_) => harness.analyzer.startCalls == 2);
    });

    for (final failure in <({bool clock, LessonErrorCode code})>[
      (clock: true, code: LessonErrorCode.lessonClockFailure),
      (
        clock: false,
        code: LessonErrorCode.performanceAnalyzerUnavailable,
      ),
    ]) {
      test('${failure.clock ? 'clock' : 'analyzer'} stream error is typed '
          'and cancels both subscriptions', () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.loadAndWait();
        harness.bloc.add(const LessonStartRequested());
        await _waitFor(
          harness.bloc,
          (state) => state.status == LessonSessionStatus.countIn,
        );

        if (failure.clock) {
          harness.clock.fail();
        } else {
          harness.analyzer.fail();
        }
        await _waitFor(
          harness.bloc,
          (state) => state.error?.code == failure.code,
        );

        expect(harness.bloc.state.status, LessonSessionStatus.failure);
        expect(harness.clock.cancelCount, 1);
        expect(harness.analyzer.cancelCount, 1);
      });
    }

    test('invalid event input becomes a recoverable typed UI error', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.loadAndWait();

      harness.bloc.add(const LessonSpeedChanged(0.73));
      await _waitFor(
        harness.bloc,
        (state) =>
            state.error?.code == LessonErrorCode.sessionInvariantViolation,
      );

      expect(harness.bloc.state.status, LessonSessionStatus.ready);
    });

    test('dispose cancels subscriptions and performs idempotent stop', () async {
      final harness = _Harness();
      await harness.loadAndWait();
      harness.bloc.add(const LessonStartRequested());
      await _waitFor(
        harness.bloc,
        (state) => state.status == LessonSessionStatus.countIn,
      );

      await harness.bloc.close();

      expect(harness.clock.cancelCount, 1);
      expect(harness.analyzer.cancelCount, 1);
      expect(harness.clock.stopCalls, 1);
      expect(harness.analyzer.stopCalls, 1);
      await harness.closeStreams();
    });
  });
}

Future<void> _waitFor(
  LessonBloc bloc,
  bool Function(LessonBlocState state) predicate,
) async {
  if (predicate(bloc.state)) return;
  await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 2));
}

NotePerformanceObservation _note({required int timestampMs}) {
  return NotePerformanceObservation(
    timestampMs: timestampMs,
    onsetSequence: 1,
    confidence: 0.95,
    hz: 110,
    midi: 45,
    cents: 0,
  );
}

final class _Harness {
  _Harness({
    LessonErrorCode? loadError,
    bool analyzerStartFails = false,
    LessonChart? chart,
  })
      : chart = chart ?? _chart(),
        catalog = _FakeCatalog(loadError: loadError),
        analyzer = _TrackingAnalyzer(startFails: analyzerStartFails),
        clock = _TrackingClock() {
    decoder = _FakeDecoder(this.chart);
    bloc = LessonBloc(
      loadLesson: LoadLessonUseCase(catalog, decoder),
      prepareSession: const PrepareLessonSessionUseCase(),
      analyzer: analyzer,
      clock: clock,
    );
  }

  final LessonChart chart;
  final _FakeCatalog catalog;
  late final _FakeDecoder decoder;
  final _TrackingAnalyzer analyzer;
  final _TrackingClock clock;
  late final LessonBloc bloc;

  void load() {
    bloc.add(
      LessonLoadRequested(
        lessonId: chart.id,
        importOptions: LessonImportOptions(),
      ),
    );
  }

  Future<void> loadAndWait() async {
    load();
    await _waitFor(
      bloc,
      (state) => state.status == LessonSessionStatus.ready,
    );
  }

  Future<void> dispose() async {
    await bloc.close();
    await closeStreams();
  }

  Future<void> closeStreams() async {
    await clock.close();
    await analyzer.close();
  }
}

LessonChart _chart() {
  final first = a2Note(id: 'note-first', startTick: 0);
  final second = a2Note(id: 'note-second', startTick: 1920);
  return validLessonChart(
    events: [first, second],
    sections: [
      LessonSection(
        id: 'first',
        title: 'Primera',
        startTick: 0,
        endTick: 1920,
      ),
      LessonSection(
        id: 'second',
        title: 'Segunda',
        startTick: 1920,
        endTick: 3840,
      ),
    ],
  );
}

final class _FakeCatalog implements LessonCatalog {
  const _FakeCatalog({this.loadError});

  final LessonErrorCode? loadError;

  @override
  Future<LessonDocument> getById(LessonId id) async {
    if (loadError != null) throw LessonException(loadError!);
    return LessonDocument(id: id, sourceName: 'lesson.xml', bytes: const [1]);
  }

  @override
  Future<List<LessonSummary>> list() async => const [];
}

final class _FakeDecoder implements LessonChartDecoder {
  const _FakeDecoder(this.chart);

  final LessonChart chart;

  @override
  LessonChart decode(
    LessonDocument document,
    LessonImportOptions options,
  ) {
    return chart;
  }
}

final class _TrackingAnalyzer implements PerformanceAnalyzer {
  _TrackingAnalyzer({this.startFails = false}) {
    _controller = StreamController<PerformanceObservation>.broadcast(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  late final StreamController<PerformanceObservation> _controller;
  final bool startFails;
  int listenCount = 0;
  int cancelCount = 0;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<PerformanceObservation> observations() => _controller.stream;

  @override
  Future<void> setTarget(PerformanceTarget? target) async {}

  @override
  Future<void> start(PerformanceAnalyzerSettings settings) async {
    startCalls++;
    if (startFails) {
      throw const LessonException(LessonErrorCode.audioPermissionDenied);
    }
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  void emit(PerformanceObservation observation) => _controller.add(observation);

  void fail() => _controller.addError(StateError('analyzer failed'));

  Future<void> close() => _controller.close();
}

final class _TrackingClock implements LessonClock {
  _TrackingClock() {
    _controller = StreamController<LessonClockTick>.broadcast(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  late final StreamController<LessonClockTick> _controller;
  int listenCount = 0;
  int cancelCount = 0;
  int startCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int stopCalls = 0;
  final List<double> setSpeedCalls = [];

  @override
  Stream<LessonClockTick> ticks() => _controller.stream;

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
  }

  @override
  Future<void> seek(int tick) async {}

  @override
  Future<void> setSpeed(double speed) async {
    setSpeedCalls.add(speed);
  }

  @override
  Future<void> start({
    required int initialTick,
    required double speed,
    required List<TempoPoint> tempoMap,
  }) async {
    startCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  void emit({required double positionTicks, required int timestampMs}) {
    _controller.add(
      LessonClockTick(
        positionTicks: positionTicks,
        monotonicTimestampMs: timestampMs,
      ),
    );
  }

  void fail() => _controller.addError(StateError('clock failed'));

  Future<void> close() => _controller.close();
}
