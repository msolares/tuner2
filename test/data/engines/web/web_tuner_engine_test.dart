import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:afinador/data/audio/audio_frame_source.dart';
import 'package:afinador/data/audio/audio_pcm_frame.dart';
import 'package:afinador/data/engines/common/analysis_window_buffer.dart';
import 'package:afinador/data/engines/common/pitch_reliability_gate.dart';
import 'package:afinador/data/engines/common/pitch_reliability_profile.dart';
import 'package:afinador/data/engines/common/simple_pitch_detector.dart';
import 'package:afinador/data/engines/web/web_tuner_engine.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:afinador/domain/entities/tuner_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebTunerEngine', () {
    test('applies temporal smoothing for consecutive frames', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: [
          const PitchSample(
            hz: 220.0,
            note: 'A3',
            cents: 10.0,
            confidence: 0.95,
            timestampMs: 100,
          ),
          const PitchSample(
            hz: 230.0,
            note: 'A3',
            cents: 30.0,
            confidence: 0.95,
            timestampMs: 220,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
        reliabilityGate: _PassthroughReliabilityGate(),
      );

      final future = engine.samples().take(2).toList();
      await engine.start(TunerSettings.defaults.copyWith(smoothing: 0.80));
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      final samples = await future;

      expect(samples, hasLength(2));
      expect(samples.first.hz, closeTo(220.0, 0.001));
      expect(samples.last.hz, closeTo(223.0, 0.05));
      expect(samples.last.cents, closeTo(16.0, 0.15));

      await engine.stop();
    });

    test('briefly holds the last stable sample on low confidence', () async {
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
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
        reliabilityGate: _PassthroughReliabilityGate(),
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

    test('forwards noise gate and preset range to detector', () async {
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
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
        reliabilityGate: _PassthroughReliabilityGate(),
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

    test('detects a real note change without unnecessary lag', () async {
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
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
        reliabilityGate: _PassthroughReliabilityGate(),
      );

      final future = engine.samples().take(2).toList();
      await engine.start(
          TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'));
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      final samples = await future;

      expect(samples.first.note, 'E2');
      expect(samples.last.note, 'A2');

      await engine.stop();
    });

    test('emits a rapid real note change even inside the base interval',
        () async {
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
            timestampMs: 140,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
        reliabilityGate: _PassthroughReliabilityGate(),
      );

      final future = engine.samples().take(2).toList();
      await engine.start(
        TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'),
      );
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 140));
      final samples = await future;

      expect(samples, hasLength(2));
      expect(samples.first.note, 'E2');
      expect(samples.last.note, 'A2');

      await engine.stop();
    });

    test('resolves harmonic rich E2 with the real detector', () async {
      final frameSource = _FakeAudioFrameSource();
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: SimplePitchDetector(),
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
        reliabilityGate: _PassthroughReliabilityGate(),
      );

      final future = engine.samples().first;
      await engine.start(
          TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'));
      frameSource.emit(
        AudioPcmFrame(
          pcmFloat32: _harmonicWave(
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
          timestampMs: 100,
        ),
      );

      final sample = await future;
      expect(sample.note, 'E2');
      expect(sample.hz, closeTo(82.41, 3.0));

      await engine.stop();
    });

    test('default guitar pipeline emits a real detected E2', () async {
      final frameSource = _FakeAudioFrameSource();
      final engine = WebTunerEngine(frameSource: frameSource);
      final detected = engine
          .samples()
          .firstWhere((sample) => sample.hz > 0 && sample.note == 'E2')
          .timeout(const Duration(milliseconds: 500));

      await engine.start(
          TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'));
      final pcm = _harmonicWave(
        fundamentalHz: 82.41,
        sampleRateHz: 48000,
        len: 12288,
        harmonics: const [
          [1.0, 0.16],
          [2.0, 0.82],
          [3.0, 0.32],
          [4.0, 0.16],
        ],
      );
      for (var offset = 0; offset < pcm.length; offset += 1024) {
        frameSource.emit(
          AudioPcmFrame(
            pcmFloat32: Float32List.sublistView(pcm, offset, offset + 1024),
            sampleRateHz: 48000,
            timestampMs: 100 + offset * 1000 ~/ 48000,
          ),
        );
      }

      final sample = await detected;
      expect(sample.hz, closeTo(82.41, 3.0));
      expect(sample.confidence, greaterThan(0.0));

      await engine.stop();
    });

    test('default guitar preset detects a quiet Web microphone E2', () async {
      final frameSource = _FakeAudioFrameSource();
      final engine = WebTunerEngine(frameSource: frameSource);
      final detected = engine
          .samples()
          .firstWhere((sample) => sample.hz > 0 && sample.note == 'E2')
          .timeout(const Duration(milliseconds: 500));

      await engine.start(TunerSettings.defaults);
      final pcm = _harmonicWave(
        fundamentalHz: 82.41,
        sampleRateHz: 48000,
        len: 12288,
        harmonics: const [
          [1.0, 0.002],
        ],
      );
      for (var offset = 0; offset < pcm.length; offset += 1024) {
        frameSource.emit(
          AudioPcmFrame(
            pcmFloat32: Float32List.sublistView(pcm, offset, offset + 1024),
            sampleRateHz: 48000,
            timestampMs: 100 + offset * 1000 ~/ 48000,
          ),
        );
      }

      final sample = await detected;
      expect(sample.hz, closeTo(82.41, 3.0));

      await engine.stop();
    });

    test('acquires guitar through a brief detector dropout', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: const [
          PitchSample(
            hz: 82.41,
            note: 'E2',
            cents: 0.0,
            confidence: 0.55,
            timestampMs: 100,
          ),
          PitchSample(
            hz: 0.0,
            note: '--',
            cents: 0.0,
            confidence: 0.0,
            timestampMs: 160,
          ),
          PitchSample(
            hz: 82.50,
            note: 'E2',
            cents: 2.0,
            confidence: 0.52,
            timestampMs: 220,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
      );
      final acquired = engine.samples().firstWhere((sample) => sample.hz > 0);

      await engine.start(TunerSettings.defaults);
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 160));
      frameSource.emit(_frame(timestampMs: 220));

      expect((await acquired).note, 'E2');
      await engine.stop();
    });

    test('recovers after chromatic to guitar to chromatic hot changes',
        () async {
      final frameSource = _FakeAudioFrameSource();
      final engine = WebTunerEngine(frameSource: frameSource);

      await engine.start(
        TunerSettings.defaults.copyWith(
          instrumentPreset: 'chromatic',
          smoothing: 0.20,
        ),
      );
      final firstChromatic = engine.samples().firstWhere(
            (sample) => sample.hz > 0 && sample.note == 'A3',
          );
      _emitTone(
        frameSource,
        frequencyHz: 220.0,
        startTimestampMs: 100,
      );
      expect((await firstChromatic).note, 'A3');

      await engine.start(
        TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'),
      );
      final guitar = engine.samples().firstWhere(
            (sample) => sample.hz > 0 && sample.note == 'E2',
          );
      _emitTone(
        frameSource,
        frequencyHz: 82.41,
        startTimestampMs: 1000,
      );
      expect((await guitar).note, 'E2');

      await engine.start(
        TunerSettings.defaults.copyWith(
          instrumentPreset: 'chromatic',
          smoothing: 0.20,
        ),
      );
      final recoveredChromatic = engine.samples().firstWhere(
            (sample) => sample.hz > 0 && sample.note == 'A3',
          );
      _emitTone(
        frameSource,
        frequencyHz: 220.0,
        startTimestampMs: 2000,
      );
      expect((await recoveredChromatic).note, 'A3');

      await engine.stop();
    });

    test('does not leak a transient wrong string once E2 is locked', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: const [
          PitchSample(
            hz: 82.41,
            note: 'E2',
            cents: 5.0,
            confidence: 0.92,
            timestampMs: 100,
          ),
          PitchSample(
            hz: 82.55,
            note: 'E2',
            cents: 8.0,
            confidence: 0.91,
            timestampMs: 220,
          ),
          PitchSample(
            hz: 82.60,
            note: 'E2',
            cents: 9.0,
            confidence: 0.93,
            timestampMs: 340,
          ),
          PitchSample(
            hz: 110.0,
            note: 'A2',
            cents: 1.0,
            confidence: 0.88,
            timestampMs: 460,
          ),
          PitchSample(
            hz: 82.48,
            note: 'E2',
            cents: 6.0,
            confidence: 0.91,
            timestampMs: 580,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
      );

      final future = engine.samples().take(5).toList();
      await engine.start(
          TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'));
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      frameSource.emit(_frame(timestampMs: 340));
      frameSource.emit(_frame(timestampMs: 460));
      frameSource.emit(_frame(timestampMs: 580));
      final samples = await future;

      expect(samples[0].note, '--');
      expect(samples[1].note, 'E2');
      expect(samples[2].note, 'E2');
      expect(samples[3].note, 'E2');
      expect(samples[4].note, 'E2');

      await engine.stop();
    });

    test('switches to A2 after sustained change from E2', () async {
      final frameSource = _FakeAudioFrameSource();
      final detector = _FakePitchDetector(
        outputs: const [
          PitchSample(
            hz: 82.41,
            note: 'E2',
            cents: 5.0,
            confidence: 0.92,
            timestampMs: 100,
          ),
          PitchSample(
            hz: 82.55,
            note: 'E2',
            cents: 8.0,
            confidence: 0.91,
            timestampMs: 220,
          ),
          PitchSample(
            hz: 82.60,
            note: 'E2',
            cents: 9.0,
            confidence: 0.93,
            timestampMs: 340,
          ),
          PitchSample(
            hz: 110.0,
            note: 'A2',
            cents: 3.0,
            confidence: 0.91,
            timestampMs: 460,
          ),
          PitchSample(
            hz: 110.25,
            note: 'A2',
            cents: 6.0,
            confidence: 0.92,
            timestampMs: 580,
          ),
        ],
      );
      final engine = WebTunerEngine(
        frameSource: frameSource,
        detector: detector,
        analysisWindowBuffer: _PassthroughAnalysisWindowBuffer(),
      );

      final future = engine.samples().take(5).toList();
      await engine.start(
          TunerSettings.defaults.copyWith(instrumentPreset: 'guitar_standard'));
      frameSource.emit(_frame(timestampMs: 100));
      frameSource.emit(_frame(timestampMs: 220));
      frameSource.emit(_frame(timestampMs: 340));
      frameSource.emit(_frame(timestampMs: 460));
      frameSource.emit(_frame(timestampMs: 580));
      final samples = await future;

      expect(samples[2].note, 'E2');
      expect(samples[3].note, 'E2');
      expect(samples[4].note, 'A2');

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
        sum += amplitude * sin(phase);
      }
      return sum;
    }),
  );
}

void _emitTone(
  _FakeAudioFrameSource frameSource, {
  required double frequencyHz,
  required int startTimestampMs,
}) {
  final pcm = _harmonicWave(
    fundamentalHz: frequencyHz,
    sampleRateHz: 48000,
    len: 12288,
    harmonics: const [
      [1.0, 0.30],
      [2.0, 0.12],
      [3.0, 0.05],
    ],
  );
  for (var offset = 0; offset < pcm.length; offset += 1024) {
    frameSource.emit(
      AudioPcmFrame(
        pcmFloat32: Float32List.sublistView(pcm, offset, offset + 1024),
        sampleRateHz: 48000,
        timestampMs: startTimestampMs + offset * 1000 ~/ 48000,
      ),
    );
  }
}

class _FakeAudioFrameSource implements AudioFrameSource {
  final StreamController<AudioPcmFrame> _controller =
      StreamController<AudioPcmFrame>.broadcast();

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

class _PassthroughReliabilityGate extends PitchReliabilityGate {
  @override
  PitchSample filter({
    required PitchSample sample,
    required PitchReliabilityProfile profile,
  }) {
    return sample;
  }
}

class _PassthroughAnalysisWindowBuffer extends AnalysisWindowBuffer {
  @override
  AudioPcmFrame? push(
    AudioPcmFrame frame, {
    required int windowFrames,
  }) {
    return frame;
  }
}
