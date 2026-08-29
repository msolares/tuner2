import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/pitch_sample.dart';
import '../../../domain/services/tuner_engine.dart';
import '../../../domain/services/tuner_engine_exception.dart';
import '../../audio/audio_frame_source.dart';
import '../../audio/audio_capture_profile.dart';
import '../../audio/create_web_audio_frame_source.dart';
import '../common/analysis_window_buffer.dart';
import '../common/pitch_emission_gate.dart';
import '../common/pitch_range.dart';
import '../common/pitch_reliability_gate.dart';
import '../common/pitch_reliability_profile.dart';
import '../common/pitch_stabilization_profile.dart';
import '../common/pitch_stabilizer.dart';
import '../common/simple_pitch_detector.dart';

class WebTunerEngine implements TunerEngine {
  WebTunerEngine({
    AudioFrameSource? frameSource,
    SimplePitchDetector? detector,
    AnalysisWindowBuffer? analysisWindowBuffer,
    PitchEmissionGate? emissionGate,
    PitchReliabilityGate? reliabilityGate,
    PitchStabilizer? stabilizer,
  })  : _frameSource = frameSource ??
            createWebAudioFrameSource(
              profile: kAudioCaptureProfiles[AudioCapturePlatform.web],
            ),
        _detector = detector ?? SimplePitchDetector(),
        _analysisWindowBuffer = analysisWindowBuffer ?? AnalysisWindowBuffer(),
        _emissionGate = emissionGate ?? PitchEmissionGate(),
        _reliabilityGate = reliabilityGate ?? PitchReliabilityGate(),
        _stabilizer = stabilizer ?? PitchStabilizer();

  final AudioFrameSource _frameSource;
  final SimplePitchDetector _detector;
  final AnalysisWindowBuffer _analysisWindowBuffer;
  final PitchEmissionGate _emissionGate;
  final PitchReliabilityGate _reliabilityGate;
  final PitchStabilizer _stabilizer;
  StreamController<PitchSample> _controller =
      StreamController<PitchSample>.broadcast();
  StreamSubscription? _subscription;
  TunerSettings _settings = TunerSettings.defaults;
  bool _started = false;
  int? _lastTraceTimestampMs;

  @override
  Future<void> start(TunerSettings settings) async {
    _settings = settings;
    if (_controller.isClosed) {
      _controller = StreamController<PitchSample>.broadcast();
    }
    if (_started) {
      _analysisWindowBuffer.reset();
      _emissionGate.reset();
      _reliabilityGate.reset();
      _stabilizer.reset();
      return;
    }
    _analysisWindowBuffer.reset();
    _emissionGate.reset();
    _reliabilityGate.reset();
    _stabilizer.reset();
    await _frameSource.start();
    _subscription = _frameSource.frames().listen(
      (frame) {
        final range = rangeForPreset(_settings.instrumentPreset);
        final analysisFrame = _analysisWindowBuffer.push(
          frame,
          windowFrames:
              analysisWindowFramesForPreset(_settings.instrumentPreset),
        );
        if (analysisFrame == null) {
          return;
        }
        final sample = _detector.detect(
          pcm: analysisFrame.pcmFloat32,
          sampleRateHz: analysisFrame.sampleRateHz,
          a4Hz: _settings.a4Hz,
          timestampMs: analysisFrame.timestampMs,
          noiseGateDb: _settings.noiseGateDb,
          minFrequencyHz: range.minHz,
          maxFrequencyHz: range.maxHz,
        );
        if (sample != null) {
          final gated = _reliabilityGate.filter(
            sample: sample,
            profile: reliabilityProfileForPreset(_settings.instrumentPreset),
          );
          final profile =
              stabilizationProfileForPreset(_settings.instrumentPreset);
          final stabilized = _stabilizer.stabilize(
            sample: gated,
            range: range,
            smoothing: _settings.smoothing,
            profile: profile,
          );
          _tracePipeline(sample, gated, stabilized);
          if (_emissionGate.shouldEmit(
            sample: stabilized,
            profile: profile,
          )) {
            _controller.add(stabilized);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _controller.addError(_toEngineException(error), stackTrace);
      },
      cancelOnError: false,
    );
    _started = true;
  }

  @override
  Stream<PitchSample> samples() => _controller.stream;

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _frameSource.stop();
    _started = false;
    _analysisWindowBuffer.reset();
    _emissionGate.reset();
    _reliabilityGate.reset();
    _stabilizer.reset();
  }

  bool get isStarted => _started;
  TunerSettings get currentSettings => _settings;

  void _tracePipeline(
    PitchSample detected,
    PitchSample gated,
    PitchSample stabilized,
  ) {
    final lastTraceTimestampMs = _lastTraceTimestampMs;
    if (!kDebugMode ||
        (lastTraceTimestampMs != null &&
            detected.timestampMs - lastTraceTimestampMs < 250)) {
      return;
    }
    _lastTraceTimestampMs = detected.timestampMs;
    debugPrint(
      'TUNER_TRACE preset=${_settings.instrumentPreset} '
      'detected=${detected.note}/${detected.hz.toStringAsFixed(2)}/'
      '${detected.cents.toStringAsFixed(1)}/'
      '${detected.confidence.toStringAsFixed(2)} '
      'gated=${gated.note}/${gated.hz.toStringAsFixed(2)}/'
      '${gated.cents.toStringAsFixed(1)}/${gated.confidence.toStringAsFixed(2)} '
      'stable=${stabilized.note}/${stabilized.hz.toStringAsFixed(2)}/'
      '${stabilized.cents.toStringAsFixed(1)}/'
      '${stabilized.confidence.toStringAsFixed(2)}',
    );
  }

  TunerEngineException _toEngineException(Object error) {
    if (error is TunerEngineException) {
      return error;
    }
    final text = error.toString().toLowerCase();
    if (text.contains('permission')) {
      return const TunerEngineException('audio_permission_denied');
    }
    return const TunerEngineException('audio_device_unavailable');
  }
}
