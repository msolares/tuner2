import 'metronome_audio_sink.dart';

class AudioplayersMetronomeAudioSink implements MetronomeAudioSink {
  @override
  Future<void> prepare() async {
    throw UnsupportedError('Salida de audio no disponible.');
  }

  @override
  Future<void> play({required bool strong}) async {}

  @override
  Future<void> dispose() async {}
}
