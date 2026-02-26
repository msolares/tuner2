import 'dart:math';
import 'dart:typed_data';

import 'package:afinador/data/engines/common/simple_pitch_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimplePitchDetector', () {
    test('respeta rango de frecuencia recibido por preset', () {
      final detector = SimplePitchDetector();
      final sample = detector.detect(
        pcm: _sineWave(440.0, 48000, 4096),
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );

      expect(sample, isNotNull);
      expect(sample!.hz, 0.0);
      expect(sample.note, '--');
    });

    test('detecta G3 en señal armónica rica dentro de rango guitarra', () {
      final detector = SimplePitchDetector();
      final sample = detector.detect(
        pcm: _harmonicWave(
          fundamentalHz: 196.0,
          sampleRateHz: 48000,
          len: 4096,
          harmonics: const [
            [1.0, 0.18],
            [2.0, 0.63],
            [3.0, 0.30],
            [4.0, 0.18],
          ],
        ),
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );

      expect(sample, isNotNull);
      expect(sample!.hz, closeTo(196.0, 4.0));
      expect(sample.note, 'G3');
    });
  });
}

Float32List _sineWave(double frequencyHz, int sampleRateHz, int len) {
  return Float32List.fromList(
    List<double>.generate(len, (i) {
      final phase = 2.0 * pi * frequencyHz * i / sampleRateHz;
      return sin(phase) * 0.5;
    }),
  );
}

Float32List _harmonicWave({
  required double fundamentalHz,
  required int sampleRateHz,
  required int len,
  required List<List<double>> harmonics,
}) {
  return Float32List.fromList(
    List<double>.generate(len, (i) {
      var sum = 0.0;
      for (final harmonic in harmonics) {
        final multiple = harmonic[0];
        final amplitude = harmonic[1];
        final phase = 2.0 * pi * (fundamentalHz * multiple) * i / sampleRateHz;
        sum += sin(phase) * amplitude;
      }
      return sum;
    }),
  );
}
