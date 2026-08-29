import 'dart:async';
import 'dart:math' as math;

import '../../domain/entities/metronome_settings.dart';
import '../../domain/entities/metronome_tick.dart';
import '../../domain/services/metronome_engine.dart';
import 'metronome_audio_sink.dart';

/// Metrónomo basado en un reloj monotónico y planificación absoluta.
///
/// `Timer` solo despierta el scheduler: el instante objetivo siempre se calcula
/// desde [Stopwatch], evitando acumular el error de cada callback.
class ScheduledMetronomeEngine implements MetronomeEngine {
  ScheduledMetronomeEngine({
    required MetronomeAudioSink audioSink,
    this.lookAhead = const Duration(milliseconds: 2),
    this.maxPendingAudioOperations = 8,
    this.audioDrainTimeout = const Duration(milliseconds: 750),
  }) : _audioSink = audioSink;

  final Duration lookAhead;
  final int maxPendingAudioOperations;
  final Duration audioDrainTimeout;
  final MetronomeAudioSink _audioSink;
  final _ticksController = StreamController<MetronomeTick>.broadcast();
  final _clock = Stopwatch();

  Timer? _timer;
  MetronomeSettings? _settings;
  MetronomeSettings? _pendingSettings;
  int _beatIndex = 0;
  int _subdivisionIndex = 0;
  final Set<Future<void>> _pendingAudioOperations = <Future<void>>{};
  double _targetMicros = 0;
  bool _running = false;
  bool _audioErrorReported = false;

  @override
  Stream<MetronomeTick> ticks() => _ticksController.stream;

  @override
  Future<void> start(MetronomeSettings settings) async {
    await stop();
    await _audioSink.prepare();
    _settings = settings;
    _pendingSettings = null;
    _beatIndex = 0;
    _subdivisionIndex = 0;
    _targetMicros = 0;
    _audioErrorReported = false;
    _running = true;
    _clock
      ..reset()
      ..start();
    _scheduleNext();
  }

  @override
  Future<void> update(MetronomeSettings settings) async {
    if (!_running) {
      _settings = settings;
      return;
    }
    _pendingSettings = settings;
  }

  @override
  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    _pendingSettings = null;
    final pending = _pendingAudioOperations.toList(growable: false);
    if (pending.isNotEmpty) {
      try {
        await Future.wait(pending).timeout(audioDrainTimeout);
      } on TimeoutException {
        // El dispose del sink fuerza la liberación del backend si una llamada
        // nativa no responde dentro del presupuesto de parada.
      }
    }
    await _audioSink.dispose();
  }

  void _scheduleNext() {
    if (!_running || _settings == null) {
      return;
    }
    final remainingMicros = _targetMicros.round() - _clock.elapsedMicroseconds;
    final wakeIn = math.max(
      0,
      remainingMicros - lookAhead.inMicroseconds,
    );
    _timer = Timer(Duration(microseconds: wakeIn), _emitScheduledTick);
  }

  void _emitScheduledTick() {
    if (!_running || _settings == null) {
      return;
    }

    _applyPendingSettingsAtBarBoundary();

    // Si el isolate estuvo detenido, nunca reproducimos de golpe los pulsos
    // que ya vencieron. Se conserva el calendario absoluto y se retoma en el
    // primer pulso que todavía puede sonar a tiempo.
    final elapsedMicros = _clock.elapsedMicroseconds;
    while (_targetMicros + _currentPulseMicros() <= elapsedMicros) {
      _advancePosition();
      _applyPendingSettingsAtBarBoundary();
    }

    final settings = _settings!;
    final beat = settings.beats[_beatIndex];
    final isFirstPulse = _subdivisionIndex == 0;
    final tickAccent = isFirstPulse ? beat.accent : BeatAccent.normal;
    final scheduledTimestampMs = _targetMicros.round() ~/ 1000;

    if (beat.accent != BeatAccent.muted) {
      _queueAudio(strong: tickAccent == BeatAccent.strong);
    }
    _ticksController.add(
      MetronomeTick(
        beatIndex: _beatIndex,
        subdivisionIndex: _subdivisionIndex,
        timestampMs: scheduledTimestampMs,
        accent: beat.accent == BeatAccent.muted ? BeatAccent.muted : tickAccent,
      ),
    );

    _advancePosition();
    _scheduleNext();
  }

  void _queueAudio({required bool strong}) {
    if (_pendingAudioOperations.length >= maxPendingAudioOperations) {
      _reportAudioFailure(
        StateError('La cola de audio del metrónomo no responde.'),
        StackTrace.current,
      );
      return;
    }

    late final Future<void> operation;
    operation = Future<void>.sync(() => _audioSink.play(strong: strong))
        .catchError((Object error, StackTrace stackTrace) {
      _reportAudioFailure(error, stackTrace);
    }).whenComplete(() {
      _pendingAudioOperations.remove(operation);
    });
    _pendingAudioOperations.add(operation);
  }

  void _reportAudioFailure(Object error, StackTrace stackTrace) {
    if (!_running || _audioErrorReported) {
      return;
    }
    _audioErrorReported = true;
    _ticksController.addError(error, stackTrace);
  }

  void _applyPendingSettingsAtBarBoundary() {
    if (_beatIndex == 0 &&
        _subdivisionIndex == 0 &&
        _targetMicros > 0 &&
        _pendingSettings != null) {
      _settings = _pendingSettings;
      _pendingSettings = null;
    }
  }

  double _currentPulseMicros() {
    final settings = _settings!;
    final pulses = settings.beats[_beatIndex].subdivision.pulses;
    return 60000000 / settings.bpm / pulses;
  }

  void _advancePosition() {
    final settings = _settings!;
    final pulses = settings.beats[_beatIndex].subdivision.pulses;
    _targetMicros += 60000000 / settings.bpm / pulses;
    _subdivisionIndex++;
    if (_subdivisionIndex >= pulses) {
      _subdivisionIndex = 0;
      _beatIndex = (_beatIndex + 1) % settings.beats.length;
    }
  }
}
