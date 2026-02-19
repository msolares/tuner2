import 'dart:async';
import 'dart:math';

import '../../../domain/entities/pitch_sample.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/services/tuner_engine.dart';

class SimulatedTunerEngine implements TunerEngine {
  StreamController<PitchSample> _controller = StreamController<PitchSample>.broadcast();
  Timer? _timer;
  int _tick = 0;
  TunerSettings _settings = TunerSettings.defaults;

  @override
  Future<void> start(TunerSettings settings) async {
    _settings = settings;
    if (_controller.isClosed) {
      _controller = StreamController<PitchSample>.broadcast();
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _tick++;
      final swing = sin(_tick / 3.0) * 12.0;
      final confidence = (0.78 + sin(_tick / 7.0) * 0.2).clamp(0.0, 1.0);
      final hz = _settings.a4Hz * pow(2.0, swing / 1200.0);
      _controller.add(
        PitchSample(
          hz: hz.toDouble(),
          note: 'A4',
          cents: swing.toDouble(),
          confidence: confidence.toDouble(),
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  @override
  Stream<PitchSample> samples() => _controller.stream;

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }
}
