import 'dart:math';
import 'dart:typed_data';

import 'package:afinador/data/engines/common/simple_pitch_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimplePitchDetector', () {
    test('keeps any folded candidate inside the requested frequency range', () {
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
      expect(sample!.hz, inInclusiveRange(70.0, 420.0));
    });

    test('detects G3 in harmonic rich guitar-range signal', () {
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

    test('detects harmonic rich E2 without folding to upper harmonic', () {
      final detector = SimplePitchDetector();
      final sample = detector.detect(
        pcm: _harmonicWave(
          fundamentalHz: 82.41,
          sampleRateHz: 48000,
          len: 4096,
          harmonics: const [
            [1.0, 0.16],
            [2.0, 0.82],
            [3.0, 0.32],
            [4.0, 0.16],
          ],
        ),
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );

      expect(sample, isNotNull);
      expect(sample!.hz, closeTo(82.41, 3.0));
      expect(sample.note, 'E2');
    });

    test('detects harmonic rich A2 in low string range', () {
      final detector = SimplePitchDetector();
      final sample = detector.detect(
        pcm: _harmonicWave(
          fundamentalHz: 110.0,
          sampleRateHz: 48000,
          len: 4096,
          harmonics: const [
            [1.0, 0.20],
            [2.0, 0.68],
            [3.0, 0.24],
            [4.0, 0.10],
          ],
        ),
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );

      expect(sample, isNotNull);
      expect(sample!.hz, closeTo(110.0, 3.0));
      expect(sample.note, 'A2');
    });

    test('guitar preset does not reject a plucked E2 with bright harmonics',
        () {
      final detector = SimplePitchDetector();
      final pcm = _harmonicWave(
        fundamentalHz: 82.41,
        sampleRateHz: 48000,
        len: 4096,
        harmonics: const [
          [1.0, 0.18],
          [2.0, 0.82],
          [3.0, 0.48],
          [4.0, 0.38],
          [5.0, 0.34],
          [6.0, 0.30],
          [7.0, 0.27],
          [8.0, 0.24],
          [9.0, 0.21],
          [10.0, 0.18],
        ],
      );

      final guitar = detector.detect(
        pcm: pcm,
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );
      final chromatic = detector.detect(
        pcm: pcm,
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 50.0,
        maxFrequencyHz: 2000.0,
      );

      expect(chromatic, isNotNull);
      expect(chromatic!.hz, greaterThan(0.0));
      expect(guitar, isNotNull);
      expect(guitar!.hz, closeTo(82.41, 3.0));
      expect(guitar.note, 'E2');
    });

    test('does not veto a real E2 because upper harmonics raise zero crossings',
        () {
      final detector = SimplePitchDetector();
      final pcm = _harmonicWave(
        fundamentalHz: 82.41,
        sampleRateHz: 48000,
        len: 4096,
        harmonics: const [
          [1.0, 0.24],
          [2.0, 0.38],
          [3.0, 0.24],
          [4.0, 0.16],
          [8.0, 0.12],
          [12.0, 0.10],
          [16.0, 0.18],
        ],
      );

      expect(_zeroCrossingRate(pcm), greaterThan(0.02));
      final sample = detector.detect(
        pcm: pcm,
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );

      expect(sample, isNotNull);
      expect(sample!.hz, closeTo(82.41, 3.0));
      expect(sample.note, 'E2');
    });

    test('keeps confidence low for broadband noise without useful tone', () {
      final detector = SimplePitchDetector();
      final sample = detector.detect(
        pcm: _noise(len: 4096),
        sampleRateHz: 48000,
        a4Hz: 440.0,
        timestampMs: 100,
        minFrequencyHz: 70.0,
        maxFrequencyHz: 420.0,
      );

      expect(sample, isNotNull);
      expect(sample!.confidence, lessThan(0.35));
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

Float32List _noise({required int len}) {
  var state = 0x12345;
  return Float32List.fromList(
    List<double>.generate(len, (_) {
      state = (1103515245 * state + 12345) & 0x7fffffff;
      return ((state / 0x7fffffff) * 2.0 - 1.0) * 0.3;
    }),
  );
}

double _zeroCrossingRate(Float32List samples) {
  var crossings = 0;
  for (var i = 1; i < samples.length; i++) {
    if ((samples[i - 1] >= 0 && samples[i] < 0) ||
        (samples[i - 1] < 0 && samples[i] >= 0)) {
      crossings++;
    }
  }
  return crossings / (samples.length - 1);
}
