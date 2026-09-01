import 'dart:async';
import 'dart:math';

import '../../../domain/learning/lesson_chart.dart';
import '../../../domain/learning/lesson_errors.dart';
import '../../../domain/learning/lesson_ports.dart';
import '../../../domain/learning/performance.dart';

const Duration lessonClockCallbackInterval = Duration(microseconds: 16667);

abstract interface class MonotonicTimeSource {
  int nowMicroseconds();
}

abstract interface class LessonClockScheduledTask {
  void cancel();
}

abstract interface class LessonClockScheduler {
  LessonClockScheduledTask schedule(Duration delay, void Function() callback);
}

final class StopwatchMonotonicTimeSource implements MonotonicTimeSource {
  StopwatchMonotonicTimeSource() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  int nowMicroseconds() => _stopwatch.elapsedMicroseconds;
}

final class TimerLessonClockScheduler implements LessonClockScheduler {
  const TimerLessonClockScheduler();

  @override
  LessonClockScheduledTask schedule(
    Duration delay,
    void Function() callback,
  ) {
    return _TimerScheduledTask(Timer(delay, callback));
  }
}

final class MonotonicLessonClock implements LessonClock {
  MonotonicLessonClock({
    MonotonicTimeSource? timeSource,
    LessonClockScheduler? scheduler,
    Duration callbackInterval = lessonClockCallbackInterval,
  })  : _timeSource = timeSource ?? StopwatchMonotonicTimeSource(),
        _scheduler = scheduler ?? const TimerLessonClockScheduler(),
        _callbackIntervalUs = callbackInterval.inMicroseconds {
    if (_callbackIntervalUs <= 0) {
      throw ArgumentError.value(
        callbackInterval,
        'callbackInterval',
        'Debe ser positivo.',
      );
    }
  }

  final MonotonicTimeSource _timeSource;
  final LessonClockScheduler _scheduler;
  final int _callbackIntervalUs;
  final StreamController<LessonClockTick> _controller =
      StreamController<LessonClockTick>.broadcast();

  List<TempoPoint> _tempoMap = const [];
  LessonClockScheduledTask? _scheduledTask;
  double _anchorPositionTicks = 0;
  int _anchorTimeUs = 0;
  int _nextDeadlineUs = 0;
  double _speed = lessonDefaultSpeed;
  int? _initialTick;
  int _generation = 0;
  bool _active = false;
  bool _running = false;

  @override
  Stream<LessonClockTick> ticks() => _controller.stream;

  @override
  Future<void> start({
    required int initialTick,
    required double speed,
    required List<TempoPoint> tempoMap,
  }) async {
    _validateSpeed(speed);
    final copiedTempoMap = _validatedTempoMap(tempoMap);
    if (_active &&
        _initialTick == initialTick &&
        _speed == speed &&
        _sameTempoMap(_tempoMap, copiedTempoMap)) {
      return;
    }

    _cancelScheduledTask();
    final nowUs = _timeSource.nowMicroseconds();
    _tempoMap = copiedTempoMap;
    _speed = speed;
    _initialTick = initialTick;
    _anchorPositionTicks = initialTick.toDouble();
    _anchorTimeUs = nowUs;
    _active = true;
    _running = true;
    _generation++;
    _emitAt(nowUs);
    try {
      _restartSchedule(nowUs);
    } catch (error, stackTrace) {
      _deactivate();
      Error.throwWithStackTrace(_clockFailure(error), stackTrace);
    }
  }

  @override
  Future<void> pause() async {
    if (!_active || !_running) {
      return;
    }
    final nowUs = _timeSource.nowMicroseconds();
    _anchorPositionTicks = _positionAt(nowUs);
    _anchorTimeUs = nowUs;
    _running = false;
    _generation++;
    _cancelScheduledTask();
    _emitAt(nowUs);
  }

  @override
  Future<void> resume() async {
    if (!_active || _running) {
      return;
    }
    final nowUs = _timeSource.nowMicroseconds();
    _anchorTimeUs = nowUs;
    _running = true;
    _generation++;
    try {
      _restartSchedule(nowUs);
    } catch (error, stackTrace) {
      _deactivate();
      Error.throwWithStackTrace(_clockFailure(error), stackTrace);
    }
  }

  @override
  Future<void> seek(int tick) async {
    if (!_active) {
      return;
    }
    final nowUs = _timeSource.nowMicroseconds();
    _anchorPositionTicks = tick.toDouble();
    _anchorTimeUs = nowUs;
    _initialTick = tick;
    _generation++;
    _cancelScheduledTask();
    _emitAt(nowUs);
    if (_running) {
      try {
        _restartSchedule(nowUs);
      } catch (error, stackTrace) {
        _deactivate();
        Error.throwWithStackTrace(_clockFailure(error), stackTrace);
      }
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    _validateSpeed(speed);
    if (!_active || _speed == speed) {
      return;
    }
    final nowUs = _timeSource.nowMicroseconds();
    if (_running) {
      _anchorPositionTicks = _positionAt(nowUs);
    }
    _anchorTimeUs = nowUs;
    _speed = speed;
    _generation++;
    _cancelScheduledTask();
    _emitAt(nowUs);
    if (_running) {
      try {
        _restartSchedule(nowUs);
      } catch (error, stackTrace) {
        _deactivate();
        Error.throwWithStackTrace(_clockFailure(error), stackTrace);
      }
    }
  }

  @override
  Future<void> stop() async {
    if (!_active) {
      return;
    }
    _deactivate();
  }

  void _restartSchedule(int nowUs) {
    _nextDeadlineUs = nowUs + _callbackIntervalUs;
    _scheduleNext(_generation);
  }

  void _scheduleNext(int generation) {
    if (!_active || !_running || generation != _generation) {
      return;
    }
    final nowUs = _timeSource.nowMicroseconds();
    while (_nextDeadlineUs <= nowUs) {
      _nextDeadlineUs += _callbackIntervalUs;
    }
    final delayUs = max(_nextDeadlineUs - nowUs, 0);
    _scheduledTask = _scheduler.schedule(
      Duration(microseconds: delayUs),
      () => _onScheduledCallback(generation),
    );
  }

  void _onScheduledCallback(int generation) {
    if (!_active || !_running || generation != _generation) {
      return;
    }
    _scheduledTask = null;
    final nowUs = _timeSource.nowMicroseconds();
    try {
      _emitAt(nowUs);
      _nextDeadlineUs += _callbackIntervalUs;
      _scheduleNext(generation);
    } catch (error, stackTrace) {
      final failure = _clockFailure(error);
      _deactivate();
      _controller.addError(failure, stackTrace);
    }
  }

  void _emitAt(int nowUs) {
    _controller.add(
      LessonClockTick(
        positionTicks: _positionAt(nowUs),
        monotonicTimestampMs: nowUs ~/ 1000,
      ),
    );
  }

  double _positionAt(int nowUs) {
    if (!_running || nowUs <= _anchorTimeUs) {
      return _anchorPositionTicks;
    }
    final elapsedSeconds = (nowUs - _anchorTimeUs) / 1000000;
    return _advanceAcrossTempoMap(_anchorPositionTicks, elapsedSeconds);
  }

  double _advanceAcrossTempoMap(double position, double elapsedSeconds) {
    var remainingSeconds = elapsedSeconds;
    var currentPosition = position;
    var tempoIndex = _tempoIndexAt(currentPosition);
    while (remainingSeconds > 0) {
      final bpm = _tempoMap[tempoIndex].bpm;
      final ticksPerSecond =
          bpm * lessonTicksPerQuarter / 60 * _speed;
      final nextTempoTick = tempoIndex + 1 < _tempoMap.length
          ? _tempoMap[tempoIndex + 1].tick.toDouble()
          : null;
      if (nextTempoTick == null || currentPosition >= nextTempoTick) {
        return currentPosition + remainingSeconds * ticksPerSecond;
      }
      final secondsToTempo =
          (nextTempoTick - currentPosition) / ticksPerSecond;
      if (remainingSeconds < secondsToTempo) {
        return currentPosition + remainingSeconds * ticksPerSecond;
      }
      currentPosition = nextTempoTick;
      remainingSeconds -= secondsToTempo;
      tempoIndex++;
    }
    return currentPosition;
  }

  int _tempoIndexAt(double position) {
    var result = 0;
    for (var index = 1; index < _tempoMap.length; index++) {
      if (_tempoMap[index].tick > position) {
        break;
      }
      result = index;
    }
    return result;
  }

  List<TempoPoint> _validatedTempoMap(List<TempoPoint> tempoMap) {
    if (tempoMap.isEmpty || tempoMap.first.tick != 0) {
      throw ArgumentError.value(
        tempoMap,
        'tempoMap',
        'Debe comenzar en tick 0.',
      );
    }
    for (var index = 1; index < tempoMap.length; index++) {
      if (tempoMap[index].tick <= tempoMap[index - 1].tick) {
        throw ArgumentError.value(
          tempoMap,
          'tempoMap',
          'Los ticks deben ser estrictamente ascendentes.',
        );
      }
    }
    return List<TempoPoint>.unmodifiable(tempoMap);
  }

  void _validateSpeed(double speed) {
    if (!speed.isFinite || speed < lessonMinSpeed || speed > lessonMaxSpeed) {
      throw RangeError.range(speed, lessonMinSpeed, lessonMaxSpeed, 'speed');
    }
  }

  bool _sameTempoMap(List<TempoPoint> left, List<TempoPoint> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  void _cancelScheduledTask() {
    _scheduledTask?.cancel();
    _scheduledTask = null;
  }

  void _deactivate() {
    _generation++;
    _cancelScheduledTask();
    _active = false;
    _running = false;
    _tempoMap = const [];
    _initialTick = null;
  }

  LessonException _clockFailure(Object error) {
    if (error is LessonException) {
      return error;
    }
    return LessonException(
      LessonErrorCode.lessonClockFailure,
      context: error.runtimeType.toString(),
    );
  }
}

final class _TimerScheduledTask implements LessonClockScheduledTask {
  const _TimerScheduledTask(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}
