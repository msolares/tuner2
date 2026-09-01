import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'click_wave.dart';
import 'metronome_audio_sink.dart';
import 'preloaded_click_pool.dart';

class AudioplayersMetronomeAudioSink implements MetronomeAudioSink {
  Directory? _tempDirectory;
  PreloadedClickPool? _strongPool;
  PreloadedClickPool? _normalPool;

  @override
  Future<void> prepare() async {
    if (_strongPool != null && _normalPool != null) {
      return;
    }
    final directory =
        await Directory.systemTemp.createTemp('afinador-metronome-');
    _tempDirectory = directory;
    final strongFile =
        File('${directory.path}${Platform.pathSeparator}strong.wav');
    final normalFile =
        File('${directory.path}${Platform.pathSeparator}normal.wav');
    await strongFile.writeAsBytes(
      createClickWav(frequencyHz: 1760, amplitude: 0.82),
      flush: true,
    );
    await normalFile.writeAsBytes(
      createClickWav(frequencyHz: 1100, amplitude: 0.58),
      flush: true,
    );
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
      ),
    );
    final strongPool = PreloadedClickPool(
      source: DeviceFileSource(strongFile.path),
      playerMode: PlayerMode.lowLatency,
      audioContext: audioContext,
    );
    final normalPool = PreloadedClickPool(
      source: DeviceFileSource(normalFile.path),
      playerMode: PlayerMode.lowLatency,
      audioContext: audioContext,
    );
    try {
      await strongPool.prepare();
      await normalPool.prepare();
      _strongPool = strongPool;
      _normalPool = normalPool;
    } catch (_) {
      await strongPool.dispose();
      await normalPool.dispose();
      rethrow;
    }
  }

  @override
  Future<void> play({required bool strong}) async {
    final pool = strong ? _strongPool : _normalPool;
    if (pool == null) {
      throw StateError('La salida de audio no está preparada.');
    }
    await pool.play();
  }

  @override
  Future<void> dispose() async {
    final strongPool = _strongPool;
    final normalPool = _normalPool;
    _strongPool = null;
    _normalPool = null;
    if (strongPool != null) {
      await strongPool.dispose();
    }
    if (normalPool != null) {
      await normalPool.dispose();
    }
    final directory = _tempDirectory;
    _tempDirectory = null;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
