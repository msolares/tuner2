import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../audio/web_audio_session.dart';
import 'metronome_audio_sink.dart';

/// Salida Web Audio que comparte el contexto desbloqueado por el gesto.
class AudioplayersMetronomeAudioSink implements MetronomeAudioSink {
  AudioplayersMetronomeAudioSink({WebAudioSession? session})
      : _session = session ?? WebAudioSession.instance;

  final WebAudioSession _session;
  final Set<_ActiveClick> _activeClicks = <_ActiveClick>{};
  bool _prepared = false;

  @override
  Future<void> prepare() async {
    if (_prepared) {
      return;
    }
    _session.installActivationListener();
    await _session.ensureRunning();
    _prepared = true;
  }

  @override
  Future<void> play({required bool strong}) async {
    if (!_prepared) {
      throw StateError('La salida de audio no está preparada.');
    }
    await _session.ensureRunning();
    final context = _session.context;
    final now = context.currentTime;
    final oscillator = context.createOscillator()
      ..type = 'square'
      ..frequency.setValueAtTime(strong ? 1760 : 1100, now);
    final gain = context.createGain();
    gain.gain
      ..setValueAtTime(strong ? 0.82 : 0.58, now)
      ..exponentialRampToValueAtTime(0.001, now + 0.035);
    oscillator.connect(gain);
    gain.connect(context.destination);

    final click = _ActiveClick(oscillator, gain);
    _activeClicks.add(click);
    oscillator.onended = ((web.Event _) {
      _activeClicks.remove(click);
      click.disconnect();
    }).toJS;
    oscillator.start(now);
    oscillator.stop(now + 0.04);
  }

  @override
  Future<void> dispose() async {
    _prepared = false;
    final clicks = _activeClicks.toList(growable: false);
    _activeClicks.clear();
    for (final click in clicks) {
      click.stopAndDisconnect();
    }
  }
}

class _ActiveClick {
  _ActiveClick(this.oscillator, this.gain);

  final web.OscillatorNode oscillator;
  final web.GainNode gain;

  void stopAndDisconnect() {
    oscillator.onended = null;
    try {
      oscillator.stop();
    } catch (_) {
      // El oscilador puede haber finalizado entre el snapshot y el cleanup.
    }
    disconnect();
  }

  void disconnect() {
    oscillator.disconnect();
    gain.disconnect();
  }
}
