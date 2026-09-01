import 'package:afinador/domain/learning/learning.dart';
import 'package:afinador/presentation/learning/fretboard/fretboard_render_mapper.dart';
import 'package:afinador/presentation/learning/fretboard/fretboard_render_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../domain/learning/learning_fixtures.dart';

void main() {
  const mapper = FretboardRenderMapper();

  group('FretboardRenderMapper', () {
    test('projects six countable strings with stable positions', () {
      final events = <LessonEvent>[
        for (var stringNumber = 6; stringNumber >= 1; stringNumber--)
          LessonNoteEvent(
            id: 'string-$stringNumber',
            startTick: (6 - stringNumber) * 100,
            durationTicks: 120,
            required: true,
            position: FretPosition(stringNumber: stringNumber, fret: 0),
            midi: standardGuitarTuning().openMidiFor(stringNumber),
          ),
      ];

      final model = mapper(_slice(events: events, windowEndTick: 1000));

      expect(model.blocks.map((block) => block.stringNumber).toSet(),
          {1, 2, 3, 4, 5, 6});
      expect(FretboardRenderModel.stringOrder, [6, 5, 4, 3, 2, 1]);
      expect(model.blocks.every((block) => block.noteLabel.isNotEmpty), isTrue);
    });

    test('keeps every chord tone aligned at exactly one depth', () {
      final chord = cMajorChord(id: 'target-chord', startTick: 960);
      final model = mapper(
        _slice(
          events: [chord],
          positionTicks: 0,
          windowEndTick: 3840,
          currentTargetId: chord.id,
          status: LessonSessionStatus.waitingForTarget,
        ),
      );

      expect(model.blocks, hasLength(3));
      expect(
          model.blocks.map((block) => block.startDepth).toSet(), hasLength(1));
      expect(model.blocks.every((block) => block.isChordTone), isTrue);
      expect(model.blocks.every((block) => block.isTarget), isTrue);
      expect(model.instruction, 'Esperando acorde C');
    });

    test('maps duration to block length without accumulating pixels', () {
      final note = a2Note(
        id: 'sustain',
        startTick: 100,
        durationTicks: 400,
      );
      final model = mapper(
        _slice(events: [note], positionTicks: 0, windowEndTick: 1000),
      );

      expect(model.blocks.single.startDepth, closeTo(0.1, 0.000001));
      expect(model.blocks.single.endDepth, closeTo(0.5, 0.000001));
    });

    test('caps a 1000-event fixture at 40 blocks and preserves target', () {
      final events = <LessonEvent>[
        for (var index = 0; index < 1000; index++)
          LessonNoteEvent(
            id: 'note-$index',
            startTick: index * 10,
            durationTicks: 10,
            required: true,
            position: FretPosition(
              stringNumber: 6 - index % 6,
              fret: 0,
            ),
            midi: standardGuitarTuning().openMidiFor(6 - index % 6),
          ),
      ];
      final model = mapper(
        _slice(
          events: events,
          positionTicks: 0,
          windowEndTick: 10000,
          currentTargetId: 'note-999',
        ),
      );

      expect(model.blocks.length, maxFretboardVisibleBlocks);
      expect(model.blocks.any((block) => block.eventId == 'note-999'), isTrue);
    });

    test('never splits a chord to fill the block budget', () {
      final notes = <LessonEvent>[
        for (var index = 0; index < 39; index++)
          a2Note(
            id: 'near-$index',
            startTick: index * 10,
            durationTicks: 10,
          ),
      ];
      final chord = cMajorChord(id: 'complete-chord', startTick: 500);
      final model = mapper(
        _slice(
          events: [...notes, chord],
          positionTicks: 0,
          windowEndTick: 1000,
        ),
      );
      final chordBlocks = model.blocks
          .where((block) => block.eventId == 'complete-chord')
          .toList();

      expect(chordBlocks, isEmpty);
      expect(model.blocks.length, 39);
    });

    test('render model defensively freezes its block collection', () {
      final model = mapper(_slice(events: [a2Note()]));

      expect(
        () => model.blocks.add(model.blocks.single),
        throwsUnsupportedError,
      );
    });

    test('maps every domain session status to explicit visual feedback', () {
      for (final status in LessonSessionStatus.values) {
        final model = mapper(_slice(events: [a2Note()], status: status));

        expect(model.status.name, status.name);
        expect(model.instruction, isNotEmpty);
        expect(model.semanticSummary, contains('Seis cuerdas'));
      }
    });
  });
}

LessonViewportSlice _slice({
  required List<LessonEvent> events,
  double positionTicks = 0,
  int windowStartTick = 0,
  int windowEndTick = 3840,
  String? currentTargetId,
  LessonSessionStatus status = LessonSessionStatus.running,
}) {
  return LessonViewportSlice(
    positionTicks: positionTicks,
    windowStartTick: windowStartTick,
    windowEndTick: windowEndTick,
    visibleEvents: events,
    currentTargetId: currentTargetId,
    status: status,
  );
}
