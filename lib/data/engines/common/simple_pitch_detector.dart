import 'dart:math';
import 'dart:typed_data';

import '../../../domain/entities/pitch_sample.dart';

class SimplePitchDetector {
  PitchSample? detect({
    required Float32List pcm,
    required int sampleRateHz,
    required double a4Hz,
    required int timestampMs,
    double? noiseGateDb,
    double? minFrequencyHz,
    double? maxFrequencyHz,
  }) {
    if (pcm.isEmpty || sampleRateHz <= 0) {
      return null;
    }
    final rms = _rms(pcm);
    final gateDb = noiseGateDb ?? -60.0;
    final rmsDb = _toDb(rms);
    if (rmsDb < gateDb) {
      return _silenceSample(timestampMs);
    }

    final minHz = (minFrequencyHz ?? 50.0).clamp(20.0, 4000.0).toDouble();
    final maxHz = (maxFrequencyHz ?? 1200.0).clamp(minHz + 1.0, 4000.0).toDouble();
    final autocorrelation = _autocorrelate(
      pcm,
      sampleRateHz,
      minFrequencyHz: minHz,
      maxFrequencyHz: maxHz,
    );
    final frequency = autocorrelation.frequencyHz;
    if (frequency <= 0) {
      return _silenceSample(timestampMs);
    }
    if (minFrequencyHz != null && frequency < minFrequencyHz) {
      return _silenceSample(timestampMs);
    }
    if (maxFrequencyHz != null && frequency > maxFrequencyHz) {
      return _silenceSample(timestampMs);
    }

    final midi = 69 + 12 * (log(frequency / a4Hz) / ln2);
    final nearestMidi = midi.round();
    final nearestHz = a4Hz * pow(2.0, (nearestMidi - 69) / 12.0);
    final cents = 1200 * (log(frequency / nearestHz) / ln2);
    final confidence = _confidenceFromSignal(
      rmsDb: rmsDb,
      gateDb: gateDb,
      normalizedCorrelation: autocorrelation.normalizedCorrelation,
    );

    return PitchSample(
      hz: frequency,
      note: _midiToNote(nearestMidi),
      cents: cents,
      confidence: confidence,
      timestampMs: timestampMs,
    );
  }

  PitchSample _silenceSample(int timestampMs) {
    return PitchSample(
      hz: 0,
      note: '--',
      cents: 0,
      confidence: 0,
      timestampMs: timestampMs,
    );
  }

  double _confidenceFromSignal({
    required double rmsDb,
    required double gateDb,
    required double normalizedCorrelation,
  }) {
    final levelConfidence = ((rmsDb - gateDb) / 24.0).clamp(0.0, 1.0);
    final toneConfidence = ((normalizedCorrelation - 0.12) / 0.50).clamp(0.0, 1.0);
    return (0.4 * levelConfidence + 0.6 * toneConfidence).clamp(0.0, 1.0);
  }

  double _rms(Float32List samples) {
    var sum = 0.0;
    for (final value in samples) {
      sum += value * value;
    }
    return sqrt(sum / samples.length);
  }

  double _toDb(double amplitude) {
    final clamped = amplitude <= 0 ? 1e-12 : amplitude;
    return 20 * (log(clamped) / log(10));
  }

  _AutocorrelationResult _autocorrelate(
    Float32List samples,
    int sampleRateHz, {
    required double minFrequencyHz,
    required double maxFrequencyHz,
  }) {
    final size = samples.length;
    if (size < 32) {
      return const _AutocorrelationResult(0.0, 0.0);
    }
    final mean = samples.reduce((a, b) => a + b) / size;
    final centered = Float32List(size);
    for (var i = 0; i < size; i++) {
      centered[i] = samples[i] - mean;
    }

    final minLag = (sampleRateHz / maxFrequencyHz).floor().clamp(1, size - 3);
    final maxLag = (sampleRateHz / minFrequencyHz).ceil().clamp(minLag + 1, size - 2);
    final correlations = List<double>.filled(maxLag - minLag + 1, 0.0);

    for (var lag = minLag; lag <= maxLag; lag++) {
      var correlation = 0.0;
      var leftEnergy = 0.0;
      var rightEnergy = 0.0;
      for (var i = 0; i < size - lag; i++) {
        final left = centered[i];
        final right = centered[i + lag];
        correlation += left * right;
        leftEnergy += left * left;
        rightEnergy += right * right;
      }
      final normalizer = sqrt(leftEnergy * rightEnergy);
      if (normalizer <= 1e-12) {
        continue;
      }
      correlation /= normalizer;
      correlations[lag - minLag] = correlation;
    }

    final peak = _selectPeak(correlations);
    var bestIndex = peak.index;
    final bestCorrelation = peak.correlation;

    if (bestIndex < 0 || bestCorrelation < 0.10) {
      return const _AutocorrelationResult(0.0, 0.0);
    }

    final lag = minLag + bestIndex;
    var refinedLag = lag.toDouble();
    if (bestIndex > 0 && bestIndex + 1 < correlations.length) {
      final y1 = correlations[bestIndex - 1];
      final y2 = correlations[bestIndex];
      final y3 = correlations[bestIndex + 1];
      final denominator = (y1 - 2 * y2 + y3);
      if (denominator.abs() > 1e-6) {
        final delta = (0.5 * (y1 - y3) / denominator).clamp(-0.5, 0.5);
        refinedLag += delta;
      }
    }

    return _AutocorrelationResult(sampleRateHz / refinedLag, bestCorrelation.clamp(0.0, 1.0));
  }

  _PeakResult _selectPeak(List<double> correlations) {
    if (correlations.isEmpty) {
      return const _PeakResult(index: -1, correlation: 0.0);
    }
    if (correlations.length < 3) {
      var bestIndex = 0;
      var bestValue = correlations.first;
      for (var i = 1; i < correlations.length; i++) {
        if (correlations[i] > bestValue) {
          bestValue = correlations[i];
          bestIndex = i;
        }
      }
      return _PeakResult(index: bestIndex, correlation: bestValue);
    }

    var globalIndex = 0;
    var globalValue = correlations.first;
    for (var i = 1; i < correlations.length; i++) {
      if (correlations[i] > globalValue) {
        globalValue = correlations[i];
        globalIndex = i;
      }
    }

    final strongPeakThreshold = (globalValue * 0.65).clamp(0.12, 0.98);
    for (var i = 1; i < correlations.length - 1; i++) {
      final current = correlations[i];
      final isLocalPeak = current > correlations[i - 1] && current >= correlations[i + 1];
      if (isLocalPeak && current >= strongPeakThreshold) {
        return _PeakResult(index: i, correlation: current);
      }
    }

    return _PeakResult(index: globalIndex, correlation: globalValue);
  }

  String _midiToNote(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final index = ((midi % 12) + 12) % 12;
    final octave = (midi ~/ 12) - 1;
    return '${names[index]}$octave';
  }
}

class _AutocorrelationResult {
  const _AutocorrelationResult(this.frequencyHz, this.normalizedCorrelation);

  final double frequencyHz;
  final double normalizedCorrelation;
}

class _PeakResult {
  const _PeakResult({
    required this.index,
    required this.correlation,
  });

  final int index;
  final double correlation;
}
