abstract class MetronomeAudioSink {
  Future<void> prepare();

  Future<void> play({required bool strong});

  Future<void> dispose();
}
