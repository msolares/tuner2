import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/pitch_sample.dart';

class SimplePitchDetector {
  int? _lastTraceTimestampMs;

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
      _trace(
        timestampMs,
        'below_noise_gate rmsDb=${rmsDb.toStringAsFixed(1)} '
        'gateDb=${gateDb.toStringAsFixed(1)} samples=${pcm.length}',
      );
      return _silenceSample(timestampMs);
    }

    final minHz = (minFrequencyHz ?? 50.0).clamp(20.0, 4000.0).toDouble();
    final maxHz =
        (maxFrequencyHz ?? 1200.0).clamp(minHz + 1.0, 4000.0).toDouble();
    final centered = _centeredSamples(pcm);
    final zeroCrossingRate = _zeroCrossingRate(centered);
    final outcome = _detectFrequency(
      centered,
      sampleRateHz.toDouble(),
      minHz: minHz,
      maxHz: maxHz,
      zeroCrossingRate: zeroCrossingRate,
    );
    final frequency = outcome.frequencyHz;
    if (frequency <= 0) {
      _trace(
        timestampMs,
        'no_pitch rmsDb=${rmsDb.toStringAsFixed(1)} '
        'zcr=${zeroCrossingRate.toStringAsFixed(4)} samples=${pcm.length}',
      );
      return _silenceSample(timestampMs);
    }

    final midi = 69 + 12 * (log(frequency / a4Hz) / ln2);
    final nearestMidi = midi.round();
    final nearestHz = a4Hz * pow(2.0, (nearestMidi - 69) / 12.0);
    final cents = 1200 * (log(frequency / nearestHz) / ln2);
    final confidence = _confidenceFromSignal(
      rmsDb: rmsDb,
      gateDb: gateDb,
      periodicityHint: outcome.periodicityHint,
      clarity: outcome.clarity,
      candidateCount: outcome.candidateCount,
    );
    _trace(
      timestampMs,
      'pitch rmsDb=${rmsDb.toStringAsFixed(1)} '
      'hz=${frequency.toStringAsFixed(2)} '
      'periodicity=${outcome.periodicityHint.toStringAsFixed(2)} '
      'clarity=${outcome.clarity.toStringAsFixed(2)} '
      'candidates=${outcome.candidateCount} '
      'confidence=${confidence.toStringAsFixed(2)}',
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

  void _trace(int timestampMs, String message) {
    final lastTraceTimestampMs = _lastTraceTimestampMs;
    if (!kDebugMode ||
        (lastTraceTimestampMs != null &&
            timestampMs - lastTraceTimestampMs < 250)) {
      return;
    }
    _lastTraceTimestampMs = timestampMs;
    debugPrint('PITCH_TRACE $message');
  }

  double _confidenceFromSignal({
    required double rmsDb,
    required double gateDb,
    required double periodicityHint,
    required double clarity,
    required int candidateCount,
  }) {
    final levelConfidence = ((rmsDb - gateDb) / 24.0).clamp(0.0, 1.0);
    final ambiguityPenalty =
        candidateCount > 1 ? pow(0.92, candidateCount - 1).toDouble() : 1.0;
    final pitchStrength =
        (0.60 * periodicityHint + 0.40 * clarity).clamp(0.0, 1.0) *
            ambiguityPenalty;
    final toneConfidence = ((pitchStrength - 0.18) / 0.55).clamp(0.0, 1.0);
    // El volumen por si solo no demuestra que exista tono. La confianza debe
    // estar dominada por periodicidad/claridad para que ruido fuerte no pase
    // el gate, sin penalizar una cuerda limpia pero grabada a bajo nivel.
    return (0.15 * levelConfidence + 0.85 * toneConfidence).clamp(0.0, 1.0);
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

  List<double> _centeredSamples(Float32List samples) {
    final size = samples.length;
    final mean = samples.reduce((a, b) => a + b) / size;
    return List<double>.generate(size, (index) => samples[index] - mean,
        growable: false);
  }

  double _zeroCrossingRate(List<double> samples) {
    if (samples.length < 2) {
      return 0.0;
    }
    var crossings = 0;
    for (var i = 1; i < samples.length; i++) {
      final previous = samples[i - 1];
      final current = samples[i];
      if ((previous >= 0 && current < 0) || (previous < 0 && current >= 0)) {
        crossings += 1;
      }
    }
    return crossings / (samples.length - 1);
  }

  _DetectorOutcome _detectFrequency(
    List<double> samples,
    double sampleRateHz, {
    required double minHz,
    required double maxHz,
    required double zeroCrossingRate,
  }) {
    if (samples.length < 64 || sampleRateHz <= 0) {
      return const _DetectorOutcome.zero();
    }

    final primary = _detectResolution(samples, sampleRateHz, minHz, maxHz);
    final lowResolution =
        _maybeDetectLowResolution(samples, sampleRateHz, minHz, maxHz);
    final resolution = _selectResolution(primary, lowResolution);
    final bestCandidate = resolution.best;
    if (!bestCandidate.isPresent) {
      return const _DetectorOutcome.zero();
    }
    if (bestCandidate.hz < minHz || bestCandidate.hz > maxHz) {
      return const _DetectorOutcome.zero();
    }

    final ambiguityConfidence =
        _ambiguityConfidence(bestCandidate.score, resolution.secondScore);
    final periodicityHint = (0.55 * bestCandidate.clarity +
            0.25 * ambiguityConfidence +
            0.20 *
                _zeroCrossingAgreement(
                  zeroCrossingRate: zeroCrossingRate,
                  frequencyHz: bestCandidate.hz,
                  sampleRateHz: sampleRateHz,
                ))
        .clamp(0.0, 1.0);

    if (periodicityHint < 0.12 || bestCandidate.clarity < 0.08) {
      return const _DetectorOutcome.zero();
    }

    return _DetectorOutcome(
      frequencyHz: bestCandidate.hz,
      periodicityHint: periodicityHint,
      clarity: bestCandidate.clarity,
      candidateCount: resolution.candidateCount,
    );
  }

  _ResolutionResult _detectResolution(
    List<double> samples,
    double sampleRateHz,
    double minHz,
    double maxHz,
  ) {
    if (samples.length < 64 || sampleRateHz <= 0) {
      return const _ResolutionResult.zero();
    }

    final minLag = (sampleRateHz / maxHz).floor().clamp(2, samples.length - 3);
    final maxLag =
        (sampleRateHz / minHz).ceil().clamp(minLag + 1, samples.length - 2);
    if (maxLag <= minLag) {
      return const _ResolutionResult.zero();
    }

    final difference = _differenceFunction(samples, maxLag);
    final cmndf = _cumulativeMeanNormalizedDifference(difference);
    final candidates = _collectCandidates(
      cmndf,
      minLag: minLag,
      maxLag: maxLag,
      sampleRateHz: sampleRateHz,
      minHz: minHz,
      maxHz: maxHz,
    );
    if (candidates.isEmpty) {
      return const _ResolutionResult.zero();
    }

    final zeroCrossingRate = _zeroCrossingRate(samples);
    _scoreCandidates(
      candidates,
      minLag: minLag.toDouble(),
      maxLag: maxLag.toDouble(),
      zeroCrossingRate: zeroCrossingRate,
      sampleRateHz: sampleRateHz,
    );
    candidates.sort((left, right) {
      final byScore = right.score.compareTo(left.score);
      if (byScore != 0) {
        return byScore;
      }
      return right.clarity.compareTo(left.clarity);
    });

    final best = candidates.first;
    final secondScore = candidates.length > 1 ? candidates[1].score : 0.0;
    return _ResolutionResult(
      best: best,
      secondScore: secondScore,
      candidateCount: candidates.length,
    );
  }

  _ResolutionResult? _maybeDetectLowResolution(
    List<double> samples,
    double sampleRateHz,
    double minHz,
    double maxHz,
  ) {
    if (minHz > 120.0 || samples.length < 1024 || sampleRateHz < 16000.0) {
      return null;
    }

    final decimated = _decimateByTwo(samples);
    if (decimated.length < 256) {
      return null;
    }

    final result =
        _detectResolution(decimated, sampleRateHz * 0.5, minHz, maxHz);
    return result.best.isPresent ? result : null;
  }

  _ResolutionResult _selectResolution(
    _ResolutionResult primary,
    _ResolutionResult? lowResolution,
  ) {
    if (lowResolution == null) {
      return primary;
    }
    if (!primary.best.isPresent) {
      return lowResolution;
    }

    final primaryBest = primary.best;
    final lowBest = lowResolution.best;
    final harmonicFamily = _areHarmonicFamily(primaryBest.hz, lowBest.hz);

    if (lowBest.hz <= 130.0 && lowBest.score + 0.03 >= primaryBest.score) {
      return lowResolution;
    }
    if (harmonicFamily &&
        lowBest.hz < primaryBest.hz &&
        lowBest.score + 0.10 >= primaryBest.score) {
      return lowResolution;
    }
    if (lowBest.score > primaryBest.score) {
      return lowResolution;
    }
    return primary;
  }

  List<double> _differenceFunction(List<double> samples, int maxLag) {
    final difference = List<double>.filled(maxLag + 1, 0.0);
    for (var lag = 1; lag <= maxLag; lag++) {
      var sum = 0.0;
      for (var i = 0; i < samples.length - lag; i++) {
        final delta = samples[i] - samples[i + lag];
        sum += delta * delta;
      }
      difference[lag] = sum;
    }
    return difference;
  }

  List<double> _cumulativeMeanNormalizedDifference(List<double> difference) {
    final cmndf = List<double>.filled(difference.length, 1.0);
    var runningSum = 0.0;
    for (var lag = 1; lag < difference.length; lag++) {
      runningSum += difference[lag];
      cmndf[lag] = runningSum <= 1e-12
          ? 1.0
          : (difference[lag] * lag / runningSum).clamp(0.0, 4.0).toDouble();
    }
    return cmndf;
  }

  List<_Candidate> _collectCandidates(
    List<double> cmndf, {
    required int minLag,
    required int maxLag,
    required double sampleRateHz,
    required double minHz,
    required double maxHz,
  }) {
    if (maxLag <= minLag + 1) {
      return <_Candidate>[];
    }

    var globalBestLag = minLag;
    for (var lag = minLag + 1; lag <= maxLag; lag++) {
      if (cmndf[lag] < cmndf[globalBestLag]) {
        globalBestLag = lag;
      }
    }

    final dynamicThreshold = (cmndf[globalBestLag] * 1.45).clamp(0.08, 0.45);
    final candidates = <_Candidate>[];

    for (var lag = minLag + 1; lag < maxLag; lag++) {
      final current = cmndf[lag];
      final isLocalMinimum =
          current <= cmndf[lag - 1] && current < cmndf[lag + 1];
      if (!isLocalMinimum || current > dynamicThreshold) {
        continue;
      }

      final refinedLag = _refineTrough(lag, cmndf);
      final hz = sampleRateHz / max(refinedLag, 1.0);
      if (hz < minHz || hz > maxHz) {
        continue;
      }

      candidates.add(
        _Candidate(
          lag: refinedLag,
          hz: hz,
          clarity: (1.0 - current).clamp(0.0, 1.0).toDouble(),
          score: 0.0,
        ),
      );
    }

    if (candidates.isEmpty) {
      final refinedLag = _refineTrough(globalBestLag, cmndf);
      final hz = sampleRateHz / max(refinedLag, 1.0);
      final isInteriorCandidate = globalBestLag > minLag &&
          globalBestLag < maxLag &&
          hz > minHz * 1.002 &&
          hz < maxHz * 0.998;
      if (isInteriorCandidate) {
        candidates.add(
          _Candidate(
            lag: refinedLag,
            hz: hz,
            clarity: (1.0 - cmndf[globalBestLag]).clamp(0.0, 1.0).toDouble(),
            score: 0.0,
          ),
        );
      }
    }

    candidates.sort((left, right) {
      final byClarity = right.clarity.compareTo(left.clarity);
      if (byClarity != 0) {
        return byClarity;
      }
      return right.lag.compareTo(left.lag);
    });

    if (candidates.length > 6) {
      return candidates.sublist(0, 6);
    }
    return candidates;
  }

  void _scoreCandidates(
    List<_Candidate> candidates, {
    required double minLag,
    required double maxLag,
    required double zeroCrossingRate,
    required double sampleRateHz,
  }) {
    final lagSpan = max(maxLag - minLag, 1.0);
    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final zeroCrossing = _zeroCrossingAgreement(
        zeroCrossingRate: zeroCrossingRate,
        frequencyHz: candidate.hz,
        sampleRateHz: sampleRateHz,
      );
      final earliestBonus =
          1.0 - ((candidate.lag - minLag) / lagSpan).clamp(0.0, 1.0);
      candidates[i] = candidate.copyWith(
        score: (0.72 * candidate.clarity +
                0.22 * zeroCrossing +
                0.06 * earliestBonus)
            .clamp(0.0, 1.0)
            .toDouble(),
      );
    }
  }

  double _ambiguityConfidence(double bestScore, double secondScore) {
    if (bestScore <= 1e-6) {
      return 0.0;
    }
    if (secondScore <= 1e-6) {
      return 1.0;
    }
    return ((bestScore - secondScore) / bestScore).clamp(0.0, 1.0).toDouble();
  }

  bool _areHarmonicFamily(double hzA, double hzB) {
    final lower = min(hzA, hzB);
    final higher = max(hzA, hzB);
    if (lower <= 0) {
      return false;
    }
    final ratio = higher / lower;
    return (ratio - 2.0).abs() <= 0.14 || (ratio - 3.0).abs() <= 0.20;
  }

  List<double> _decimateByTwo(List<double> samples) {
    final downsampled = <double>[];
    for (var i = 0; i + 1 < samples.length; i += 2) {
      downsampled.add((samples[i] + samples[i + 1]) * 0.5);
    }
    return downsampled;
  }

  double _refineTrough(int lag, List<double> cmndf) {
    if (lag <= 0 || lag + 1 >= cmndf.length) {
      return lag.toDouble();
    }
    final left = cmndf[lag - 1];
    final center = cmndf[lag];
    final right = cmndf[lag + 1];
    final denominator = left - 2 * center + right;
    if (denominator.abs() < 1e-6) {
      return lag.toDouble();
    }
    final delta = (0.5 * (left - right) / denominator).clamp(-0.5, 0.5);
    return max(lag + delta, 1.0);
  }

  double _zeroCrossingAgreement({
    required double zeroCrossingRate,
    required double frequencyHz,
    required double sampleRateHz,
  }) {
    if (frequencyHz <= 0 || sampleRateHz <= 0) {
      return 0.0;
    }
    final expected = (2 * frequencyHz / sampleRateHz).clamp(1e-6, 1.0);
    final ratio = zeroCrossingRate / expected;
    if (!ratio.isFinite || ratio <= 0) {
      return 0.0;
    }
    final distance = (log(ratio) / ln2).abs();
    return (1.0 - distance / 1.1).clamp(0.0, 1.0).toDouble();
  }

  String _midiToNote(int midi) {
    const names = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    final index = ((midi % 12) + 12) % 12;
    final octave = (midi ~/ 12) - 1;
    return '${names[index]}$octave';
  }
}

class _DetectorOutcome {
  const _DetectorOutcome({
    required this.frequencyHz,
    required this.periodicityHint,
    required this.clarity,
    required this.candidateCount,
  });

  const _DetectorOutcome.zero()
      : frequencyHz = 0.0,
        periodicityHint = 0.0,
        clarity = 0.0,
        candidateCount = 0;

  final double frequencyHz;
  final double periodicityHint;
  final double clarity;
  final int candidateCount;
}

class _Candidate {
  const _Candidate({
    required this.lag,
    required this.hz,
    required this.clarity,
    required this.score,
  });

  final double lag;
  final double hz;
  final double clarity;
  final double score;

  bool get isPresent => hz > 0 && clarity > 0;

  _Candidate copyWith({
    double? lag,
    double? hz,
    double? clarity,
    double? score,
  }) {
    return _Candidate(
      lag: lag ?? this.lag,
      hz: hz ?? this.hz,
      clarity: clarity ?? this.clarity,
      score: score ?? this.score,
    );
  }
}

class _ResolutionResult {
  const _ResolutionResult({
    required this.best,
    required this.secondScore,
    required this.candidateCount,
  });

  const _ResolutionResult.zero()
      : best = const _Candidate(
          lag: 0.0,
          hz: 0.0,
          clarity: 0.0,
          score: 0.0,
        ),
        secondScore = 0.0,
        candidateCount = 0;

  final _Candidate best;
  final double secondScore;
  final int candidateCount;
}
