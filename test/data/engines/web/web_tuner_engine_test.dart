import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:afinador/data/audio/audio_frame_source.dart';
import 'package:afinador/data/audio/audio_pcm_frame.dart';
import 'package:afinador/data/engines/common/simple_pitch_detector.dart';
import 'package:afinador/data/engines/web/web_tuner_engine.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:afinador/domain/entities/tuner_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebTunerEngine', () {
    test('aplica suavizado temporal cuando llegan frames consecutivos', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: [
          const PitchSample(
            hz: 440.0,
            note: 'A4',
            cents: 10.0,
            confidence: 0.95,
            timestampMs: 100,
          ),
          const PitchSample(
            hz: 450.0,
            note: 'A4',
            cents: 30.0,
            confidence: 0.95,
            timestampMs: 220,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
      );

      final future = engine.samples().take(2).toList();
      await engine.start(
        TunerSettings.defaults.copyWith(
          smoothing: 0.80,
        ),
      );
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      final samples = await future;

      expect(samples, hasLength(2));
      expect(samples.first.hz, closeTo(440.0, 0.001));
      expect(samples.last.hz, closeTo(442.0, 0.01));
      expect(samples.last.cents, closeTo(14.0, 0.01));

      await engine.stop();
    });

    test('retiene brevemente la ultima muestra estable con baja confidence', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: [
          const PitchSample(
            hz: 329.63,
            note: 'E4',
            cents: 1.0,
            confidence: 0.90,
            timestampMs: 100,
          ),
          const PitchSample(
            hz: 0.0,
            note: '--',
            cents: 0.0,
            confidence: 0.10,
            timestampMs: 220,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
      );

      final future = engine.samples().take(2).toList();
      await engine.start(TunerSettings.defaults);
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      final samples = await future;

      expect(samples.first.note, 'E4');
      expect(samples.last.note, 'E4');
      expect(samples.last.hz, closeTo(329.63, 0.01));
      expect(samples.last.confidence, lessThan(samples.first.confidence));

      await engine.stop();
    });

    test('propaga noiseGate y rango por preset hacia el detector', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: const [
          PitchSample(
            hz: 82.4,
            note: 'E2',
            cents: 0.0,
            confidence: 0.90,
            timestampMs: 100,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
      );

      await engine.start(
        TunerSettings.defaults.copyWith(
          instrumentPreset: 'bass_standard',
          noiseGateDb: -52.0,
        ),
      );
      frameSource.emit(_frame(timestampMs: 100));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(detector.calls, isNotEmpty);
      final firstCall = detector.calls.first;
      expect(firstCall.noiseGateDb, -52.0);
      expect(firstCall.minFrequencyHz, 30.0);
      expect(firstCall.maxFrequencyHz, 260.0);

      await engine.stop();
    });

    test('detecta cambio real de nota sin retardo innecesario', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: const [
          PitchSample(
            hz: 82.41,
            note: 'E2',
            cents: 3.0,
            confidence: 0.95,
            timestampMs: 100,
          ),
          PitchSample(
            hz: 110.0,
            note: 'A2',
            cents: 1.0,
            confidence: 0.92,
            timestampMs: 220,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
      );

      final future = engine.samples().take(2).toList();
      await engine.start(TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'));
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      final samples = await future;

      expect(samples.first.note, 'E2');
      expect(samples.last.note, 'A2');

      await engine.stop();
    });
  });
}

AudioPcmFrame _frame({required int timestampMs}) {
  return AudioPcmFrame(
    pcmFloat32: Float32List.fromList(List<double>.filled(1024, 0.1)),
    sampleRateHz: 48000,
    timestampMs: timestampMs,
  );
}

class _FakeAudioFrameSource implements AudioFrameSource {
  final StreamController<AudioPcmFrame> _controller = StreamController<AudioPcmFrame>.broadcast();

  bool started = false;
  bool stopped = false;

  @override
  Stream<AudioPcmFrame> frames() => _controller.stream;

  @override
  Future<void> start() async {
    started = true;
    stopped = false;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    started = false;
  }

  void emit(AudioPcmFrame frame) {
    _controller.add(frame);
  }
}

class _FakePitchDetector extends SimplePitchDetector {
  _FakePitchDetector({
    required List<PitchSample> outputs,
  }) : _outputs = Queue<PitchSample>.from(outputs);

  final Queue<PitchSample> _outputs;
  final List<_DetectorCall> calls = <_DetectorCall>[];

  @override
  PitchSample? detect({
    required Float32List pcm,
    required int sampleRateHz,
    required double a4Hz,
    required int timestampMs,
    double? noiseGateDb,
    double? minFrequencyHz,
    double? maxFrequencyHz,
  }) {
    calls.add(
      _DetectorCall(
        noiseGateDb: noiseGateDb,
        minFrequencyHz: minFrequencyHz,
        maxFrequencyHz: maxFrequencyHz,
      ),
    );
    if (_outputs.isEmpty) {
      return null;
    }
    return _outputs.removeFirst();
  }
}

class _DetectorCall {
  const _DetectorCall({
    required this.noiseGateDb,
    required this.minFrequencyHz,
    required this.maxFrequencyHz,
  });

  final double? noiseGateDb;
  final double? minFrequencyHz;
  final double? maxFrequencyHz;
}

