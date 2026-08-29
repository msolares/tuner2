import 'dart:math' as math;
import 'dart:typed_data';

Uint8List createClickWav({
  required int frequencyHz,
  required double amplitude,
}) {
  // 48 kHz coincide con la ruta nativa habitual de Android y evita que el
  // backend de baja latencia tenga que remuestrear cada clic.
  const sampleRate = 48000;
  const durationMs = 38;
  const channels = 1;
  const bitsPerSample = 16;
  const sampleCount = sampleRate * durationMs ~/ 1000;
  const dataLength = sampleCount * 2;
  final bytes = ByteData(44 + dataLength);

  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(
      28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
  bytes.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
  bytes.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);

  for (var index = 0; index < sampleCount; index++) {
    final time = index / sampleRate;
    final envelope = math.exp(-time * 92);
    final sample =
        math.sin(2 * math.pi * frequencyHz * time) * envelope * amplitude;
    bytes.setInt16(44 + index * 2, (sample * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}
