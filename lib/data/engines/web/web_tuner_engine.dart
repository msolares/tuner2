import 'dart:async';

import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/pitch_sample.dart';
import '../../../domain/services/tuner_engine.dart';
import '../../../domain/services/tuner_engine_exception.dart';
import '../../audio/audio_frame_source.dart';
import '../../audio/audio_capture_profile.dart';
import '../../audio/recorder_audio_frame_source.dart';
import '../common/pitch_range.dart';
import '../common/pitch_stabilizer.dart';
import '../common/simple_pitch_detector.dart';

class WebTunerEngine implements TunerEngine {
  WebTunerEngine({
    AudioFrameSource? frameSource,
    SimplePitchDetector? detector,
    PitchStabilizer? stabilizer,
  })  : _frameSource = frameSource ??
            RecorderAudioFrameSource(
              profile: kAudioCaptureProfiles[AudioCapturePlatform.web],
            ),
        _detector = detector ?? SimplePitchDetector(),
        _stabilizer = stabilizer ?? PitchStabilizer();

  final AudioFrameSource _frameSource;
  final SimplePitchDetector _detector;
  final PitchStabilizer _stabilizer;
  StreamController<PitchSample> _controller = StreamController<PitchSample>.broadcast();
  StreamSubscription? _subscription;
  TunerSettings _settings = TunerSettings.defaults;
  bool _started = false;
  static const int _emitIntervalMs = 90;
  int _lastEmittedTimestampMs = 0;

  @override
  Future<void> start(TunerSettings settings) async {
    _settings = settings;
    if (_controller.isClosed) {
      _controller = StreamController<PitchSample>.broadcast();
    }
    if (_started) {
      return;
    }
    _stabilizer.reset();
    _lastEmittedTimestampMs = 0;
    await _frameSource.start();
    _subscription = _frameSource.frames().listen(
      (frame) {
        final range = rangeForPreset(_settings.instrumentPreset);
        final sample = _detector.detect(
          pcm: frame.pcmFloat32,
          sampleRateHz: frame.sampleRateHz,
          a4Hz: _settings.a4Hz,
          timestampMs: frame.timestampMs,
          noiseGateDb: _settings.noiseGateDb,
          minFrequencyHz: range.minHz,
          maxFrequencyHz: range.maxHz,
        );
        if (sample != null) {
          final stabilized = _stabilizer.stabilize(
            sample: sample,
            range: range,
            smoothing: _settings.smoothing,
          );
          if (_shouldEmit(stabilized.timestampMs)) {
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
    _stabilizer.reset();
    _lastEmittedTimestampMs = 0;
  }

  bool get isStarted => _started;
  TunerSettings get currentSettings => _settings;

  bool _shouldEmit(int timestampMs) {
    if (_lastEmittedTimestampMs == 0 || timestampMs - _lastEmittedTimestampMs >= _emitIntervalMs) {
      _lastEmittedTimestampMs = timestampMs;
      return true;
    }
    return false;
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
