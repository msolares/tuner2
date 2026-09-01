import 'package:afinador/data/learning/musicxml/musicxml_document.dart';
import 'package:afinador/domain/learning/learning.dart';

enum MusicXmlImportDiagnosticCode {
  graceNoteIgnored,
  measureDurationNormalized,
}

final class MusicXmlImportDiagnostic {
  const MusicXmlImportDiagnostic({
    required this.code,
    required this.measureNumber,
  });

  final MusicXmlImportDiagnosticCode code;
  final String measureNumber;
}

final class MusicXmlNormalizationResult {
  MusicXmlNormalizationResult({
    required this.chart,
    required List<MusicXmlImportDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final LessonChart chart;
  final List<MusicXmlImportDiagnostic> diagnostics;
}

final class MusicXmlTimelineNormalizer {
  LessonChart normalize(
    MusicXmlScoreData score,
    LessonDocument document,
    LessonImportOptions options,
  ) =>
      normalizeWithDiagnostics(score, document, options).chart;

  MusicXmlNormalizationResult normalizeWithDiagnostics(
    MusicXmlScoreData score,
    LessonDocument document,
    LessonImportOptions options,
  ) {
    try {
      final contexts = _measureContexts(score.measures);
      final sequence = _expandNavigation(score.measures);
      final tempoMap = <TempoPoint>[];
      final meterMap = <MeterPoint>[];
      final groups = <_EventGroup>[];
      final activeTies = <_ToneKey, _ToneBuilder>{};
      final occurrences = <int, int>{};
      final diagnostics = <MusicXmlImportDiagnostic>[];
      final diagnosticKeys = <String>{};
      GuitarTuningSpec? chartTuning;
      var totalTicks = 0;
      int? previousSourceIndex;

      for (final sourceIndex in sequence) {
        if (previousSourceIndex != null &&
            sourceIndex != previousSourceIndex + 1 &&
            activeTies.isNotEmpty) {
          throw _error(
            LessonErrorCode.invalidLessonDocument,
            'A tie cannot cross a repeat jump',
          );
        }
        final occurrence = (occurrences[sourceIndex] ?? 0) + 1;
        occurrences[sourceIndex] = occurrence;
        final result = _appendMeasure(
          measure: score.measures[sourceIndex],
          context: contexts[sourceIndex],
          sourceIndex: sourceIndex,
          occurrence: occurrence,
          baseTick: totalTicks,
          tempoMap: tempoMap,
          meterMap: meterMap,
          groups: groups,
          activeTies: activeTies,
          chartTuning: chartTuning,
          diagnostics: diagnostics,
          diagnosticKeys: diagnosticKeys,
        );
        chartTuning ??= result.tuning;
        totalTicks += result.durationTicks;
        previousSourceIndex = sourceIndex;
      }

      if (activeTies.isNotEmpty) {
        throw _error(
          LessonErrorCode.invalidLessonDocument,
          'A tie start has no matching stop',
        );
      }
      if (chartTuning == null || tempoMap.isEmpty || meterMap.isEmpty) {
        throw _error(
          LessonErrorCode.invalidLessonDocument,
          'Tuning, tempo and meter must be defined from the chart start',
        );
      }

      final events = groups
          .where((group) => group.tones.isNotEmpty)
          .map((group) => group.toEvent())
          .toList()
        ..sort((left, right) {
          final tickOrder = left.startTick.compareTo(right.startTick);
          return tickOrder != 0 ? tickOrder : left.id.compareTo(right.id);
        });
      final title = options.sectionTitle ?? score.partName;
      return MusicXmlNormalizationResult(
        chart: LessonChart(
          schemaVersion: 1,
          id: document.id,
          title: title,
          tuning: chartTuning,
          tempoMap: tempoMap,
          meterMap: meterMap,
          sections: [
            LessonSection(
              id: 'section-1',
              title: title,
              startTick: 0,
              endTick: totalTicks,
            ),
          ],
          events: events,
          totalTicks: totalTicks,
        ),
        diagnostics: diagnostics,
      );
    } on LessonException {
      rethrow;
    } on ArgumentError catch (error) {
      throw _error(LessonErrorCode.invalidLessonDocument, error.toString());
    }
  }

  List<_MeasureContext> _measureContexts(
    List<MusicXmlMeasureData> measures,
  ) {
    final contexts = <_MeasureContext>[];
    var divisions = 0;
    MusicXmlMeterData? meter;
    MusicXmlTuningData? tuning;
    var capo = 0;
    var tempo = 0.0;
    for (final measure in measures) {
      contexts.add(
        _MeasureContext(
          divisions: divisions,
          meter: meter,
          tuning: tuning,
          capo: capo,
          tempo: tempo,
        ),
      );
      for (final item in measure.items) {
        if (item case MusicXmlAttributesData attributes) {
          divisions = attributes.divisions ?? divisions;
          meter = attributes.meter ?? meter;
          tuning = attributes.tuning ?? tuning;
          capo = attributes.capo ?? capo;
        } else if (item case MusicXmlDirectionData direction) {
          tempo = direction.tempo;
        }
      }
    }
    return contexts;
  }

  _MeasureResult _appendMeasure({
    required MusicXmlMeasureData measure,
    required _MeasureContext context,
    required int sourceIndex,
    required int occurrence,
    required int baseTick,
    required List<TempoPoint> tempoMap,
    required List<MeterPoint> meterMap,
    required List<_EventGroup> groups,
    required Map<_ToneKey, _ToneBuilder> activeTies,
    required GuitarTuningSpec? chartTuning,
    required List<MusicXmlImportDiagnostic> diagnostics,
    required Set<String> diagnosticKeys,
  }) {
    var divisions = context.divisions;
    var meter = context.meter;
    var tuning = context.tuning;
    var capo = context.capo;
    var tempo = context.tempo;
    var streamCursor = 0;
    var maximumCursor = 0;
    final voiceCursors = <String, int>{};
    final lastAttackByVoice = <String, int>{};
    final pendingTieStopByVoice = <String, ({int tick, _ToneBuilder tone})>{};
    var localEventIndex = 0;

    if (meter != null) {
      _addMeter(meterMap, baseTick, meter);
    }
    if (tempo > 0) {
      _addTempo(tempoMap, baseTick, tempo);
    }

    for (final item in measure.items) {
      switch (item) {
        case MusicXmlAttributesData attributes:
          divisions = attributes.divisions ?? divisions;
          meter = attributes.meter ?? meter;
          tuning = attributes.tuning ?? tuning;
          capo = attributes.capo ?? capo;
          if (attributes.meter != null) {
            _addMeter(meterMap, baseTick + streamCursor, meter!);
          }
        case MusicXmlDirectionData direction:
          tempo = direction.tempo;
          _addTempo(tempoMap, baseTick + streamCursor, tempo);
        case MusicXmlBackupData backup:
          final ticks = _durationTicks(backup.duration, divisions);
          streamCursor -= ticks;
          if (streamCursor < 0) {
            throw _error(
              LessonErrorCode.invalidLessonDocument,
              'backup moves before the start of measure ${measure.number}',
            );
          }
        case MusicXmlForwardData forward:
          final ticks = _durationTicks(forward.duration, divisions);
          streamCursor += ticks;
          if (forward.voice != null) {
            voiceCursors[forward.voice!] = streamCursor;
          }
          maximumCursor = _max(maximumCursor, streamCursor);
        case MusicXmlSkippedNoteData skipped:
          if (!skipped.isGrace && !skipped.isChordMember) {
            streamCursor += _durationTicks(skipped.duration!, divisions);
            maximumCursor = _max(maximumCursor, streamCursor);
          }
        case MusicXmlNoteData note:
          if (note.isGrace) {
            _addDiagnostic(
              diagnostics,
              diagnosticKeys,
              sourceIndex,
              measure.number,
              MusicXmlImportDiagnosticCode.graceNoteIgnored,
              occurrenceKey: localEventIndex++,
            );
            continue;
          }
          final duration = _durationTicks(note.duration!, divisions);
          final start =
              note.isChordMember ? lastAttackByVoice[note.voice] : streamCursor;
          if (start == null) {
            throw _error(
              LessonErrorCode.invalidLessonDocument,
              'A chord member has no preceding attack in voice ${note.voice}',
            );
          }
          if (!note.isChordMember) {
            lastAttackByVoice[note.voice] = start;
            streamCursor += duration;
            voiceCursors[note.voice] = streamCursor;
            maximumCursor = _max(maximumCursor, streamCursor);
          } else {
            maximumCursor = _max(maximumCursor, start + duration);
          }
          if (note.isRest) {
            continue;
          }
          if (tuning == null) {
            throw _error(
              LessonErrorCode.invalidTuning,
              'Tuning is missing before the first TAB note',
            );
          }
          final effectiveTuning = _effectiveTuning(tuning, capo);
          if (chartTuning != null && chartTuning != effectiveTuning) {
            throw _error(
              LessonErrorCode.invalidTuning,
              'Tuning or capo changes are not representable in LessonChart',
            );
          }
          final absoluteStart = baseTick + start;
          final key = _ToneKey(note.stringNumber!, note.midi!);
          final existing = activeTies[key];
          if (note.tieStop) {
            if (existing == null) {
              throw _error(
                LessonErrorCode.invalidLessonDocument,
                'A tie stop has no matching start',
              );
            }
            existing.durationTicks =
                absoluteStart + duration - existing.startTick;
            existing.techniques.addAll(_techniques(note.techniques));
            pendingTieStopByVoice[note.voice] = (
              tick: absoluteStart,
              tone: existing,
            );
            if (!note.tieStart) {
              activeTies.remove(key);
            }
            continue;
          }

          final tiedChordBase = note.isChordMember
              ? pendingTieStopByVoice.remove(note.voice)
              : null;
          if (!note.isChordMember) {
            pendingTieStopByVoice.remove(note.voice);
          }
          final preferredGroup = tiedChordBase?.tick == absoluteStart
              ? tiedChordBase!.tone.group
              : null;
          final toneStart = preferredGroup?.startTick ?? absoluteStart;
          final tone = _ToneBuilder(
            position: FretPosition(
              stringNumber: note.stringNumber!,
              fret: note.fret!,
            ),
            midi: effectiveTuning.openMidiFor(note.stringNumber!) + note.fret!,
            startTick: toneStart,
            durationTicks: absoluteStart + duration - toneStart,
            techniques: _techniques(note.techniques),
          );
          var group = preferredGroup ??
              groups.reversed.cast<_EventGroup?>().firstWhere(
                    (candidate) => candidate!.startTick == absoluteStart,
                    orElse: () => null,
                  );
          if (group == null) {
            localEventIndex++;
            group = _EventGroup(
              id: 'm${sourceIndex + 1}e${localEventIndex}i$occurrence',
              startTick: absoluteStart,
            );
            groups.add(group);
          }
          group.tones.add(tone);
          tone.group = group;
          if (note.tieStart) {
            activeTies[key] = tone;
          }
        case MusicXmlBarlineData():
          break;
      }
    }

    if (divisions <= 0 || meter == null || tuning == null || tempo <= 0) {
      throw _error(
        LessonErrorCode.invalidLessonDocument,
        'Measure ${measure.number} lacks divisions, meter, tuning or tempo',
      );
    }
    final nominalDuration = _meterTicks(meter);
    final difference = (nominalDuration - maximumCursor).abs();
    if (difference > 120) {
      throw _error(
        LessonErrorCode.invalidLessonDocument,
        'Measure ${measure.number} differs from its meter by $difference ticks',
      );
    }
    if (difference > 0) {
      _addDiagnostic(
        diagnostics,
        diagnosticKeys,
        sourceIndex,
        measure.number,
        MusicXmlImportDiagnosticCode.measureDurationNormalized,
      );
    }
    return _MeasureResult(
      durationTicks: nominalDuration,
      tuning: _effectiveTuning(tuning, capo),
    );
  }

  List<int> _expandNavigation(List<MusicXmlMeasureData> measures) {
    final endings = _endingMembership(measures);
    final regions = <_RepeatRegion>[];
    int? openStart;
    for (var index = 0; index < measures.length; index++) {
      final bars = measures[index].items.whereType<MusicXmlBarlineData>();
      for (final bar in bars) {
        if (bar.repeatDirection == 'forward') {
          if (openStart != null) {
            throw _error(
              LessonErrorCode.unsupportedNavigation,
              'Nested repeats are not supported',
            );
          }
          openStart = index;
        } else if (bar.repeatDirection == 'backward') {
          final start = openStart ?? 0;
          if (regions.any((region) => start <= region.end)) {
            throw _error(
              LessonErrorCode.unsupportedNavigation,
              'Nested or overlapping repeats are not supported',
            );
          }
          var extendedEnd = index;
          while (extendedEnd + 1 < measures.length &&
              endings[extendedEnd + 1] == 2) {
            extendedEnd++;
          }
          final times = bar.repeatTimes ?? 2;
          if (times > 2 &&
              endings
                  .sublist(start, extendedEnd + 1)
                  .any((value) => value != null)) {
            throw _error(
              LessonErrorCode.unsupportedNavigation,
              'Endings 1/2 cannot be combined with more than two passes',
            );
          }
          regions.add(
            _RepeatRegion(
              start: start,
              end: index,
              extendedEnd: extendedEnd,
              times: times,
            ),
          );
          openStart = null;
        }
      }
    }
    if (openStart != null) {
      throw _error(
        LessonErrorCode.unsupportedNavigation,
        'A forward repeat has no backward repeat',
      );
    }

    final output = <int>[];
    final iterations = <_RepeatRegion, int>{};
    var index = 0;
    while (index < measures.length) {
      _RepeatRegion? region;
      for (final candidate in regions) {
        if (index >= candidate.start && index <= candidate.extendedEnd) {
          region = candidate;
          break;
        }
      }
      final iteration = region == null ? 1 : (iterations[region] ?? 1);
      final ending = endings[index];
      if (ending == null || ending == iteration) {
        output.add(index);
      }
      if (region != null && index == region.end && iteration < region.times) {
        iterations[region] = iteration + 1;
        index = region.start;
      } else {
        if (region != null && index == region.extendedEnd) {
          iterations.remove(region);
        }
        index++;
      }
    }
    return output;
  }

  List<int?> _endingMembership(List<MusicXmlMeasureData> measures) {
    final result = List<int?>.filled(measures.length, null);
    int? active;
    for (var index = 0; index < measures.length; index++) {
      final bars = measures[index].items.whereType<MusicXmlBarlineData>();
      for (final bar in bars.where((bar) => bar.location == 'left')) {
        active = _applyEndingStart(active, bar);
      }
      result[index] = active;
      for (final bar in bars.where((bar) => bar.location != 'left')) {
        active = _applyEndingStart(active, bar);
        result[index] ??= active;
      }
      for (final bar in bars) {
        if (bar.endingNumber != null &&
            bar.endingType != 'start' &&
            bar.endingType != 'stop' &&
            bar.endingType != 'discontinue') {
          throw _error(
            LessonErrorCode.unsupportedNavigation,
            'Unsupported ending type ${bar.endingType}',
          );
        }
        if (bar.endingType == 'stop' || bar.endingType == 'discontinue') {
          active = null;
        }
      }
    }
    if (active != null) {
      throw _error(
        LessonErrorCode.unsupportedNavigation,
        'An ending has no stop or discontinue marker',
      );
    }
    return result;
  }

  int? _applyEndingStart(int? active, MusicXmlBarlineData bar) {
    if (bar.endingType != 'start') return active;
    if (active != null) {
      throw _error(
        LessonErrorCode.unsupportedNavigation,
        'Nested endings are not supported',
      );
    }
    return bar.endingNumber;
  }

  int _durationTicks(int duration, int divisions) {
    if (divisions <= 0) {
      throw _error(
        LessonErrorCode.invalidLessonDocument,
        'divisions must be defined before temporal content',
      );
    }
    final numerator = duration * lessonTicksPerQuarter;
    if (numerator % divisions != 0) {
      throw _error(
        LessonErrorCode.unsupportedRhythmResolution,
        '$duration divisions cannot be represented at 960 PPQ',
      );
    }
    return numerator ~/ divisions;
  }

  int _meterTicks(MusicXmlMeterData meter) {
    if (!MeterPoint.supportedDenominators.contains(meter.beatType) ||
        meter.beats < 1 ||
        meter.beats > 32) {
      throw _error(
        LessonErrorCode.invalidLessonDocument,
        'Unsupported meter ${meter.beats}/${meter.beatType}',
      );
    }
    return meter.beats * lessonTicksPerQuarter * 4 ~/ meter.beatType;
  }

  GuitarTuningSpec _effectiveTuning(MusicXmlTuningData tuning, int capo) {
    return GuitarTuningSpec([
      for (var stringNumber = 1; stringNumber <= 6; stringNumber++)
        GuitarStringTuning(
          stringNumber: stringNumber,
          openMidi: (tuning.openMidiByString[stringNumber] ??
                  (throw _error(
                    LessonErrorCode.invalidTuning,
                    'Missing tuning for string $stringNumber',
                  ))) +
              capo,
        ),
    ]);
  }

  Set<GuitarTechnique> _techniques(Set<String> values) => {
        if (values.contains('hammer-on')) GuitarTechnique.hammerOn,
        if (values.contains('slide')) GuitarTechnique.slide,
        if (values.contains('bend')) GuitarTechnique.bend,
        if (values.contains('harmonic')) GuitarTechnique.harmonic,
        if (values.contains('up-bow')) GuitarTechnique.upStroke,
        if (values.contains('down-bow')) GuitarTechnique.downStroke,
      };

  void _addTempo(List<TempoPoint> points, int tick, double bpm) {
    if (!bpm.isFinite || bpm < 20 || bpm > 300) {
      throw _error(
        LessonErrorCode.invalidLessonDocument,
        'Tempo $bpm is outside 20..300 BPM',
      );
    }
    if (points.isNotEmpty && points.last.tick == tick) {
      points[points.length - 1] = TempoPoint(tick: tick, bpm: bpm);
    } else if (points.isEmpty || points.last.bpm != bpm) {
      points.add(TempoPoint(tick: tick, bpm: bpm));
    }
  }

  void _addMeter(
    List<MeterPoint> points,
    int tick,
    MusicXmlMeterData meter,
  ) {
    final point = MeterPoint(
      tick: tick,
      numerator: meter.beats,
      denominator: meter.beatType,
    );
    if (points.isNotEmpty && points.last.tick == tick) {
      points[points.length - 1] = point;
    } else if (points.isEmpty ||
        points.last.numerator != point.numerator ||
        points.last.denominator != point.denominator) {
      points.add(point);
    }
  }

  int _max(int left, int right) => left > right ? left : right;

  void _addDiagnostic(
    List<MusicXmlImportDiagnostic> diagnostics,
    Set<String> keys,
    int sourceIndex,
    String measureNumber,
    MusicXmlImportDiagnosticCode code, {
    int? occurrenceKey,
  }) {
    final key = '$sourceIndex:${code.name}:${occurrenceKey ?? ''}';
    if (keys.add(key)) {
      diagnostics.add(
        MusicXmlImportDiagnostic(
          code: code,
          measureNumber: measureNumber,
        ),
      );
    }
  }

  LessonException _error(LessonErrorCode code, String context) =>
      LessonException(code, context: context);
}

final class _MeasureContext {
  const _MeasureContext({
    required this.divisions,
    required this.meter,
    required this.tuning,
    required this.capo,
    required this.tempo,
  });

  final int divisions;
  final MusicXmlMeterData? meter;
  final MusicXmlTuningData? tuning;
  final int capo;
  final double tempo;
}

final class _MeasureResult {
  const _MeasureResult({required this.durationTicks, required this.tuning});

  final int durationTicks;
  final GuitarTuningSpec tuning;
}

final class _RepeatRegion {
  const _RepeatRegion({
    required this.start,
    required this.end,
    required this.extendedEnd,
    required this.times,
  });

  final int start;
  final int end;
  final int extendedEnd;
  final int times;
}

final class _ToneKey {
  const _ToneKey(this.stringNumber, this.writtenMidi);

  final int stringNumber;
  final int writtenMidi;

  @override
  bool operator ==(Object other) =>
      other is _ToneKey &&
      other.stringNumber == stringNumber &&
      other.writtenMidi == writtenMidi;

  @override
  int get hashCode => Object.hash(stringNumber, writtenMidi);
}

final class _ToneBuilder {
  _ToneBuilder({
    required this.position,
    required this.midi,
    required this.startTick,
    required this.durationTicks,
    required Set<GuitarTechnique> techniques,
  }) : techniques = Set.of(techniques);

  final FretPosition position;
  final int midi;
  final int startTick;
  int durationTicks;
  final Set<GuitarTechnique> techniques;
  late _EventGroup group;
}

final class _EventGroup {
  _EventGroup({required this.id, required this.startTick});

  final String id;
  final int startTick;
  final List<_ToneBuilder> tones = [];

  LessonEvent toEvent() {
    final duration = tones
        .map((tone) => tone.durationTicks)
        .reduce((left, right) => left > right ? left : right);
    final techniques = tones.expand((tone) => tone.techniques).toSet();
    if (tones.length == 1) {
      final tone = tones.single;
      return LessonNoteEvent(
        id: id,
        startTick: startTick,
        durationTicks: duration,
        required: true,
        position: tone.position,
        midi: tone.midi,
        techniques: techniques,
      );
    }
    final targets = tones
        .map(
          (tone) => ChordToneTarget(
            position: tone.position,
            midi: tone.midi,
          ),
        )
        .toList();
    final playedStrings =
        targets.map((tone) => tone.position.stringNumber).toSet();
    return LessonChordEvent(
      id: id,
      startTick: startTick,
      durationTicks: duration,
      required: true,
      symbol: _chordSymbol(targets.map((tone) => tone.midi % 12).toSet()),
      tones: targets,
      mutedStrings: {1, 2, 3, 4, 5, 6}.difference(playedStrings),
      techniques: techniques,
    );
  }

  String _chordSymbol(Set<int> pitchClasses) {
    const names = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    for (final root in pitchClasses) {
      final relative = pitchClasses.map((value) => (value - root) % 12).toSet();
      if (_same(relative, const {0, 7}) || _same(relative, const {0, 5})) {
        return '${names[root]}5';
      }
      if (_same(relative, const {0, 4, 7})) return names[root];
      if (_same(relative, const {0, 3, 7})) return '${names[root]}m';
    }
    throw const LessonException(LessonErrorCode.unsupportedChord);
  }

  bool _same(Set<int> left, Set<int> right) =>
      left.length == right.length && left.containsAll(right);
}
