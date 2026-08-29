enum WebAudioCaptureBackend {
  recordPlugin,
  sharedWebAudio,
}

WebAudioCaptureBackend chooseWebAudioCaptureBackend({
  required String userAgent,
  required String platform,
  required int maxTouchPoints,
}) {
  final reportsIosDevice = RegExp(r'iPad|iPhone|iPod').hasMatch(userAgent);
  final isIpadDesktopMode = platform == 'MacIntel' && maxTouchPoints > 1;
  return reportsIosDevice || isIpadDesktopMode
      ? WebAudioCaptureBackend.sharedWebAudio
      : WebAudioCaptureBackend.recordPlugin;
}
