import 'package:flutter/foundation.dart';

enum AudioCapturePlatform {
  android,
  ios,
  web,
}

class AudioCaptureProfile {
  const AudioCaptureProfile({
    required this.sampleRateHz,
    required this.bufferSizeFrames,
    required this.channels,
    required this.pcmFloat32,
    required this.restrictions,
  });

  final int sampleRateHz;
  final int bufferSizeFrames;
  final int channels;
  final bool pcmFloat32;
  final String restrictions;
}

const Map<AudioCapturePlatform, AudioCaptureProfile> kAudioCaptureProfiles = {
  AudioCapturePlatform.android: AudioCaptureProfile(
    sampleRateHz: 48000,
    bufferSizeFrames: 1024,
    channels: 1,
    pcmFloat32: true,
    restrictions: 'Fallback a 44100 Hz si el hardware no soporta 48000 Hz.',
  ),
  AudioCapturePlatform.ios: AudioCaptureProfile(
    sampleRateHz: 48000,
    bufferSizeFrames: 1024,
    channels: 1,
    pcmFloat32: true,
    restrictions: 'Sesion AVAudio en modo medicion; puede ajustar buffer por latencia del dispositivo.',
  ),
  AudioCapturePlatform.web: AudioCaptureProfile(
    sampleRateHz: 48000,
    bufferSizeFrames: 2048,
    channels: 1,
    pcmFloat32: true,
    restrictions: 'Sample rate final lo decide el navegador; requiere gesto de usuario para iniciar microfono.',
  ),
};

AudioCapturePlatform currentAudioCapturePlatform() {
  if (kIsWeb) {
    return AudioCapturePlatform.web;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AudioCapturePlatform.android;
    case TargetPlatform.iOS:
      return AudioCapturePlatform.ios;
    default:
      throw UnsupportedError('Plataforma no soportada para captura de audio MVP.');
  }
}

AudioCaptureProfile currentAudioCaptureProfile() {
  return kAudioCaptureProfiles[currentAudioCapturePlatform()]!;
}
