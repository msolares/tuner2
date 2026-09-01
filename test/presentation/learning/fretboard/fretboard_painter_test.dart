import 'dart:io';

import 'package:afinador/domain/learning/learning.dart';
import 'package:afinador/presentation/learning/fretboard/fretboard_painter.dart';
import 'package:afinador/presentation/learning/fretboard/fretboard_render_mapper.dart';
import 'package:afinador/presentation/learning/fretboard/fretboard_render_model.dart';
import 'package:afinador/presentation/learning/fretboard/learning_fretboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../domain/learning/learning_fixtures.dart';

void main() {
  group('FretboardPainter architecture and geometry', () {
    test('painter imports neither BLoC, data nor stream APIs', () {
      final source = File(
        'lib/presentation/learning/fretboard/fretboard_painter.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('/bloc/')));
      expect(source, isNot(contains('/data/')));
      expect(source, isNot(contains('Stream')));
      expect(source, isNot(contains('package:xml/')));
    });

    test('projects six distinct lanes from grave left to aguda right', () {
      const projection = FretboardProjection();
      const size = Size(844, 390);
      final points = [
        for (final stringNumber in FretboardRenderModel.stringOrder)
          projection.pointFor(size, stringNumber, 0),
      ];

      expect(points.map((point) => point.dx).toSet(), hasLength(6));
      for (var index = 1; index < points.length; index++) {
        expect(points[index].dx, greaterThan(points[index - 1].dx));
        expect(points[index].dy, points.first.dy);
      }
      expect(
        projection.laneSpacing(size, 1),
        lessThan(projection.laneSpacing(size, 0)),
      );
    });

    test('repaints only for model or decorative motion changes', () {
      final model = _model();
      final original = FretboardPainter(model: model);

      expect(
        FretboardPainter(model: model).shouldRepaint(original),
        isFalse,
      );
      expect(
        FretboardPainter(model: model, pulsePhase: 0.5).shouldRepaint(original),
        isTrue,
      );
    });
  });

  group('LearningFretboard widget', () {
    testWidgets('isolates canvas repaint and exposes one semantic summary',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      addTearDown(semanticsHandle.dispose);
      await tester.pumpWidget(_host(_model()));

      expect(
        find.byKey(const ValueKey('learning-fretboard-boundary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('learning-fretboard-canvas')),
        findsOneWidget,
      );
      expect(find.byType(Text), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(LearningFretboard));
      expect(semantics.label, contains('Esperando acorde C'));
      expect(semantics.label, contains('Cuerda 5, traste 3'));
    });

    testWidgets('vertical layout requests rotation and hides gameplay',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_host(_model()));

      expect(find.textContaining('Gira el dispositivo'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('learning-fretboard-canvas')),
        findsNothing,
      );
    });

    testWidgets('renders a textual cue for every visual state', (tester) async {
      for (final status in LessonSessionStatus.values) {
        final model = _model(status: status);
        await tester.pumpWidget(_host(model));

        expect(find.text(model.instruction.toUpperCase()), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    for (final viewport in <Size>[
      const Size(640, 360),
      const Size(844, 390),
      const Size(1024, 768),
      const Size(1440, 900),
    ]) {
      testWidgets(
        'golden chord alignment ${viewport.width.toInt()}x'
        '${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _host(
              _model(),
              goldenKey: const ValueKey('fretboard-golden'),
            ),
          );

          await expectLater(
            find.byKey(const ValueKey('fretboard-golden')),
            matchesGoldenFile(
              'goldens/fretboard_chord_'
              '${viewport.width.toInt()}x${viewport.height.toInt()}.png',
            ),
          );
        },
      );
    }
  });
}

Widget _host(FretboardRenderModel model, {Key? goldenKey}) {
  return MaterialApp(
    home: Scaffold(
      body: RepaintBoundary(
        key: goldenKey,
        child: LearningFretboard(
          model: model,
          reduceMotion: true,
        ),
      ),
    ),
  );
}

FretboardRenderModel _model({
  LessonSessionStatus status = LessonSessionStatus.waitingForTarget,
}) {
  final chord = cMajorChord(id: 'chord-target', startTick: 960);
  final future = a2Note(
    id: 'future-note',
    startTick: 2400,
    durationTicks: 480,
  );
  final slice = LessonViewportSlice(
    positionTicks: 960,
    windowStartTick: 0,
    windowEndTick: 3840,
    visibleEvents: [chord, future],
    currentTargetId: chord.id,
    status: status,
  );
  return const FretboardRenderMapper()(slice);
}
