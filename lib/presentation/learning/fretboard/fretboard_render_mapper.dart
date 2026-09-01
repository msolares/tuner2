import 'dart:math' as math;

import '../../../domain/learning/learning.dart';
import 'fretboard_render_model.dart';

final class FretboardRenderMapper {
  const FretboardRenderMapper();

  FretboardRenderModel call(
    LessonViewportSlice slice, {
    FretboardRenderStrings strings = FretboardRenderStrings.spanish,
  }) {
    final candidates = slice.visibleEvents
        .map(
          (event) => _EventCandidate(
            event: event,
            blockCount: event is LessonChordEvent ? event.tones.length : 1,
            isTarget: event.id == slice.currentTargetId,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) {
        if (left.isTarget != right.isTarget) return left.isTarget ? -1 : 1;
        final leftDistance = (left.event.startTick - slice.positionTicks).abs();
        final rightDistance =
            (right.event.startTick - slice.positionTicks).abs();
        final distanceOrder = leftDistance.compareTo(rightDistance);
        if (distanceOrder != 0) return distanceOrder;
        return left.event.startTick.compareTo(right.event.startTick);
      });

    final selected = <FretboardRenderBlock>[];
    for (final candidate in candidates) {
      if (selected.length + candidate.blockCount > maxFretboardVisibleBlocks) {
        continue;
      }
      selected.addAll(_mapEvent(candidate.event, slice, strings));
    }
    selected.sort((left, right) {
      final depthOrder = right.startDepth.compareTo(left.startDepth);
      if (depthOrder != 0) return depthOrder;
      return right.stringNumber.compareTo(left.stringNumber);
    });

    final target = _findTarget(slice);
    final instruction = strings.instructionFor(slice.status, target);
    final semantics = StringBuffer('$instruction. ${strings.sixStrings}.');
    for (final block in selected) {
      semantics.write(' ${block.semanticLabel}.');
    }

    return FretboardRenderModel(
      positionTicks: slice.positionTicks,
      windowStartTick: slice.windowStartTick,
      windowEndTick: slice.windowEndTick,
      status: _mapStatus(slice.status),
      blocks: selected,
      instruction: instruction,
      semanticSummary: semantics.toString(),
      currentTargetId: slice.currentTargetId,
    );
  }

  List<FretboardRenderBlock> _mapEvent(
    LessonEvent event,
    LessonViewportSlice slice,
    FretboardRenderStrings strings,
  ) {
    final isTarget = event.id == slice.currentTargetId;
    final startDepth = _depthFor(event.startTick, slice);
    final endDepth = _depthFor(event.endTick, slice);
    final isPast = event.endTick <= slice.positionTicks && !isTarget;
    return switch (event) {
      LessonNoteEvent note => [
          _mapTone(
            id: note.id,
            eventId: note.id,
            position: note.position,
            midi: note.midi,
            startDepth: startDepth,
            endDepth: endDepth,
            isTarget: isTarget,
            isChordTone: false,
            isPast: isPast,
            strings: strings,
          ),
        ],
      LessonChordEvent chord => [
          for (final tone in chord.tones)
            _mapTone(
              id: '${chord.id}-string-${tone.position.stringNumber}',
              eventId: chord.id,
              position: tone.position,
              midi: tone.midi,
              startDepth: startDepth,
              endDepth: endDepth,
              isTarget: isTarget,
              isChordTone: true,
              isPast: isPast,
              chordSymbol: chord.symbol,
              strings: strings,
            ),
        ],
    };
  }

  FretboardRenderBlock _mapTone({
    required String id,
    required String eventId,
    required FretPosition position,
    required int midi,
    required double startDepth,
    required double endDepth,
    required bool isTarget,
    required bool isChordTone,
    required bool isPast,
    required FretboardRenderStrings strings,
    String? chordSymbol,
  }) {
    return FretboardRenderBlock(
      id: id,
      eventId: eventId,
      stringNumber: position.stringNumber,
      fret: position.fret,
      midi: midi,
      noteLabel: strings.noteLabel(midi),
      semanticLabel: strings.blockSemantics(
        stringNumber: position.stringNumber,
        fret: position.fret,
        noteLabel: strings.noteLabel(midi),
        isTarget: isTarget,
        chordSymbol: chordSymbol,
      ),
      startDepth: startDepth,
      endDepth: endDepth,
      isTarget: isTarget,
      isChordTone: isChordTone,
      isPast: isPast,
      chordSymbol: chordSymbol,
    );
  }

  double _depthFor(int tick, LessonViewportSlice slice) {
    final distance = tick - slice.positionTicks;
    if (distance >= 0) {
      final span = math.max(1.0, slice.windowEndTick - slice.positionTicks);
      return (distance / span).clamp(0.0, 1.0).toDouble();
    }
    final span = math.max(1.0, slice.positionTicks - slice.windowStartTick);
    return (distance / span).clamp(-1.0, 0.0).toDouble();
  }

  LessonEvent? _findTarget(LessonViewportSlice slice) {
    final id = slice.currentTargetId;
    if (id == null) return null;
    for (final event in slice.visibleEvents) {
      if (event.id == id) return event;
    }
    return null;
  }
}

final class FretboardRenderStrings {
  const FretboardRenderStrings({
    required this.idle,
    required this.ready,
    required this.countIn,
    required this.running,
    required this.waitingForNote,
    required this.waitingForChord,
    required this.validating,
    required this.success,
    required this.reentry,
    required this.paused,
    required this.completed,
    required this.failure,
    required this.sixStrings,
    required this.chord,
    required this.string,
    required this.fret,
    required this.note,
    required this.currentTarget,
    required this.pitchClassNames,
  }) : assert(pitchClassNames.length == 12);

  static const spanish = FretboardRenderStrings(
    idle: 'Selecciona una leccion',
    ready: 'Listo para practicar',
    countIn: 'Cuenta de entrada',
    running: 'Sigue el mastil',
    waitingForNote: 'Esperando nota',
    waitingForChord: 'Esperando acorde',
    validating: 'Validando sonido',
    success: 'Objetivo correcto',
    reentry: 'Reentrada: 1',
    paused: 'Pausa',
    completed: 'Leccion completada',
    failure: 'No se pudo continuar. Intentalo de nuevo',
    sixStrings: 'Seis cuerdas, de 6 a 1',
    chord: 'Acorde',
    string: 'Cuerda',
    fret: 'traste',
    note: 'nota',
    currentTarget: 'objetivo actual',
    pitchClassNames: <String>[
      'Do', 'Do sostenido', 'Re', 'Re sostenido', 'Mi', 'Fa',
      'Fa sostenido', 'Sol', 'Sol sostenido', 'La', 'La sostenido', 'Si',
    ],
  );

  final String idle;
  final String ready;
  final String countIn;
  final String running;
  final String waitingForNote;
  final String waitingForChord;
  final String validating;
  final String success;
  final String reentry;
  final String paused;
  final String completed;
  final String failure;
  final String sixStrings;
  final String chord;
  final String string;
  final String fret;
  final String note;
  final String currentTarget;
  final List<String> pitchClassNames;

  String instructionFor(LessonSessionStatus status, LessonEvent? target) {
    return switch (status) {
      LessonSessionStatus.idle => idle,
      LessonSessionStatus.ready => ready,
      LessonSessionStatus.countIn => countIn,
      LessonSessionStatus.running => running,
      LessonSessionStatus.waitingForTarget => target is LessonChordEvent
          ? '$waitingForChord ${target.symbol}'
          : waitingForNote,
      LessonSessionStatus.validating => validating,
      LessonSessionStatus.successFeedback => success,
      LessonSessionStatus.reentry => reentry,
      LessonSessionStatus.paused => paused,
      LessonSessionStatus.completed => completed,
      LessonSessionStatus.failure => failure,
    };
  }

  String noteLabel(int midi) {
    final octave = midi ~/ 12 - 1;
    return '${pitchClassNames[midi % 12]} $octave';
  }

  String blockSemantics({
    required int stringNumber,
    required int fret,
    required String noteLabel,
    required bool isTarget,
    String? chordSymbol,
  }) {
    final chordPrefix = chordSymbol == null ? '' : '$chord $chordSymbol, ';
    final targetSuffix = isTarget ? ', $currentTarget' : '';
    return '$chordPrefix$string $stringNumber, ${this.fret} $fret, '
        '$note $noteLabel$targetSuffix';
  }
}

final class _EventCandidate {
  const _EventCandidate({
    required this.event,
    required this.blockCount,
    required this.isTarget,
  });

  final LessonEvent event;
  final int blockCount;
  final bool isTarget;
}

FretboardVisualStatus _mapStatus(LessonSessionStatus status) {
  return switch (status) {
    LessonSessionStatus.idle => FretboardVisualStatus.idle,
    LessonSessionStatus.ready => FretboardVisualStatus.ready,
    LessonSessionStatus.countIn => FretboardVisualStatus.countIn,
    LessonSessionStatus.running => FretboardVisualStatus.running,
    LessonSessionStatus.waitingForTarget =>
      FretboardVisualStatus.waitingForTarget,
    LessonSessionStatus.validating => FretboardVisualStatus.validating,
    LessonSessionStatus.successFeedback =>
      FretboardVisualStatus.successFeedback,
    LessonSessionStatus.reentry => FretboardVisualStatus.reentry,
    LessonSessionStatus.paused => FretboardVisualStatus.paused,
    LessonSessionStatus.completed => FretboardVisualStatus.completed,
    LessonSessionStatus.failure => FretboardVisualStatus.failure,
  };
}
