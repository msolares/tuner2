import 'lesson_chart.dart';
import 'lesson_content.dart';
import 'lesson_errors.dart';
import 'lesson_ports.dart';
import 'lesson_session.dart';
import 'performance.dart';

final class ListLessonsUseCase {
  const ListLessonsUseCase(this._catalog);

  final LessonCatalog _catalog;

  Future<List<LessonSummary>> call() async {
    try {
      final lessons = await _catalog.list();
      final ids = <LessonId>{};
      final indices = <int>{};
      var previousIndex = -1;
      for (final lesson in lessons) {
        if (!ids.add(lesson.id) ||
            !indices.add(lesson.sequenceIndex) ||
            lesson.sequenceIndex <= previousIndex) {
          throw const LessonException(LessonErrorCode.invalidLessonCatalog);
        }
        previousIndex = lesson.sequenceIndex;
      }
      return List.unmodifiable(lessons);
    } on LessonException {
      rethrow;
    } catch (_) {
      throw const LessonException(LessonErrorCode.lessonCatalogUnavailable);
    }
  }
}

final class LoadLessonUseCase {
  const LoadLessonUseCase(this._catalog, this._decoder);

  final LessonCatalog _catalog;
  final LessonChartDecoder _decoder;

  Future<LessonChart> call(
    LessonId id, {
    required LessonImportOptions options,
  }) async {
    late final LessonDocument document;
    try {
      document = await _catalog.getById(id);
    } on LessonException {
      rethrow;
    } catch (_) {
      throw const LessonException(LessonErrorCode.lessonCatalogUnavailable);
    }
    try {
      return _decoder.decode(document, options);
    } on LessonException {
      rethrow;
    } catch (_) {
      throw const LessonException(LessonErrorCode.invalidLessonDocument);
    }
  }
}

final class PrepareLessonSessionUseCase {
  const PrepareLessonSessionUseCase();

  LessonSessionState call(
    LessonChart chart, {
    String? sectionId,
    double speed = lessonDefaultSpeed,
  }) {
    validateLessonSpeed(speed);
    final section = _selectSection(chart, sectionId);
    final firstTarget = _requiredEvents(chart, section).firstOrNull;
    return LessonSessionState(
      chart: chart,
      section: section,
      status: LessonSessionStatus.ready,
      positionTicks: section.startTick.toDouble(),
      speed: speed,
      currentTarget: firstTarget,
      results: const {},
      attempt: 1,
    );
  }
}

enum LessonStopReason { voluntary, naturalCompletion, failure }

final class LessonSessionController {
  LessonSessionController({
    required LessonSessionState initialState,
    required LessonEvaluationPolicy policy,
    required PerformanceAnalyzer analyzer,
    required LessonClock clock,
    PerformanceAnalyzerSettings? analyzerSettings,
  })  : _state = initialState,
        _policy = policy,
        _analyzer = analyzer,
        _clock = clock,
        _analyzerSettings =
            analyzerSettings ?? PerformanceAnalyzerSettings(a4Hz: 440);

  static const int successFeedbackMs = 250;

  LessonSessionState _state;
  final LessonEvaluationPolicy _policy;
  final PerformanceAnalyzer _analyzer;
  final LessonClock _clock;
  final PerformanceAnalyzerSettings _analyzerSettings;
  final Set<int> _consumedOnsets = {};

  bool _resourcesStarted = false;
  int? _countInEndTick;
  LessonSessionStatus? _countInResumeStatus;
  int? _noteStableFromMs;
  int? _noteOnsetSequence;
  int? _chordWindowStartMs;
  int? _chordOnsetSequence;
  List<double>? _chordMaxima;
  int? _reentryEndTick;

  LessonSessionState get state => _state;

  Future<LessonSessionState> start() async {
    if (_state.status != LessonSessionStatus.ready) return _state;
    try {
      await _analyzer.start(_analyzerSettings);
      _resourcesStarted = true;
      await _analyzer.setTarget(_targetFor(_state.currentTarget));
    } on LessonException catch (error) {
      await _enterFailure(error);
      return _state;
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.performanceAnalyzerUnavailable),
      );
      return _state;
    }
    try {
      final countInTicks = _countInTicksAt(
        _state.chart,
        _state.section.startTick,
      );
      final initialTick = _state.section.startTick - countInTicks;
      _countInEndTick = _state.section.startTick;
      _countInResumeStatus = LessonSessionStatus.running;
      await _clock.start(initialTick: initialTick, speed: _state.speed);
      _state = _state.copyWith(
        status: LessonSessionStatus.countIn,
        positionTicks: initialTick.toDouble(),
        error: null,
      );
    } on LessonException catch (error) {
      await _enterFailure(error);
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.lessonClockFailure),
      );
    }
    return _state;
  }

  Future<LessonSessionState> processTick(LessonClockTick tick) async {
    try {
      switch (_state.status) {
        case LessonSessionStatus.countIn:
          final endTick = _countInEndTick!;
          if (tick.positionTicks < endTick) {
            _state = _state.copyWith(positionTicks: tick.positionTicks);
            return _state;
          }
          final resumeStatus =
              _countInResumeStatus ?? LessonSessionStatus.running;
          _state = _state.copyWith(
            status: resumeStatus,
            positionTicks: endTick.toDouble(),
            resumeStatus: null,
          );
          if (resumeStatus == LessonSessionStatus.waitingForTarget ||
              resumeStatus == LessonSessionStatus.validating) {
            await _clock.pause();
            _state = _state.copyWith(
              status: LessonSessionStatus.waitingForTarget,
              waitStartedTimestampMs: tick.monotonicTimestampMs,
            );
            return _state;
          }
          return _processRunningPosition(tick);
        case LessonSessionStatus.running:
          return _processRunningPosition(tick);
        case LessonSessionStatus.successFeedback:
          final limit = _state.feedbackUntilTimestampMs;
          if (limit != null && tick.monotonicTimestampMs >= limit) {
            await _beginReentry();
          }
          return _state;
        case LessonSessionStatus.reentry:
          final endTick = _reentryEndTick!;
          if (tick.positionTicks < endTick) {
            _state = _state.copyWith(positionTicks: tick.positionTicks);
            return _state;
          }
          _state = _state.copyWith(
            status: LessonSessionStatus.running,
            positionTicks: endTick.toDouble(),
            currentTarget: _nextPendingTarget(),
          );
          await _analyzer.setTarget(_targetFor(_state.currentTarget));
          return _processRunningPosition(tick);
        case LessonSessionStatus.idle:
        case LessonSessionStatus.ready:
        case LessonSessionStatus.waitingForTarget:
        case LessonSessionStatus.validating:
        case LessonSessionStatus.paused:
        case LessonSessionStatus.completed:
        case LessonSessionStatus.failure:
          return _state;
      }
    } on LessonException catch (error) {
      await _enterFailure(error);
      return _state;
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.lessonClockFailure),
      );
      return _state;
    }
  }

  Future<LessonSessionState> _processRunningPosition(
    LessonClockTick tick,
  ) async {
    final target = _nextPendingTarget();
    if (target != null && tick.positionTicks >= target.startTick) {
      await _clock.pause();
      await _analyzer.setTarget(_targetFor(target));
      _resetEvaluation();
      _state = _state.copyWith(
        status: LessonSessionStatus.waitingForTarget,
        positionTicks: target.startTick.toDouble(),
        currentTarget: target,
        attempt: 1,
        waitStartedTimestampMs: tick.monotonicTimestampMs,
      );
      return _state;
    }
    if (target == null && tick.positionTicks >= _state.section.endTick) {
      _state = _state.copyWith(
        status: LessonSessionStatus.completed,
        positionTicks: _state.section.endTick.toDouble(),
        currentTarget: null,
      );
      await stop(reason: LessonStopReason.naturalCompletion);
      return _state;
    }
    _state = _state.copyWith(
      status: LessonSessionStatus.running,
      positionTicks: tick.positionTicks,
      currentTarget: target,
    );
    return _state;
  }

  Future<LessonSessionState> processObservation(
    PerformanceObservation observation,
  ) async {
    try {
      if (_state.status != LessonSessionStatus.waitingForTarget &&
          _state.status != LessonSessionStatus.validating) {
        return _state;
      }
      final waitStart = _state.waitStartedTimestampMs;
      if (waitStart == null ||
          observation.timestampMs <= waitStart ||
          _consumedOnsets.contains(observation.onsetSequence)) {
        return _state;
      }
      final target = _state.currentTarget;
      if (target is LessonNoteEvent &&
          observation is NotePerformanceObservation) {
        await _processNote(target, observation);
      } else if (target is LessonChordEvent &&
          observation is ChordPerformanceObservation) {
        await _processChord(target, observation);
      }
      return _state;
    } on LessonException catch (error) {
      await _enterFailure(error);
      return _state;
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.performanceAnalyzerUnavailable),
      );
      return _state;
    }
  }

  Future<void> _processNote(
    LessonNoteEvent target,
    NotePerformanceObservation observation,
  ) async {
    final matches = observation.midi == target.midi &&
        observation.confidence >= _policy.noteMinConfidence &&
        observation.cents.abs() <= _policy.noteMaxAbsCents;
    if (!matches) {
      _noteStableFromMs = null;
      _noteOnsetSequence = null;
      _state = _state.copyWith(status: LessonSessionStatus.waitingForTarget);
      return;
    }
    if (_noteOnsetSequence != observation.onsetSequence) {
      _noteOnsetSequence = observation.onsetSequence;
      _noteStableFromMs = observation.timestampMs;
    }
    _state = _state.copyWith(status: LessonSessionStatus.validating);
    if (observation.timestampMs - _noteStableFromMs! >= _policy.noteStableMs) {
      await _recordSuccess(observation);
    }
  }

  Future<void> _processChord(
    LessonChordEvent target,
    ChordPerformanceObservation observation,
  ) async {
    if (_chordWindowStartMs == null) {
      if (observation.onsetConfidence < _policy.chordMinOnsetConfidence) {
        return;
      }
      _chordWindowStartMs = observation.timestampMs;
      _chordOnsetSequence = observation.onsetSequence;
      _chordMaxima = List.filled(12, 0);
    }
    if (_chordOnsetSequence != observation.onsetSequence) return;
    for (var index = 0; index < 12; index++) {
      if (observation.pitchClassStrengths[index] > _chordMaxima![index]) {
        _chordMaxima![index] = observation.pitchClassStrengths[index];
      }
    }
    _state = _state.copyWith(status: LessonSessionStatus.validating);
    final strengths = target.requiredPitchClasses
        .map((pitchClass) => _chordMaxima![pitchClass])
        .toList(growable: false);
    final mean =
        strengths.reduce((left, right) => left + right) / strengths.length;
    final success = strengths.every(
          (strength) => strength >= _policy.chordMinToneStrength,
        ) &&
        mean >= _policy.chordMinMeanStrength;
    if (success) {
      await _recordSuccess(observation);
      return;
    }
    if (observation.timestampMs - _chordWindowStartMs! >=
        _policy.chordWindowMs) {
      _consumedOnsets.add(observation.onsetSequence);
      _resetEvaluation();
      _state = _state.copyWith(
        status: LessonSessionStatus.waitingForTarget,
        attempt: _state.attempt + 1,
        waitStartedTimestampMs: observation.timestampMs,
      );
    }
  }

  Future<void> _recordSuccess(PerformanceObservation observation) async {
    final target = _state.currentTarget!;
    final results = Map<String, LessonEventResult>.of(_state.results)
      ..[target.id] = LessonEventResult(
        eventId: target.id,
        attempt: _state.attempt,
        completedAtTimestampMs: observation.timestampMs,
        onsetSequence: observation.onsetSequence,
      );
    _consumedOnsets.add(observation.onsetSequence);
    await _analyzer.setTarget(null);
    _state = _state.copyWith(
      status: LessonSessionStatus.successFeedback,
      results: results,
      feedbackUntilTimestampMs: observation.timestampMs + successFeedbackMs,
      waitStartedTimestampMs: null,
    );
  }

  Future<void> _beginReentry() async {
    final completedTarget = _state.currentTarget!;
    final start = completedTarget.startTick - _policy.reentryTicks;
    final reentryStart =
        start < _state.section.startTick ? _state.section.startTick : start;
    _reentryEndTick = completedTarget.startTick;
    await _clock.seek(reentryStart);
    await _clock.resume();
    _resetEvaluation();
    _state = _state.copyWith(
      status: LessonSessionStatus.reentry,
      positionTicks: reentryStart.toDouble(),
      currentTarget: null,
      feedbackUntilTimestampMs: null,
      attempt: 1,
    );
  }

  Future<LessonSessionState> setSpeed(double speed) async {
    validateLessonSpeed(speed);
    const allowed = {
      LessonSessionStatus.ready,
      LessonSessionStatus.countIn,
      LessonSessionStatus.running,
      LessonSessionStatus.waitingForTarget,
      LessonSessionStatus.paused,
    };
    if (!allowed.contains(_state.status)) return _state;
    try {
      if (_resourcesStarted) await _clock.setSpeed(speed);
      _state = _state.copyWith(speed: speed);
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.lessonClockFailure),
      );
    }
    return _state;
  }

  Future<LessonSessionState> pause() async {
    const active = {
      LessonSessionStatus.countIn,
      LessonSessionStatus.running,
      LessonSessionStatus.waitingForTarget,
      LessonSessionStatus.validating,
      LessonSessionStatus.successFeedback,
      LessonSessionStatus.reentry,
    };
    if (!active.contains(_state.status)) return _state;
    try {
      await _clock.pause();
      _state = _state.copyWith(
        status: LessonSessionStatus.paused,
        resumeStatus: _state.status,
      );
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.lessonClockFailure),
      );
    }
    return _state;
  }

  Future<LessonSessionState> resume() async {
    if (_state.status != LessonSessionStatus.paused) return _state;
    final resumeStatus = _state.resumeStatus ?? LessonSessionStatus.running;
    final endTick = _state.positionTicks.round();
    final countInTicks = _countInTicksAt(_state.chart, endTick);
    final initialTick = endTick - countInTicks;
    try {
      _countInEndTick = endTick;
      _countInResumeStatus = resumeStatus;
      await _clock.seek(initialTick);
      await _clock.resume();
      _state = _state.copyWith(
        status: LessonSessionStatus.countIn,
        positionTicks: initialTick.toDouble(),
      );
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.lessonClockFailure),
      );
    }
    return _state;
  }

  Future<LessonSessionState> repeatSection() async {
    final firstTarget = _requiredEvents(
      _state.chart,
      _state.section,
    ).firstOrNull;
    final countInTicks = _countInTicksAt(
      _state.chart,
      _state.section.startTick,
    );
    final initialTick = _state.section.startTick - countInTicks;
    try {
      final mustStartClock = !_resourcesStarted;
      if (mustStartClock) {
        await _analyzer.start(_analyzerSettings);
        _resourcesStarted = true;
      }
      _consumedOnsets.clear();
      _resetEvaluation();
      _countInEndTick = _state.section.startTick;
      _countInResumeStatus = LessonSessionStatus.running;
      await _analyzer.setTarget(_targetFor(firstTarget));
      if (mustStartClock) {
        await _clock.start(initialTick: initialTick, speed: _state.speed);
      } else {
        await _clock.seek(initialTick);
        await _clock.resume();
      }
      _state = _state.copyWith(
        status: LessonSessionStatus.countIn,
        positionTicks: initialTick.toDouble(),
        currentTarget: firstTarget,
        results: const {},
        attempt: 1,
        error: null,
        resumeStatus: null,
        waitStartedTimestampMs: null,
        feedbackUntilTimestampMs: null,
      );
    } catch (_) {
      await _enterFailure(
        const LessonException(LessonErrorCode.lessonClockFailure),
      );
    }
    return _state;
  }

  Future<LessonSessionState> stop({
    LessonStopReason reason = LessonStopReason.voluntary,
  }) async {
    if (_resourcesStarted) {
      await _shutdownResources();
    }
    final status = switch (reason) {
      LessonStopReason.voluntary => LessonSessionStatus.ready,
      LessonStopReason.naturalCompletion => LessonSessionStatus.completed,
      LessonStopReason.failure => LessonSessionStatus.failure,
    };
    _state = _state.copyWith(
      status: status,
      positionTicks: reason == LessonStopReason.voluntary
          ? _state.section.startTick.toDouble()
          : _state.positionTicks,
      currentTarget: reason == LessonStopReason.voluntary
          ? _requiredEvents(_state.chart, _state.section).firstOrNull
          : null,
      results: reason == LessonStopReason.voluntary ? const {} : _state.results,
      attempt: reason == LessonStopReason.voluntary ? 1 : _state.attempt,
      error: reason == LessonStopReason.voluntary ? null : _state.error,
      resumeStatus: null,
      waitStartedTimestampMs: null,
      feedbackUntilTimestampMs: null,
    );
    return _state;
  }

  Future<void> _enterFailure(LessonException error) async {
    _state = _state.copyWith(
      status: LessonSessionStatus.failure,
      error: error,
    );
    try {
      await stop(reason: LessonStopReason.failure);
    } catch (_) {
      _resourcesStarted = false;
    }
  }

  Future<void> _shutdownResources() async {
    for (final operation in <Future<void> Function()>[
      _clock.pause,
      _clock.stop,
      () => _analyzer.setTarget(null),
      _analyzer.stop,
    ]) {
      try {
        await operation();
      } catch (_) {
        // UC-L09 exige intentar liberar todos los recursos incluso si uno falla.
      }
    }
    _resourcesStarted = false;
  }

  LessonEvent? _nextPendingTarget() {
    for (final event in _requiredEvents(_state.chart, _state.section)) {
      if (!_state.results.containsKey(event.id)) return event;
    }
    return null;
  }

  void _resetEvaluation() {
    _noteStableFromMs = null;
    _noteOnsetSequence = null;
    _chordWindowStartMs = null;
    _chordOnsetSequence = null;
    _chordMaxima = null;
  }
}

final class GetLessonViewportSliceUseCase {
  const GetLessonViewportSliceUseCase();

  LessonViewportSlice call(
    LessonSessionState state, {
    required int windowStartTick,
    required int windowEndTick,
  }) {
    if (windowEndTick < windowStartTick) {
      throw RangeError('windowEndTick debe ser >= windowStartTick.');
    }
    final visible = state.chart.events
        .where(
          (event) =>
              event.startTick <= windowEndTick &&
              event.endTick > windowStartTick,
        )
        .toList(growable: false);
    return LessonViewportSlice(
      positionTicks: state.positionTicks,
      windowStartTick: windowStartTick,
      windowEndTick: windowEndTick,
      visibleEvents: visible,
      currentTargetId: state.currentTarget?.id,
      status: state.status,
    );
  }
}

LessonSection _selectSection(LessonChart chart, String? sectionId) {
  if (sectionId == null) {
    if (chart.sections.isNotEmpty) return chart.sections.first;
    return LessonSection(
      id: 'full-chart',
      title: chart.title,
      startTick: 0,
      endTick: chart.totalTicks,
    );
  }
  for (final section in chart.sections) {
    if (section.id == sectionId) return section;
  }
  throw const LessonException(
    LessonErrorCode.sessionInvariantViolation,
    context: 'La seccion solicitada no existe.',
  );
}

List<LessonEvent> _requiredEvents(
  LessonChart chart,
  LessonSection section,
) {
  return chart.events
      .where(
        (event) =>
            event.required &&
            event.startTick >= section.startTick &&
            event.startTick < section.endTick,
      )
      .toList(growable: false);
}

int _countInTicksAt(LessonChart chart, int tick) {
  var meter = chart.meterMap.first;
  for (final candidate in chart.meterMap) {
    if (candidate.tick > tick) break;
    meter = candidate;
  }
  return meter.numerator * 4 * lessonTicksPerQuarter ~/ meter.denominator;
}

PerformanceTarget? _targetFor(LessonEvent? event) {
  return switch (event) {
    LessonNoteEvent note => NotePerformanceTarget(
        eventId: note.id,
        midi: note.midi,
      ),
    LessonChordEvent chord => ChordPerformanceTarget(
        eventId: chord.id,
        requiredPitchClasses: chord.requiredPitchClasses,
      ),
    null => null,
  };
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
