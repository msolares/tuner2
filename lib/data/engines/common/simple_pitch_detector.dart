import 'dart:math';
import 'dart:typed_data';

import '../../../domain/entities/pitch_sample.dart';

class SimplePitchDetector {
  PitchSample? detect({
    required Float32List pcm,
    required int sampleRateHz,
    required double a4Hz,
    required int timestampMs,
  }) {
    if (pcm.isEmpty || sampleRateHz <= 0) {
      return null;
    }
    final rms = _rms(pcm);
    if (rms < 0.01) {
      return PitchSample(
        hz: 0,
        note: '--',
        cents: 0,
        confidence: 0,
        timestampMs: timestampMs,
      );
    }

    final frequency = _autocorrelate(pcm, sampleRateHz);
    if (frequency <= 0) {
      return PitchSample(
        hz: 0,
        note: '--',
        cents: 0,
        confidence: 0,
        timestampMs: timestampMs,
      );
    }

    final midi = 69 + 12 * (log(frequency / a4Hz) / ln2);
    final nearestMidi = midi.round();
    final nearestHz = a4Hz * pow(2.0, (nearestMidi - 69) / 12.0);
    final cents = 1200 * (log(frequency / nearestHz) / ln2);

    return PitchSample(
      hz: frequency,
      note: _midiToNote(nearestMidi),
      cents: cents,
      confidence: (rms * 2).clamp(0.0, 1.0),
      timestampMs: timestampMs,
    );
  }

  double _rms(Float32List samples) {
    var sum = 0.0;
    for (final value in samples) {
      sum += value * value;
    }
    return sqrt(sum / samples.length);
  }

  double _autocorrelate(Float32List samples, int sampleRateHz) {
    final size = samples.length;
    final minLag = (sampleRateHz / 1200).floor();
    final maxLag = (sampleRateHz / 50).ceil().clamp(1, size - 1);
    var bestLag = -1;
    var bestCorrelation = 0.0;

    for (var lag = minLag; lag <= maxLag; lag++) {
      var correlation = 0.0;
      for (var i = 0; i < size - lag; i++) {
        correlation += samples[i] * samples[i + lag];
      }
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestLag = lag;
      }
    }

    if (bestLag <= 0) {
      return 0.0;
    }
    return sampleRateHz / bestLag;
  }

  String _midiToNote(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final index = ((midi % 12) + 12) % 12;
    final octave = (midi ~/ 12) - 1;
    return '${names[index]}$octave';
  }
}
