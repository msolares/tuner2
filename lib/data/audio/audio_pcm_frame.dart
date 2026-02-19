import 'dart:typed_data';

class AudioPcmFrame {
  const AudioPcmFrame({
    required this.pcmFloat32,
    required this.sampleRateHz,
    required this.timestampMs,
  });

  final Float32List pcmFloat32;
  final int sampleRateHz;
  final int timestampMs;
}
