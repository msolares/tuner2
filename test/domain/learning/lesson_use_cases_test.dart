import 'package:afinador/domain/learning/learning.dart';
import 'package:flutter_test/flutter_test.dart';

import 'learning_fixtures.dart';

void main() {
  group('UC-L00 listar clases', () {
    test('acepta vacio y devuelve una lista inmutable', () async {
      final result = await ListLessonsUseCase(_FakeCatalog()).call();

      expect(result, isEmpty);
      expect(() => result.add(_summary(0)), throwsUnsupportedError);
    });

    test('rechaza IDs, indices duplicados y desorden', () async {
      for (final lessons in [
        [_summary(0), _summary(1, id: 'lesson-0')],
        [_summary(0), _summary(0, id: 'lesson-1')],
        [_summary(1), _summary(0, id: 'lesson-1')],
      ]) {
        expect(
          () => ListLessonsUseCase(_FakeCatalog(lessons: lessons)).call(),
          throwsA(_lessonError(LessonErrorCode.invalidLessonCatalog)),
        );
      }
    });

    test('oculta el detalle de un fallo tecnico', () async {
      expect(
        () => ListLessonsUseCase(
          _FakeCatalog(listError: StateError('disk path')),
        ).call(),
        throwsA(_lessonError(LessonErrorCode.lessonCatalogUnavailable)),
      );
    });
  });

  test('UC-L01 carga documento y conserva errores tipados', () async {
    final document = LessonDocument(
      id: LessonId('lesson-0'),
      sourceName: 'fixture.musicxml',
      bytes: const [1],
    );
    final chart = validLessonChart();
    final decoder = _FakeDecoder(chart);

    final result = await LoadLessonUseCase(
      _FakeCatalog(document: document),
      decoder,
    ).call(document.id, options: LessonImportOptions());

    expect(result, chart);
    expect(decoder.document, document);
  });

  test('UC-L02 prepara seccion y primer objetivo', () {
    final note = a2Note(startTick: 960);
    final chart = validLessonChart(
      events: [note],
      sections: [
        LessonSection(
          id: 'part-a',
          title: 'Parte A',
          startTick: 480,
          endTick: 1920,
        ),
      ],
    );

    final state = const PrepareLessonSessionUseCase()(
      chart,
      sectionId: 'part-a',
      speed: 0.75,
    );

    expect(state.status, LessonSessionStatus.ready);
    expect(state.positionTicks, 480);
    expect(state.currentTarget, note);
    expect(state.results, isEmpty);
    expect(
      () => const PrepareLessonSessionUseCase()(chart, speed: 0.73),
      throwsArgumentError,
    );
  });

  test('UC-L02 usa el chart completo cuando no hay secciones', () {
    final chart = validLessonChart(sections: const []);

    final state = const PrepareLessonSessionUseCase()(chart);

    expect(state.section.startTick, 0);
    expect(state.section.endTick, chart.totalTicks);
  });

  group('UC-L03..UC-L06 sesion y evaluacion', () {
    test('cuenta un compas y se bloquea exactamente en el target', () async {
      final harness = _Harness();

      await harness.controller.start();
      expect(harness.clock.startedAt, -3840);
      expect(harness.controller.state.status, LessonSessionStatus.countIn);

      await harness.tick(-1, 90);
      expect(harness.controller.state.positionTicks, -1);
      await harness.tick(0, 100);

      expect(
        harness.controller.state.status,
        LessonSessionStatus.waitingForTarget,
      );
      expect(harness.controller.state.positionTicks, 0);
      expect(harness.clock.pauseCalls, 1);
    });

    test('observacion antigua, ruido y ataque consumido no desbloquean',
        () async {
      final first = a2Note(id: 'first');
      final second = a2Note(id: 'second', startTick: 960);
      final harness = _Harness(
        chart: validLessonChart(events: [first, second]),
      );
      await harness.startAtTarget(waitTimestamp: 100);

      await harness.note(timestamp: 100, onset: 1);
      await harness.note(timestamp: 101, onset: 1, confidence: 0.2);
      expect(harness.controller.state.results, isEmpty);
      await harness.note(timestamp: 101, onset: 1);
      await harness.note(timestamp: 201, onset: 1);
      expect(
          harness.controller.state.status, LessonSessionStatus.successFeedback);

      await harness.tick(0, 451);
      expect(harness.controller.state.status, LessonSessionStatus.reentry);
      await harness.tick(0, 452);
      await harness.tick(960, 500);
      expect(harness.controller.state.currentTarget, second);

      await harness.note(timestamp: 501, onset: 1);
      expect(harness.controller.state.status,
          LessonSessionStatus.waitingForTarget);
      await harness.note(timestamp: 501, onset: 2);
      await harness.note(timestamp: 601, onset: 2);
      expect(harness.controller.state.results.keys,
          containsAll(['first', 'second']));
    });

    test('reentrada conserva el resultado y no reevalua el target acertado',
        () async {
      final note = a2Note(startTick: 1920);
      final harness = _Harness(
        chart: validLessonChart(events: [note]),
        policy: LessonEvaluationPolicy.defaults.copyWith(reentryTicks: 960),
      );
      await harness.startAtTarget(waitTimestamp: 100, targetTick: 1920);
      await harness.note(timestamp: 101, onset: 1);
      await harness.note(timestamp: 201, onset: 1);
      await harness.tick(1920, 451);

      expect(harness.controller.state.status, LessonSessionStatus.reentry);
      expect(harness.controller.state.positionTicks, 960);
      expect(harness.controller.state.results, contains(note.id));

      await harness.tick(1920, 500);
      expect(harness.controller.state.status, LessonSessionStatus.running);
      expect(harness.controller.state.currentTarget, isNull);
    });

    test('acorde incompleto expira y uno completo acierta', () async {
      final chord = cMajorChord();
      final harness = _Harness(chart: validLessonChart(events: [chord]));
      await harness.startAtTarget(waitTimestamp: 100);

      await harness.chord(timestamp: 101, onset: 1, active: const {0, 4});
      await harness.chord(timestamp: 801, onset: 1, active: const {0, 4});
      expect(harness.controller.state.attempt, 2);
      expect(harness.controller.state.results, isEmpty);

      await harness.chord(
        timestamp: 802,
        onset: 2,
        active: const {0, 4, 7},
      );
      expect(
          harness.controller.state.status, LessonSessionStatus.successFeedback);
      expect(harness.controller.state.results, contains(chord.id));
    });

    test('ticks tardios no avanzan espera ni feedback', () async {
      final harness = _Harness();
      await harness.startAtTarget(waitTimestamp: 100);
      await harness.tick(700, 200);
      expect(harness.controller.state.positionTicks, 0);
      await harness.note(timestamp: 201, onset: 1);
      await harness.note(timestamp: 301, onset: 1);
      await harness.tick(700, 500);
      expect(
          harness.controller.state.status, LessonSessionStatus.successFeedback);
      expect(harness.controller.state.positionTicks, 0);
    });
  });

  group('UC-L07..UC-L09 controles y lifecycle', () {
    test('velocidad valida conserva tick y actualiza clock', () async {
      final harness = _Harness();
      await harness.startAtTarget(waitTimestamp: 100);

      await harness.controller.setSpeed(0.85);

      expect(harness.controller.state.speed, 0.85);
      expect(harness.controller.state.positionTicks, 0);
      expect(harness.clock.speeds, [0.85]);
      expect(
        () => harness.controller.setSpeed(0.83),
        throwsArgumentError,
      );
    });

    test('pausa y reanuda mediante cuenta completa', () async {
      final harness = _Harness();
      await harness.startAtTarget(waitTimestamp: 100);

      await harness.controller.pause();
      expect(harness.controller.state.status, LessonSessionStatus.paused);
      await harness.controller.resume();
      expect(harness.controller.state.status, LessonSessionStatus.countIn);
      expect(harness.clock.seeks.last, -3840);
      await harness.tick(0, 500);
      expect(
        harness.controller.state.status,
        LessonSessionStatus.waitingForTarget,
      );
    });

    test('repetir limpia resultados sin recrear recursos', () async {
      final harness = _Harness();
      await harness.startAtTarget(waitTimestamp: 100);
      await harness.note(timestamp: 101, onset: 1);
      await harness.note(timestamp: 201, onset: 1);
      expect(harness.controller.state.results, isNotEmpty);

      await harness.controller.repeatSection();

      expect(harness.controller.state.status, LessonSessionStatus.countIn);
      expect(harness.controller.state.results, isEmpty);
      expect(harness.analyzer.startCalls, 1);
      expect(harness.clock.startCalls, 1);
    });

    test('stop es idempotente y final natural libera recursos', () async {
      final emptyChart = validLessonChart(events: const []);
      final harness = _Harness(chart: emptyChart);
      await harness.controller.start();
      await harness.tick(0, 100);
      await harness.tick(emptyChart.totalTicks.toDouble(), 200);

      expect(harness.controller.state.status, LessonSessionStatus.completed);
      expect(harness.analyzer.stopCalls, 1);
      expect(harness.clock.stopCalls, 1);
      await harness.controller.stop(reason: LessonStopReason.naturalCompletion);
      expect(harness.analyzer.stopCalls, 1);
      expect(harness.clock.stopCalls, 1);
    });

    test('repetir tras completar reinicia analyzer y clock', () async {
      final harness = _Harness(chart: validLessonChart(events: const []));
      await harness.controller.start();
      await harness.tick(0, 100);
      await harness.tick(3840, 200);

      await harness.controller.repeatSection();

      expect(harness.controller.state.status, LessonSessionStatus.countIn);
      expect(harness.analyzer.startCalls, 2);
      expect(harness.clock.startCalls, 2);
    });

    test('preserva permiso denegado y traduce fallo tecnico de clock',
        () async {
      final state = const PrepareLessonSessionUseCase()(validLessonChart());
      final deniedController = LessonSessionController(
        initialState: state,
        policy: LessonEvaluationPolicy.defaults,
        analyzer: _FakeAnalyzer(
          startError: const LessonException(
            LessonErrorCode.audioPermissionDenied,
          ),
        ),
        clock: _FakeClock(),
      );
      await deniedController.start();
      expect(
        deniedController.state.error?.code,
        LessonErrorCode.audioPermissionDenied,
      );

      final analyzer = _FakeAnalyzer();
      final clockController = LessonSessionController(
        initialState: state,
        policy: LessonEvaluationPolicy.defaults,
        analyzer: analyzer,
        clock: _FakeClock(startError: StateError('timer')),
      );
      await clockController.start();
      expect(
        clockController.state.error?.code,
        LessonErrorCode.lessonClockFailure,
      );
      expect(analyzer.stopCalls, 1);
    });

    test('la limpieza intenta todos los puertos aunque uno falle', () async {
      final state = const PrepareLessonSessionUseCase()(validLessonChart());
      final analyzer = _FakeAnalyzer();
      final controller = LessonSessionController(
        initialState: state,
        policy: LessonEvaluationPolicy.defaults,
        analyzer: analyzer,
        clock: _FakeClock(stopError: StateError('clock stop')),
      );
      await controller.start();

      await controller.stop();

      expect(analyzer.stopCalls, 1);
      expect(controller.state.status, LessonSessionStatus.ready);
    });
  });

  test('UC-L10 filtra por ventana y no expone conceptos visuales', () {
    final first = a2Note(id: 'first');
    final second = a2Note(id: 'second', startTick: 1920);
    final state = const PrepareLessonSessionUseCase()(
      validLessonChart(events: [first, second]),
    );

    final slice = const GetLessonViewportSliceUseCase()(
      state,
      windowStartTick: 0,
      windowEndTick: 1000,
    );

    expect(slice.visibleEvents, [first]);
    expect(slice.currentTargetId, first.id);
    expect(() => slice.visibleEvents.add(second), throwsUnsupportedError);
  });
}

Matcher _lessonError(LessonErrorCode code) => isA<LessonException>().having(
      (error) => error.code,
      'code',
      code,
    );

LessonSummary _summary(int index, {String? id}) => LessonSummary(
      id: LessonId(id ?? 'lesson-$index'),
      title: 'Leccion $index',
      subtitle: 'Disponible',
      sequenceIndex: index,
      estimatedMinutes: 2,
      kind: LessonKind.exercise,
    );

final class _FakeCatalog implements LessonCatalog {
  _FakeCatalog({
    this.lessons = const [],
    this.document,
    this.listError,
  });

  final List<LessonSummary> lessons;
  final LessonDocument? document;
  final Object? listError;

  @override
  Future<LessonDocument> getById(LessonId id) async => document!;

  @override
  Future<List<LessonSummary>> list() async {
    if (listError != null) throw listError!;
    return lessons;
  }
}

final class _FakeDecoder implements LessonChartDecoder {
  _FakeDecoder(this.chart);

  final LessonChart chart;
  LessonDocument? document;

  @override
  LessonChart decode(LessonDocument document, LessonImportOptions options) {
    this.document = document;
    return chart;
  }
}

final class _FakeAnalyzer implements PerformanceAnalyzer {
  _FakeAnalyzer({this.startError});

  final targets = <PerformanceTarget?>[];
  final Object? startError;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<PerformanceObservation> observations() => const Stream.empty();

  @override
  Future<void> setTarget(PerformanceTarget? target) async {
    targets.add(target);
  }

  @override
  Future<void> start(PerformanceAnalyzerSettings settings) async {
    startCalls++;
    if (startError != null) throw startError!;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

final class _FakeClock implements LessonClock {
  _FakeClock({this.startError, this.stopError});

  final Object? startError;
  final Object? stopError;
  int? startedAt;
  int startCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  final seeks = <int>[];
  final speeds = <double>[];

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(int tick) async => seeks.add(tick);

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> start({required int initialTick, required double speed}) async {
    startCalls++;
    startedAt = initialTick;
    if (startError != null) throw startError!;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    if (stopError != null) throw stopError!;
  }

  @override
  Stream<LessonClockTick> ticks() => const Stream.empty();
}

final class _Harness {
  _Harness({
    LessonChart? chart,
    LessonEvaluationPolicy? policy,
  })  : analyzer = _FakeAnalyzer(),
        clock = _FakeClock() {
    final initialState = const PrepareLessonSessionUseCase()(
      chart ?? validLessonChart(),
    );
    controller = LessonSessionController(
      initialState: initialState,
      policy: policy ?? LessonEvaluationPolicy.defaults,
      analyzer: analyzer,
      clock: clock,
    );
  }

  final _FakeAnalyzer analyzer;
  final _FakeClock clock;
  late final LessonSessionController controller;

  Future<void> startAtTarget({
    required int waitTimestamp,
    int targetTick = 0,
  }) async {
    await controller.start();
    await tick(targetTick.toDouble(), waitTimestamp);
  }

  Future<void> tick(double position, int timestamp) => controller.processTick(
        LessonClockTick(
          positionTicks: position,
          monotonicTimestampMs: timestamp,
        ),
      );

  Future<void> note({
    required int timestamp,
    required int onset,
    double confidence = 0.9,
  }) =>
      controller.processObservation(
        NotePerformanceObservation(
          timestampMs: timestamp,
          onsetSequence: onset,
          confidence: confidence,
          hz: 110,
          midi: 45,
          cents: 0,
        ),
      );

  Future<void> chord({
    required int timestamp,
    required int onset,
    required Set<int> active,
  }) {
    final strengths = List<double>.filled(12, 0.05);
    for (final pitchClass in active) {
      strengths[pitchClass] = 0.9;
    }
    return controller.processObservation(
      ChordPerformanceObservation(
        timestampMs: timestamp,
        onsetSequence: onset,
        confidence: 0.9,
        pitchClassStrengths: strengths,
        onsetConfidence: 0.9,
      ),
    );
  }
}
