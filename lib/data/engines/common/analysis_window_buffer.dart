import 'dart:typed_data';

import '../../audio/audio_pcm_frame.dart';

class AnalysisWindowBuffer {
  List<double> _samples = <double>[];
  int? _sampleRateHz;

  void reset() {
    _samples = <double>[];
    _sampleRateHz = null;
  }

  AudioPcmFrame? push(
    AudioPcmFrame frame, {
    required int windowFrames,
  }) {
    if (_sampleRateHz != null && _sampleRateHz != frame.sampleRateHz) {
      reset();
    }
    _sampleRateHz = frame.sampleRateHz;
    _samples.addAll(frame.pcmFloat32);

    final maxRetainedFrames = windowFrames * 2;
    if (_samples.length > maxRetainedFrames) {
      _samples = _samples.sublist(_samples.length - maxRetainedFrames);
    }

    if (_samples.length < windowFrames) {
      return null;
    }

    final window = _samples.sublist(_samples.length - windowFrames);
    return AudioPcmFrame(
      pcmFloat32: Float32List.fromList(window),
      sampleRateHz: frame.sampleRateHz,
      timestampMs: frame.timestampMs,
    );
  }
}

int analysisWindowFramesForPreset(String preset) {
  return switch (preset) {
    'guitar_standard' || 'bass_standard' || 'chromatic' => 4096,
    _ => 2048,
  };
}
