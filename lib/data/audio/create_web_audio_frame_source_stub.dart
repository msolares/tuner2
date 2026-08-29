import 'audio_capture_profile.dart';
import 'audio_frame_source.dart';

AudioFrameSource createWebAudioFrameSource({AudioCaptureProfile? profile}) {
  throw UnsupportedError('La captura Web Audio solo existe en navegador.');
}
