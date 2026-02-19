import 'dart:async';

import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/pitch_sample.dart';
import '../../../domain/services/tuner_engine.dart';
import '../../audio/audio_capture_profile.dart';
import '../../audio/recorder_audio_frame_source.dart';
import '../common/simple_pitch_detector.dart';

class WebTunerEngine implements TunerEngine {
  WebTunerEngine({
    RecorderAudioFrameSource? frameSource,
    SimplePitchDetector? detector,
  })  : _frameSource = frameSource ??
            RecorderAudioFrameSource(
              profile: kAudioCaptureProfiles[AudioCapturePlatform.web],
            ),
        _detector = detector ?? SimplePitchDetector();

  final RecorderAudioFrameSource _frameSource;
  final SimplePitchDetector _detector;
  StreamController<PitchSample> _controller = StreamController<PitchSample>.broadcast();
  StreamSubscription? _subscription;
  TunerSettings _settings = TunerSettings.defaults;
  bool _started = false;

  @override
  Future<void> start(TunerSettings settings) async {
    _settings = settings;
    if (_controller.isClosed) {
      _controller = StreamController<PitchSample>.broadcast();
    }
    if (_started) {
      return;
    }
    await _frameSource.start();
    _subscription = _frameSource.frames().listen(
      (frame) {
        final sample = _detector.detect(
          pcm: frame.pcmFloat32,
          sampleRateHz: frame.sampleRateHz,
          a4Hz: _settings.a4Hz,
          timestampMs: frame.timestampMs,
        );
        if (sample != null) {
          _controller.add(sample);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _controller.addError(error, stackTrace);
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
  }

  bool get isStarted => _started;
  TunerSettings get currentSettings => _settings;
}
