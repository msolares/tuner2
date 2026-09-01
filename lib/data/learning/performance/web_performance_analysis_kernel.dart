import 'dart:math';
import 'dart:typed_data';

import '../../../domain/learning/performance.dart';
import '../../audio/audio_pcm_frame.dart';
import '../../engines/common/simple_pitch_detector.dart';

const int webPerformanceMaxAnalysisSamples = 8192;
const int webPerformanceMaxChromaFrames = 64;

abstract interface class WebPerformanceFrameAnalyzer {
  void reset();

  void setTarget(PerformanceTarget? target);

  Future<PerformanceObservation?> process(
    AudioPcmFrame frame,
    PerformanceAnalyzerSettings settings,
  );
}

/// Implementacion Dart acotada del front-end movil de PerformanceAnalyzer.
///
/// Conserva como maximo 64 frames de chroma, analiza como maximo 8192 muestras
/// y entrega siempre las clases cromaticas en orden C..B.
final class WebPerformanceAnalysisKernel
    implements WebPerformanceFrameAnalyzer {
  WebPerformanceAnalysisKernel({SimplePitchDetector? noteDetector})
      : _noteDetector = noteDetector ?? SimplePitchDetector();

  final SimplePitchDetector _noteDetector;
  final List<_ChromaFrame?> _chromaFrames =
      List<_ChromaFrame?>.filled(webPerformanceMaxChromaFrames, null);

  PerformanceTarget? _target;
  int _nextChromaFrame = 0;
  int _totalSamples = 0;
  double _previousRms = 0;
  int _samplesSinceOnset = 1 << 30;
  int _onsetSequence = 0;
  int? _lastTimestampMs;

  @override
  void reset() {
    _target = null;
    _resetTargetState();
    _previousRms = 0;
    _samplesSinceOnset = 1 << 30;
    _onsetSequence = 0;
    _lastTimestampMs = null;
  }

  @override
  void setTarget(PerformanceTarget? target) {
    if (_target == target) {
      return;
    }
    _target = target;
    _resetTargetState();
  }

  @override
  Future<PerformanceObservation?> process(
    AudioPcmFrame frame,
    PerformanceAnalyzerSettings settings,
  ) async {
    _validateFrame(frame);
    final previousTimestamp = _lastTimestampMs;
    if (previousTimestamp != null && frame.timestampMs < previousTimestamp) {
      throw const FormatException('non_monotonic_timestamp');
    }

    final pcm = _boundedPcm(frame.pcmFloat32);
    final target = _target;
    PerformanceObservation? observation;
    if (target is NotePerformanceTarget) {
      observation = _processNote(frame, pcm, settings);
    } else if (target is ChordPerformanceTarget) {
      observation = await _processChord(frame, pcm);
    }

    _updateOnset(pcm, frame.sampleRateHz);
    _lastTimestampMs = frame.timestampMs;
    if (observation is NotePerformanceObservation) {
      return observation.copyWith(onsetSequence: _onsetSequence);
    }
    if (observation is ChordPerformanceObservation) {
      return observation.copyWith(onsetSequence: _onsetSequence);
    }
    return null;
  }

  PerformanceObservation? _processNote(
    AudioPcmFrame frame,
    Float32List pcm,
    PerformanceAnalyzerSettings settings,
  ) {
    final sample = _noteDetector.detect(
      pcm: pcm,
      sampleRateHz: frame.sampleRateHz,
      a4Hz: settings.a4Hz,
      timestampMs: frame.timestampMs,
      noiseGateDb: -60,
      minFrequencyHz: 50,
      maxFrequencyHz: 1200,
    );
    if (sample == null || sample.hz <= 0) {
      return null;
    }
    final midi = 69 + 12 * (log(sample.hz / settings.a4Hz) / ln2);
    return NotePerformanceObservation(
      timestampMs: frame.timestampMs,
      onsetSequence: _onsetSequence,
      confidence: sample.confidence,
      hz: sample.hz,
      midi: midi.round().clamp(0, 127),
      cents: sample.cents,
    );
  }

  Future<ChordPerformanceObservation> _processChord(
    AudioPcmFrame frame,
    Float32List pcm,
  ) async {
    _totalSamples += pcm.length;
    final rms = _rootMeanSquare(pcm);
    final rmsDb = 20 * log(max(rms, 1e-12)) / ln10;
    final onsetConfidence = _onsetConfidence(_previousRms, rms);
    final result = rmsDb >= -60
        ? await _spectralChroma(pcm, frame.sampleRateHz, rms)
        : _ChromaResult(List<double>.filled(12, 0), 0);

    _chromaFrames[_nextChromaFrame] = _ChromaFrame(
      endSample: _totalSamples,
      strengths: result.strengths,
      confidence: result.confidence,
    );
    _nextChromaFrame = (_nextChromaFrame + 1) % webPerformanceMaxChromaFrames;

    final windowSamples = frame.sampleRateHz * 700 ~/ 1000;
    final accumulated = List<double>.filled(12, 0);
    var confidence = 0.0;
    for (final chromaFrame in _chromaFrames) {
      if (chromaFrame == null ||
          _totalSamples - chromaFrame.endSample > windowSamples) {
        continue;
      }
      for (var index = 0; index < 12; index++) {
        accumulated[index] =
            max(accumulated[index], chromaFrame.strengths[index]);
      }
      confidence = max(confidence, chromaFrame.confidence);
    }

    return ChordPerformanceObservation(
      timestampMs: frame.timestampMs,
      onsetSequence: _onsetSequence,
      confidence: _unit(confidence),
      pitchClassStrengths: accumulated.map(_unit).toList(growable: false),
      onsetConfidence: onsetConfidence,
    );
  }

  Future<_ChromaResult> _spectralChroma(
    Float32List pcm,
    int sampleRateHz,
    double rms,
  ) async {
    const minMidi = 40;
    const maxMidi = 88;
    final mean = pcm.reduce((left, right) => left + right) / pcm.length;
    final raw = List<double>.filled(maxMidi - minMidi + 1, 0);
    for (var midi = minMidi; midi <= maxMidi; midi++) {
      final frequency = 440 * pow(2, (midi - 69) / 12);
      if (frequency < sampleRateHz * 0.48) {
        raw[midi - minMidi] =
            _goertzelAmplitude(pcm, sampleRateHz, frequency, mean);
      }
      if ((midi - minMidi + 1) % 6 == 0) {
        // En Web el DSP Dart comparte isolate con la UI. Los lotes pequenos
        // evitan monopolizar un frame sin cambiar el resultado numerico.
        await Future<void>.delayed(Duration.zero);
      }
    }

    final noteEnergy = List<double>.from(raw);
    for (var index = 0; index < noteEnergy.length; index++) {
      final octaveParent = index >= 12 ? raw[index - 12] * 0.42 : 0;
      final thirdParent = index >= 19 ? raw[index - 19] * 0.22 : 0;
      noteEnergy[index] =
          max(raw[index] - octaveParent - thirdParent, 0).toDouble();
    }

    final chroma = List<double>.filled(12, 0);
    for (var index = 0; index < noteEnergy.length; index++) {
      final pitchClass = (minMidi + index) % 12;
      chroma[pitchClass] = max(chroma[pitchClass], noteEnergy[index]);
    }
    final sorted = List<double>.from(chroma)..sort();
    final noiseFloor = sorted[3] * 0.8;
    for (var index = 0; index < chroma.length; index++) {
      chroma[index] = max(chroma[index] - noiseFloor, 0).toDouble();
    }
    final peak = chroma.reduce(max);
    if (peak <= 1e-8) {
      return _ChromaResult(List<double>.filled(12, 0), 0);
    }
    for (var index = 0; index < chroma.length; index++) {
      chroma[index] = _unit(chroma[index] / peak);
    }
    final activeBins = chroma.where((value) => value >= 0.35).length;
    final spectralQuality =
        (1 - (activeBins - 3).abs() / 9).clamp(0.35, 1).toDouble();
    return _ChromaResult(
      List<double>.unmodifiable(chroma),
      _unit((rms * 12).clamp(0, 1) * spectralQuality),
    );
  }

  double _goertzelAmplitude(
    Float32List pcm,
    int sampleRateHz,
    num frequency,
    double mean,
  ) {
    final omega = 2 * pi * frequency / sampleRateHz;
    final coefficient = 2 * cos(omega);
    final denominator = max(pcm.length - 1, 1);
    var previous = 0.0;
    var previousTwo = 0.0;
    for (var index = 0; index < pcm.length; index++) {
      final hann = 0.5 - 0.5 * cos(2 * pi * index / denominator);
      final current =
          (pcm[index] - mean) * hann + coefficient * previous - previousTwo;
      previousTwo = previous;
      previous = current;
    }
    final power = previousTwo * previousTwo +
        previous * previous -
        coefficient * previous * previousTwo;
    return sqrt(max(power, 0)) * 2 / pcm.length;
  }

  void _updateOnset(Float32List pcm, int sampleRateHz) {
    _samplesSinceOnset = min(
      _samplesSinceOnset + pcm.length,
      1 << 30,
    );
    final rms = _rootMeanSquare(pcm);
    final confidence = _onsetConfidence(_previousRms, rms);
    _previousRms = rms;
    final refractorySamples = sampleRateHz * 50 ~/ 1000;
    if (confidence >= 0.45 && _samplesSinceOnset >= refractorySamples) {
      _onsetSequence++;
      _samplesSinceOnset = 0;
    }
  }

  double _onsetConfidence(double previousRms, double rms) {
    return _unit(max(rms - previousRms, 0) / (rms + 0.01) * 1.5);
  }

  double _rootMeanSquare(Float32List pcm) {
    var sum = 0.0;
    for (final sample in pcm) {
      sum += sample * sample;
    }
    return sqrt(sum / pcm.length);
  }

  Float32List _boundedPcm(Float32List pcm) {
    if (pcm.length <= webPerformanceMaxAnalysisSamples) {
      return pcm;
    }
    return Float32List.sublistView(
      pcm,
      pcm.length - webPerformanceMaxAnalysisSamples,
    );
  }

  void _validateFrame(AudioPcmFrame frame) {
    if (frame.pcmFloat32.length < 256 ||
        frame.sampleRateHz < 8000 ||
        frame.sampleRateHz > 192000 ||
        frame.timestampMs < 0 ||
        frame.pcmFloat32.any((sample) => !sample.isFinite)) {
      throw const FormatException('invalid_performance_frame');
    }
  }

  void _resetTargetState() {
    for (var index = 0; index < _chromaFrames.length; index++) {
      _chromaFrames[index] = null;
    }
    _nextChromaFrame = 0;
    _totalSamples = 0;
  }

  double _unit(num value) {
    if (!value.isFinite) {
      return 0;
    }
    return value.clamp(0, 1).toDouble();
  }
}

final class _ChromaFrame {
  const _ChromaFrame({
    required this.endSample,
    required this.strengths,
    required this.confidence,
  });

  final int endSample;
  final List<double> strengths;
  final double confidence;
}

final class _ChromaResult {
  const _ChromaResult(this.strengths, this.confidence);

  final List<double> strengths;
  final double confidence;
}
