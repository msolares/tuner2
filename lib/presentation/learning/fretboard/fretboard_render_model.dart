import 'dart:collection';

import 'package:equatable/equatable.dart';

const int fretboardStringCount = 6;
const int maxFretboardVisibleBlocks = 40;

enum FretboardVisualStatus {
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

final class FretboardRenderBlock extends Equatable {
  FretboardRenderBlock({
    required String id,
    required String eventId,
    required int stringNumber,
    required int fret,
    required int midi,
    required String noteLabel,
    required String semanticLabel,
    required double startDepth,
    required double endDepth,
    required bool isTarget,
    required bool isChordTone,
    required bool isPast,
    String? chordSymbol,
  })  : id = _requireText(id, 'id'),
        eventId = _requireText(eventId, 'eventId'),
        stringNumber = _requireRange(
          stringNumber,
          1,
          fretboardStringCount,
          'stringNumber',
        ),
        fret = _requireRange(fret, 0, 24, 'fret'),
        midi = _requireRange(midi, 0, 127, 'midi'),
        noteLabel = _requireText(noteLabel, 'noteLabel'),
        semanticLabel = _requireText(semanticLabel, 'semanticLabel'),
        startDepth = _requireDepth(startDepth, 'startDepth'),
        endDepth = _requireDepth(endDepth, 'endDepth'),
        isTarget = isTarget,
        isChordTone = isChordTone,
        isPast = isPast,
        chordSymbol = chordSymbol == null
            ? null
            : _requireText(chordSymbol, 'chordSymbol') {
    if (endDepth < startDepth) {
      throw ArgumentError('endDepth debe ser >= startDepth.');
    }
  }

  final String id;
  final String eventId;
  final int stringNumber;
  final int fret;
  final int midi;
  final String noteLabel;
  final String semanticLabel;
  final double startDepth;
  final double endDepth;
  final bool isTarget;
  final bool isChordTone;
  final bool isPast;
  final String? chordSymbol;

  @override
  List<Object?> get props => [
        id,
        eventId,
        stringNumber,
        fret,
        midi,
        noteLabel,
        semanticLabel,
        startDepth,
        endDepth,
        isTarget,
        isChordTone,
        isPast,
        chordSymbol,
      ];
}

final class FretboardRenderModel extends Equatable {
  FretboardRenderModel({
    required double positionTicks,
    required int windowStartTick,
    required int windowEndTick,
    required FretboardVisualStatus status,
    required List<FretboardRenderBlock> blocks,
    required String instruction,
    required String semanticSummary,
    String? currentTargetId,
  })  : positionTicks = _requireFinite(positionTicks, 'positionTicks'),
        windowStartTick = windowStartTick,
        windowEndTick = windowEndTick,
        status = status,
        blocks = UnmodifiableListView(List.of(blocks)),
        instruction = _requireText(instruction, 'instruction'),
        semanticSummary = _requireText(semanticSummary, 'semanticSummary'),
        currentTargetId = currentTargetId == null
            ? null
            : _requireText(currentTargetId, 'currentTargetId') {
    if (windowEndTick < windowStartTick) {
      throw RangeError('windowEndTick debe ser >= windowStartTick.');
    }
    if (blocks.length > maxFretboardVisibleBlocks) {
      throw RangeError.range(
        blocks.length,
        0,
        maxFretboardVisibleBlocks,
        'blocks.length',
      );
    }
  }

  final double positionTicks;
  final int windowStartTick;
  final int windowEndTick;
  final FretboardVisualStatus status;
  final List<FretboardRenderBlock> blocks;
  final String instruction;
  final String semanticSummary;
  final String? currentTargetId;

  static const List<int> stringOrder = [6, 5, 4, 3, 2, 1];

  bool get isWaiting =>
      status == FretboardVisualStatus.waitingForTarget ||
      status == FretboardVisualStatus.validating;

  @override
  List<Object?> get props => [
        positionTicks,
        windowStartTick,
        windowEndTick,
        status,
        blocks,
        instruction,
        semanticSummary,
        currentTargetId,
      ];
}

String _requireText(String value, String name) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, name);
  return value;
}

int _requireRange(int value, int min, int max, String name) {
  if (value < min || value > max) {
    throw RangeError.range(value, min, max, name);
  }
  return value;
}

double _requireDepth(double value, String name) {
  _requireFinite(value, name);
  if (value < -1 || value > 1) {
    throw RangeError.range(value, -1, 1, name);
  }
  return value;
}

double _requireFinite(double value, String name) {
  if (!value.isFinite) throw ArgumentError.value(value, name);
  return value;
}
