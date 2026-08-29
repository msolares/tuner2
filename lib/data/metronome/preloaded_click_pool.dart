import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Pool de voces ya preparadas para un único tipo de clic.
///
/// En `lowLatency`, `AudioPool` no recibe eventos de finalización. Por eso cada
/// voz se devuelve explícitamente al pool después de que termina la muestra.
class PreloadedClickPool {
  PreloadedClickPool({
    required this.source,
    required this.playerMode,
    this.audioContext,
    this.voiceLease = const Duration(milliseconds: 45),
    this.operationTimeout = const Duration(milliseconds: 500),
    this.minPlayers = 4,
    this.maxPlayers = 8,
  });

  final Source source;
  final PlayerMode playerMode;
  final AudioContext? audioContext;
  final Duration voiceLease;
  final Duration operationTimeout;
  final int minPlayers;
  final int maxPlayers;

  AudioPool? _pool;
  final Set<Timer> _releaseTimers = <Timer>{};
  final Set<StopFunction> _activeVoices = <StopFunction>{};
  bool _disposing = false;

  Future<void> prepare() async {
    if (_pool != null) {
      return;
    }
    _disposing = false;
    final pool = await AudioPool.create(
      source: source,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      playerMode: playerMode,
      audioContext: audioContext,
    ).timeout(operationTimeout);
    if (_disposing) {
      await pool.dispose();
      return;
    }
    _pool = pool;
  }

  Future<void> play() async {
    final pool = _pool;
    if (pool == null || _disposing) {
      throw StateError('El pool de clics no está preparado.');
    }

    final stop = await pool.start().timeout(operationTimeout);
    if (_disposing) {
      await stop().timeout(operationTimeout);
      return;
    }

    _activeVoices.add(stop);
    late final Timer timer;
    timer = Timer(voiceLease, () {
      _releaseTimers.remove(timer);
      unawaited(_release(stop));
    });
    _releaseTimers.add(timer);
  }

  Future<void> dispose() async {
    _disposing = true;
    for (final timer in _releaseTimers) {
      timer.cancel();
    }
    _releaseTimers.clear();

    final voices = _activeVoices.toList(growable: false);
    await Future.wait(voices.map(_release)).timeout(
      operationTimeout,
      onTimeout: () => <void>[],
    );

    final pool = _pool;
    _pool = null;
    if (pool != null) {
      await pool.dispose().timeout(operationTimeout);
    }
  }

  Future<void> _release(StopFunction stop) async {
    if (!_activeVoices.remove(stop)) {
      return;
    }
    try {
      await stop().timeout(operationTimeout);
    } catch (_) {
      // El dispose del pool sigue liberando cualquier voz que haya quedado.
    }
  }
}
