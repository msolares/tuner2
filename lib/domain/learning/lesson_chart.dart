import 'package:equatable/equatable.dart';

import 'lesson_errors.dart';

const int lessonTicksPerQuarter = 960;

void _requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'No puede estar vacio.');
  }
}

void _requireMidi(int midi, String name) {
  if (midi < 0 || midi > 127) {
    throw RangeError.range(midi, 0, 127, name);
  }
}

bool _isSupportedChordPitchClasses(Set<int> pitchClasses) {
  if (pitchClasses.length == 2) {
    final values = pitchClasses.toList()..sort();
    final distance = (values[1] - values[0]) % 12;
    return distance == 5 || distance == 7;
  }
  if (pitchClasses.length != 3) {
    return false;
  }
  for (final root in pitchClasses) {
    final relative = pitchClasses.map((value) => (value - root) % 12).toSet();
    if (_setEquals(relative, const {0, 4, 7}) ||
        _setEquals(relative, const {0, 3, 7})) {
      return true;
    }
  }
  return false;
}

bool _setEquals<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}

final class LessonId extends Equatable {
  factory LessonId(String value) {
    _requireText(value, 'value');
    return LessonId._(value);
  }

  const LessonId._(this.value);

  final String value;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

final class FretPosition extends Equatable {
  factory FretPosition({required int stringNumber, required int fret}) {
    if (stringNumber < 1 || stringNumber > 6) {
      throw RangeError.range(stringNumber, 1, 6, 'stringNumber');
    }
    if (fret < 0 || fret > 24) {
      throw RangeError.range(fret, 0, 24, 'fret');
    }
    return FretPosition._(stringNumber, fret);
  }

  const FretPosition._(this.stringNumber, this.fret);

  final int stringNumber;
  final int fret;

  FretPosition copyWith({int? stringNumber, int? fret}) {
    return FretPosition(
      stringNumber: stringNumber ?? this.stringNumber,
      fret: fret ?? this.fret,
    );
  }

  @override
  List<Object> get props => [stringNumber, fret];
}

final class GuitarStringTuning extends Equatable {
  factory GuitarStringTuning({
    required int stringNumber,
    required int openMidi,
  }) {
    if (stringNumber < 1 || stringNumber > 6) {
      throw RangeError.range(stringNumber, 1, 6, 'stringNumber');
    }
    _requireMidi(openMidi, 'openMidi');
    return GuitarStringTuning._(stringNumber, openMidi);
  }

  const GuitarStringTuning._(this.stringNumber, this.openMidi);

  final int stringNumber;
  final int openMidi;

  GuitarStringTuning copyWith({int? stringNumber, int? openMidi}) {
    return GuitarStringTuning(
      stringNumber: stringNumber ?? this.stringNumber,
      openMidi: openMidi ?? this.openMidi,
    );
  }

  @override
  List<Object> get props => [stringNumber, openMidi];
}

final class GuitarTuningSpec extends Equatable {
  factory GuitarTuningSpec(List<GuitarStringTuning> strings) {
    if (strings.length != 6) {
      throw const LessonException(
        LessonErrorCode.invalidTuning,
        context: 'Se requieren exactamente seis cuerdas.',
      );
    }
    for (var index = 0; index < strings.length; index++) {
      if (strings[index].stringNumber != index + 1) {
        throw const LessonException(
          LessonErrorCode.invalidTuning,
          context: 'Las cuerdas deben estar ordenadas de 1 a 6.',
        );
      }
    }
    return GuitarTuningSpec._(List.unmodifiable(strings));
  }

  const GuitarTuningSpec._(this.strings);

  final List<GuitarStringTuning> strings;

  int openMidiFor(int stringNumber) {
    if (stringNumber < 1 || stringNumber > 6) {
      throw RangeError.range(stringNumber, 1, 6, 'stringNumber');
    }
    return strings[stringNumber - 1].openMidi;
  }

  @override
  List<Object> get props => [strings];
}

final class TempoPoint extends Equatable {
  factory TempoPoint({required int tick, required double bpm}) {
    if (tick < 0) {
      throw RangeError.value(tick, 'tick', 'Debe ser no negativo.');
    }
    if (!bpm.isFinite || bpm < 20 || bpm > 300) {
      throw RangeError.range(bpm, 20, 300, 'bpm');
    }
    return TempoPoint._(tick, bpm);
  }

  const TempoPoint._(this.tick, this.bpm);

  final int tick;
  final double bpm;

  TempoPoint copyWith({int? tick, double? bpm}) {
    return TempoPoint(tick: tick ?? this.tick, bpm: bpm ?? this.bpm);
  }

  @override
  List<Object> get props => [tick, bpm];
}

final class MeterPoint extends Equatable {
  factory MeterPoint({
    required int tick,
    required int numerator,
    required int denominator,
  }) {
    if (tick < 0) {
      throw RangeError.value(tick, 'tick', 'Debe ser no negativo.');
    }
    if (numerator < 1 || numerator > 32) {
      throw RangeError.range(numerator, 1, 32, 'numerator');
    }
    if (!supportedDenominators.contains(denominator)) {
      throw ArgumentError.value(denominator, 'denominator');
    }
    return MeterPoint._(tick, numerator, denominator);
  }

  const MeterPoint._(this.tick, this.numerator, this.denominator);

  static const Set<int> supportedDenominators = {1, 2, 4, 8, 16, 32};

  final int tick;
  final int numerator;
  final int denominator;

  MeterPoint copyWith({int? tick, int? numerator, int? denominator}) {
    return MeterPoint(
      tick: tick ?? this.tick,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
    );
  }

  @override
  List<Object> get props => [tick, numerator, denominator];
}

enum GuitarTechnique {
  hammerOn,
  slide,
  bend,
  harmonic,
  upStroke,
  downStroke,
}

sealed class LessonEvent extends Equatable {
  const LessonEvent({
    required this.id,
    required this.startTick,
    required this.durationTicks,
    required this.required,
  });

  final String id;
  final int startTick;
  final int durationTicks;
  final bool required;

  int get endTick => startTick + durationTicks;
}

final class LessonNoteEvent extends LessonEvent {
  factory LessonNoteEvent({
    required String id,
    required int startTick,
    required int durationTicks,
    required bool required,
    required FretPosition position,
    required int midi,
    Set<GuitarTechnique> techniques = const {},
  }) {
    _validateEventFields(id, startTick, durationTicks);
    _requireMidi(midi, 'midi');
    return LessonNoteEvent._(
      id: id,
      startTick: startTick,
      durationTicks: durationTicks,
      required: required,
      position: position,
      midi: midi,
      techniques: Set.unmodifiable(techniques),
    );
  }

  const LessonNoteEvent._({
    required super.id,
    required super.startTick,
    required super.durationTicks,
    required super.required,
    required this.position,
    required this.midi,
    required this.techniques,
  });

  final FretPosition position;
  final int midi;
  final Set<GuitarTechnique> techniques;

  LessonNoteEvent copyWith({
    String? id,
    int? startTick,
    int? durationTicks,
    bool? required,
    FretPosition? position,
    int? midi,
    Set<GuitarTechnique>? techniques,
  }) {
    return LessonNoteEvent(
      id: id ?? this.id,
      startTick: startTick ?? this.startTick,
      durationTicks: durationTicks ?? this.durationTicks,
      required: required ?? this.required,
      position: position ?? this.position,
      midi: midi ?? this.midi,
      techniques: techniques ?? this.techniques,
    );
  }

  @override
  List<Object> get props => [
        id,
        startTick,
        durationTicks,
        required,
        position,
        midi,
        techniques,
      ];
}

final class ChordToneTarget extends Equatable {
  factory ChordToneTarget({
    required FretPosition position,
    required int midi,
  }) {
    _requireMidi(midi, 'midi');
    return ChordToneTarget._(position, midi);
  }

  const ChordToneTarget._(this.position, this.midi);

  final FretPosition position;
  final int midi;

  ChordToneTarget copyWith({FretPosition? position, int? midi}) {
    return ChordToneTarget(
      position: position ?? this.position,
      midi: midi ?? this.midi,
    );
  }

  @override
  List<Object> get props => [position, midi];
}

final class LessonChordEvent extends LessonEvent {
  factory LessonChordEvent({
    required String id,
    required int startTick,
    required int durationTicks,
    required bool required,
    required String symbol,
    required List<ChordToneTarget> tones,
    required Set<int> mutedStrings,
    Set<GuitarTechnique> techniques = const {},
  }) {
    _validateEventFields(id, startTick, durationTicks);
    _requireText(symbol, 'symbol');
    if (tones.length < 2 || tones.length > 6) {
      throw const LessonException(LessonErrorCode.unsupportedChord);
    }
    final playedStrings =
        tones.map((tone) => tone.position.stringNumber).toSet();
    if (playedStrings.length != tones.length) {
      throw const LessonException(
        LessonErrorCode.unsupportedChord,
        context: 'Un acorde no puede repetir cuerda.',
      );
    }
    if (mutedStrings.any((value) => value < 1 || value > 6)) {
      throw RangeError('mutedStrings debe contener cuerdas 1..6.');
    }
    final expectedMuted = {1, 2, 3, 4, 5, 6}.difference(playedStrings);
    if (!_setEquals(mutedStrings, expectedMuted)) {
      throw const LessonException(
        LessonErrorCode.unsupportedChord,
        context: 'Las cuerdas silenciadas deben completar el voicing.',
      );
    }
    final pitchClasses = tones.map((tone) => tone.midi % 12).toSet();
    if (!_isSupportedChordPitchClasses(pitchClasses)) {
      throw const LessonException(LessonErrorCode.unsupportedChord);
    }
    return LessonChordEvent._(
      id: id,
      startTick: startTick,
      durationTicks: durationTicks,
      required: required,
      symbol: symbol,
      tones: List.unmodifiable(tones),
      mutedStrings: Set.unmodifiable(mutedStrings),
      techniques: Set.unmodifiable(techniques),
    );
  }

  const LessonChordEvent._({
    required super.id,
    required super.startTick,
    required super.durationTicks,
    required super.required,
    required this.symbol,
    required this.tones,
    required this.mutedStrings,
    required this.techniques,
  });

  final String symbol;
  final List<ChordToneTarget> tones;
  final Set<int> mutedStrings;
  final Set<GuitarTechnique> techniques;

  Set<int> get requiredPitchClasses =>
      Set.unmodifiable(tones.map((tone) => tone.midi % 12));

  LessonChordEvent copyWith({
    String? id,
    int? startTick,
    int? durationTicks,
    bool? required,
    String? symbol,
    List<ChordToneTarget>? tones,
    Set<int>? mutedStrings,
    Set<GuitarTechnique>? techniques,
  }) {
    return LessonChordEvent(
      id: id ?? this.id,
      startTick: startTick ?? this.startTick,
      durationTicks: durationTicks ?? this.durationTicks,
      required: required ?? this.required,
      symbol: symbol ?? this.symbol,
      tones: tones ?? this.tones,
      mutedStrings: mutedStrings ?? this.mutedStrings,
      techniques: techniques ?? this.techniques,
    );
  }

  @override
  List<Object> get props => [
        id,
        startTick,
        durationTicks,
        required,
        symbol,
        tones,
        mutedStrings,
        techniques,
      ];
}

void _validateEventFields(String id, int startTick, int durationTicks) {
  _requireText(id, 'id');
  if (startTick < 0) {
    throw RangeError.value(startTick, 'startTick', 'Debe ser no negativo.');
  }
  if (durationTicks <= 0) {
    throw RangeError.value(
        durationTicks, 'durationTicks', 'Debe ser positivo.');
  }
}

final class LessonSection extends Equatable {
  factory LessonSection({
    required String id,
    required String title,
    required int startTick,
    required int endTick,
  }) {
    _requireText(id, 'id');
    _requireText(title, 'title');
    if (startTick < 0) {
      throw RangeError.value(startTick, 'startTick');
    }
    if (endTick <= startTick) {
      throw RangeError('endTick debe ser mayor que startTick.');
    }
    return LessonSection._(id, title, startTick, endTick);
  }

  const LessonSection._(this.id, this.title, this.startTick, this.endTick);

  final String id;
  final String title;
  final int startTick;
  final int endTick;

  LessonSection copyWith({
    String? id,
    String? title,
    int? startTick,
    int? endTick,
  }) {
    return LessonSection(
      id: id ?? this.id,
      title: title ?? this.title,
      startTick: startTick ?? this.startTick,
      endTick: endTick ?? this.endTick,
    );
  }

  @override
  List<Object> get props => [id, title, startTick, endTick];
}

final class LessonChart extends Equatable {
  factory LessonChart({
    required int schemaVersion,
    required LessonId id,
    required String title,
    required GuitarTuningSpec tuning,
    required List<TempoPoint> tempoMap,
    required List<MeterPoint> meterMap,
    required List<LessonSection> sections,
    required List<LessonEvent> events,
    required int totalTicks,
  }) {
    if (schemaVersion != 1) {
      throw const LessonException(
        LessonErrorCode.sessionInvariantViolation,
        context: 'schemaVersion debe ser 1.',
      );
    }
    _requireText(title, 'title');
    if (totalTicks <= 0) {
      throw RangeError.value(totalTicks, 'totalTicks', 'Debe ser positivo.');
    }
    _validatePointMap(tempoMap.map((point) => point.tick), 'tempoMap');
    _validatePointMap(meterMap.map((point) => point.tick), 'meterMap');
    _validateSections(sections, totalTicks);
    _validateEvents(events, totalTicks, tuning);
    return LessonChart._(
      schemaVersion,
      id,
      title,
      tuning,
      List.unmodifiable(tempoMap),
      List.unmodifiable(meterMap),
      List.unmodifiable(sections),
      List.unmodifiable(events),
      totalTicks,
    );
  }

  const LessonChart._(
    this.schemaVersion,
    this.id,
    this.title,
    this.tuning,
    this.tempoMap,
    this.meterMap,
    this.sections,
    this.events,
    this.totalTicks,
  );

  final int schemaVersion;
  final LessonId id;
  final String title;
  final GuitarTuningSpec tuning;
  final List<TempoPoint> tempoMap;
  final List<MeterPoint> meterMap;
  final List<LessonSection> sections;
  final List<LessonEvent> events;
  final int totalTicks;

  LessonChart copyWith({
    int? schemaVersion,
    LessonId? id,
    String? title,
    GuitarTuningSpec? tuning,
    List<TempoPoint>? tempoMap,
    List<MeterPoint>? meterMap,
    List<LessonSection>? sections,
    List<LessonEvent>? events,
    int? totalTicks,
  }) {
    return LessonChart(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      title: title ?? this.title,
      tuning: tuning ?? this.tuning,
      tempoMap: tempoMap ?? this.tempoMap,
      meterMap: meterMap ?? this.meterMap,
      sections: sections ?? this.sections,
      events: events ?? this.events,
      totalTicks: totalTicks ?? this.totalTicks,
    );
  }

  @override
  List<Object> get props => [
        schemaVersion,
        id,
        title,
        tuning,
        tempoMap,
        meterMap,
        sections,
        events,
        totalTicks,
      ];
}

void _validatePointMap(Iterable<int> ticks, String name) {
  final values = ticks.toList();
  if (values.isEmpty || values.first != 0) {
    throw LessonException(
      LessonErrorCode.sessionInvariantViolation,
      context: '$name debe comenzar en tick 0.',
    );
  }
  for (var index = 1; index < values.length; index++) {
    if (values[index] <= values[index - 1]) {
      throw LessonException(
        LessonErrorCode.sessionInvariantViolation,
        context: '$name debe estar estrictamente ordenado.',
      );
    }
  }
}

void _validateSections(List<LessonSection> sections, int totalTicks) {
  final ids = <String>{};
  var previousTick = -1;
  for (final section in sections) {
    if (!ids.add(section.id) || section.startTick < previousTick) {
      throw const LessonException(LessonErrorCode.sessionInvariantViolation);
    }
    if (section.endTick > totalTicks) {
      throw const LessonException(LessonErrorCode.sessionInvariantViolation);
    }
    previousTick = section.startTick;
  }
}

void _validateEvents(
  List<LessonEvent> events,
  int totalTicks,
  GuitarTuningSpec tuning,
) {
  final ids = <String>{};
  var previousTick = -1;
  for (final event in events) {
    if (!ids.add(event.id) || event.startTick < previousTick) {
      throw const LessonException(LessonErrorCode.sessionInvariantViolation);
    }
    if (event.endTick > totalTicks) {
      throw const LessonException(LessonErrorCode.sessionInvariantViolation);
    }
    final tones = event is LessonNoteEvent
        ? [ChordToneTarget(position: event.position, midi: event.midi)]
        : (event as LessonChordEvent).tones;
    for (final tone in tones) {
      final expected =
          tuning.openMidiFor(tone.position.stringNumber) + tone.position.fret;
      if (expected != tone.midi) {
        throw const LessonException(
          LessonErrorCode.inconsistentPitchAndFret,
        );
      }
    }
    previousTick = event.startTick;
  }
}
