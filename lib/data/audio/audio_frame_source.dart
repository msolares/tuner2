import 'audio_pcm_frame.dart';

abstract class AudioFrameSource {
  Stream<AudioPcmFrame> frames();

  Future<void> start();

  Future<void> stop();
}
