import 'package:web/web.dart' as web;

import 'audio_capture_profile.dart';
import 'audio_frame_source.dart';
import 'recorder_audio_frame_source.dart';
import 'web_audio_capture_backend.dart';
import 'web_audio_frame_source.dart';

AudioFrameSource createWebAudioFrameSource({AudioCaptureProfile? profile}) {
  final navigator = web.window.navigator;
  final backend = chooseWebAudioCaptureBackend(
    userAgent: navigator.userAgent,
    platform: navigator.platform,
    maxTouchPoints: navigator.maxTouchPoints,
  );
  return switch (backend) {
    WebAudioCaptureBackend.sharedWebAudio =>
      WebAudioFrameSource(profile: profile),
    WebAudioCaptureBackend.recordPlugin =>
      RecorderAudioFrameSource(profile: profile),
  };
}
