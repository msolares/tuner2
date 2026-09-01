import 'dart:async';
import 'dart:io';

import 'package:afinador/app/app_localizations.dart';
import 'package:afinador/app/app_theme.dart';
import 'package:afinador/domain/learning/learning.dart';
import 'package:afinador/presentation/learning/bloc/lesson_bloc.dart';
import 'package:afinador/presentation/learning/bloc/lesson_state.dart';
import 'package:afinador/presentation/learning/screens/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../domain/learning/learning_fixtures.dart';

void main() {
  test('learning screen keeps data, XML and FFI outside presentation', () {
    final directory = Directory('lib/presentation/learning/screens');
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

  testWidgets('close requests stop before the screen is disposed',
      (tester) async {
    await _setViewport(tester, const Size(1024, 600));
    final chart = validLessonChart();
    final analyzer = _ScreenAnalyzer();
    final clock = _ScreenClock();
    final bloc = LessonBloc(
      loadLesson: LoadLessonUseCase(
        const _ScreenCatalog(),
        _ScreenDecoder(chart),
      ),
      prepareSession: const PrepareLessonSessionUseCase(),
      analyzer: analyzer,
      clock: clock,
    );
    addTearDown(() async {
      await bloc.close();
      await analyzer.close();
      await clock.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate],
        theme: AppTheme.theme(),
        home: BlocProvider.value(
          value: bloc,
          child: LessonScreen(lessonId: chart.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-primary-control')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cerrar lección'));
    await tester.pumpAndSettle();

    expect(clock.stopCalls, 1);
    expect(analyzer.stopCalls, 1);
    expect(bloc.state.status, LessonSessionStatus.ready);
  });

  group('LessonScreenView', () {
    for (final viewport in <Size>[
      const Size(640, 360),
      const Size(1024, 600),
      const Size(1440, 900),
    ]) {
      testWidgets(
        'lays out without overflow at ${viewport.width.toInt()}x'
        '${viewport.height.toInt()}',
        (tester) async {
          await _setViewport(tester, viewport);
          await tester.pumpWidget(_host(_state()));

          expect(find.byKey(const ValueKey('learning-fretboard-canvas')),
              findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('shows raw pitch-class evidence without deciding correctness',
        (tester) async {
      await _setViewport(tester, const Size(1024, 600));
      final observation = ChordPerformanceObservation(
        timestampMs: 20,
        onsetSequence: 1,
        confidence: .82,
        pitchClassStrengths: const [
          .63, 0, 0, 0, .51, 0, 0, .77, 0, 0, 0, 0,
        ],
        onsetConfidence: .9,
      );

      await tester.pumpWidget(
        _host(_state(latestObservation: observation)),
      );

      expect(find.byKey(const ValueKey('lesson-chord-diagram')), findsOneWidget);
      expect(find.text('63%'), findsOneWidget);
      expect(find.text('51%'), findsOneWidget);
      expect(find.text('77%'), findsOneWidget);
      expect(find.textContaining('correcto'), findsNothing);
    });

    testWidgets('routes primary, speed and repeat controls to callbacks',
        (tester) async {
      await _setViewport(tester, const Size(1024, 600));
      var starts = 0;
      var repeats = 0;
      double? speed;
      await tester.pumpWidget(
        _host(
          _state(status: LessonSessionStatus.ready),
          onStart: () => starts++,
          onRepeat: () => repeats++,
          onSpeedChanged: (value) => speed = value,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('lesson-primary-control')));
      await tester.tap(find.byTooltip('Aumentar velocidad'));
      await tester.tap(find.text('REPETIR SECCIÓN'));

      expect(starts, 1);
      expect(repeats, 1);
      expect(speed, .8);
    });

    testWidgets('uses English instructions and accessible controls',
        (tester) async {
      await _setViewport(tester, const Size(1024, 600));
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await tester.pumpWidget(_host(_state(), locale: const Locale('en')));

      expect(find.textContaining('WAITING FOR CHORD C'), findsOneWidget);
      expect(find.byTooltip('Close lesson'), findsOneWidget);
      expect(find.byTooltip('Increase speed'), findsOneWidget);
    });

    for (final status in <LessonSessionStatus>[
      LessonSessionStatus.running,
      LessonSessionStatus.waitingForTarget,
      LessonSessionStatus.validating,
      LessonSessionStatus.successFeedback,
      LessonSessionStatus.reentry,
      LessonSessionStatus.failure,
    ]) {
      testWidgets('renders explicit ${status.name} feedback', (tester) async {
        await _setViewport(tester, const Size(1024, 600));
        await tester.pumpWidget(_host(_state(status: status)));

        expect(find.byKey(const ValueKey('learning-fretboard-canvas')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('portrait requests rotation and does not render gameplay',
        (tester) async {
      await _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(_host(_state()));

      expect(find.textContaining('Gira el dispositivo'), findsOneWidget);
      expect(find.byKey(const ValueKey('learning-fretboard-canvas')),
          findsNothing);
    });

    for (final viewport in <Size>[
      const Size(640, 360),
      const Size(1024, 600),
      const Size(1440, 900),
    ]) {
      testWidgets(
        'golden waiting chord ${viewport.width.toInt()}x'
        '${viewport.height.toInt()}',
        (tester) async {
          await _setViewport(tester, viewport);
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('lesson-screen-golden'),
              child: _host(_state()),
            ),
          );

          await expectLater(
            find.byKey(const ValueKey('lesson-screen-golden')),
            matchesGoldenFile(
              'goldens/lesson_waiting_chord_'
              '${viewport.width.toInt()}x${viewport.height.toInt()}.png',
            ),
          );
        },
      );
    }
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(
  LessonBlocState state, {
  Locale locale = const Locale('es'),
  VoidCallback? onStart,
  VoidCallback? onRepeat,
  ValueChanged<double>? onSpeedChanged,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [AppLocalizations.delegate],
    theme: AppTheme.theme(),
    home: LessonScreenView(
      state: state,
      onClose: () {},
      onStart: onStart ?? () {},
      onStop: () {},
      onPause: () {},
      onResume: () {},
      onRepeat: onRepeat ?? () {},
      onSpeedChanged: onSpeedChanged ?? (_) {},
      onRetry: () {},
    ),
  );
}

LessonBlocState _state({
  LessonSessionStatus status = LessonSessionStatus.waitingForTarget,
  PerformanceObservation? latestObservation,
}) {
  final chord = cMajorChord(id: 'chord-first', startTick: 0);
  final note = a2Note(id: 'note-next', startTick: 1920);
  final chart = validLessonChart(events: [chord, note]);
  final session = LessonSessionState(
    chart: chart,
    section: chart.sections.first,
    status: status,
    positionTicks: 0,
    speed: .75,
    currentTarget: chord,
    results: const {},
    attempt: 1,
    waitStartedTimestampMs: status == LessonSessionStatus.waitingForTarget ||
            status == LessonSessionStatus.validating
        ? 10
        : null,
  );
  return LessonBlocState(
    isLoading: false,
    session: session,
    latestObservation: latestObservation,
  );
}

final class _ScreenCatalog implements LessonCatalog {
  const _ScreenCatalog();

  @override
  Future<LessonDocument> getById(LessonId id) async =>
      LessonDocument(id: id, sourceName: 'lesson.xml', bytes: const [1]);

  @override
  Future<List<LessonSummary>> list() async => const [];
}

final class _ScreenDecoder implements LessonChartDecoder {
  const _ScreenDecoder(this.chart);

  final LessonChart chart;

  @override
  LessonChart decode(LessonDocument document, LessonImportOptions options) =>
      chart;
}

final class _ScreenAnalyzer implements PerformanceAnalyzer {
  final StreamController<PerformanceObservation> _controller =
      StreamController<PerformanceObservation>.broadcast();
  int stopCalls = 0;

  @override
  Stream<PerformanceObservation> observations() => _controller.stream;

  @override
  Future<void> setTarget(PerformanceTarget? target) async {}

  @override
  Future<void> start(PerformanceAnalyzerSettings settings) async {}

  @override
  Future<void> stop() async => stopCalls++;

  Future<void> close() => _controller.close();
}

final class _ScreenClock implements LessonClock {
  final StreamController<LessonClockTick> _controller =
      StreamController<LessonClockTick>.broadcast();
  int stopCalls = 0;

  @override
  Stream<LessonClockTick> ticks() => _controller.stream;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(int tick) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> start({
    required int initialTick,
    required double speed,
    required List<TempoPoint> tempoMap,
  }) async {}

  @override
  Future<void> stop() async => stopCalls++;

  Future<void> close() => _controller.close();
}
