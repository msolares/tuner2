import 'audio_capture_profile.dart';
import 'audio_frame_source.dart';
import 'create_web_audio_frame_source_stub.dart'
    if (dart.library.js_interop) 'create_web_audio_frame_source_web.dart'
    as platform;

AudioFrameSource createWebAudioFrameSource({AudioCaptureProfile? profile}) {
  return platform.createWebAudioFrameSource(profile: profile);
}
