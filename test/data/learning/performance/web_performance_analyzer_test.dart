import 'dart:async';
import 'dart:typed_data';

import 'package:afinador/data/audio/audio_frame_source.dart';
import 'package:afinador/data/audio/audio_pcm_frame.dart';
import 'package:afinador/data/learning/performance/web_performance_analysis_kernel.dart';
import 'package:afinador/data/learning/performance/web_performance_analyzer.dart';
import 'package:afinador/domain/learning/lesson_errors.dart';
import 'package:afinador/domain/learning/performance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebPerformanceAnalyzer', () {
    test('start, target and stop are idempotent', () async {
      final source = _FakeAudioFrameSource();
      final kernel = _FakeFrameAnalyzer();
      final analyzer = WebPerformanceAnalyzer(
        frameSource: source,
        frameAnalyzer: kernel,
      );
      final settings = PerformanceAnalyzerSettings(a4Hz: 440);
      final target = NotePerformanceTarget(eventId: 'a', midi: 69);

      await analyzer.setTarget(target);
      await analyzer.start(settings);
      await analyzer.start(settings);
      await analyzer.setTarget(target);
      await analyzer.stop();
      await analyzer.stop();

      expect(source.startCalls, 1);
      expect(source.stopCalls, 1);
      expect(kernel.targets.whereType<NotePerformanceTarget>(), hasLength(1));
    });

    test('emits equivalent note and chord observation shapes', () async {
      final source = _FakeAudioFrameSource();
      final kernel = _FakeFrameAnalyzer();
      final analyzer = WebPerformanceAnalyzer(
        frameSource: source,
        frameAnalyzer: kernel,
      );
      final values = <PerformanceObservation>[];
      final subscription = analyzer.observations().listen(values.add);
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));

      await analyzer.setTarget(NotePerformanceTarget(eventId: 'a', midi: 69));
      kernel.next = NotePerformanceObservation(
        timestampMs: 100,
        onsetSequence: 1,
        confidence: 0.9,
        hz: 440,
        midi: 69,
        cents: 0,
      );
      source.emit(_frame(100));
      await _flushEvents();

      await analyzer.setTarget(
        ChordPerformanceTarget(
          eventId: 'c',
          requiredPitchClasses: const {0, 4, 7},
        ),
      );
      kernel.next = ChordPerformanceObservation(
        timestampMs: 200,
        onsetSequence: 2,
        confidence: 0.8,
        pitchClassStrengths: const [1, 0, 0, 0, 0.8, 0, 0, 0.9, 0, 0, 0, 0],
        onsetConfidence: 0.7,
      );
      source.emit(_frame(200));
      await _flushEvents();

      expect(values, [
        isA<NotePerformanceObservation>(),
        isA<ChordPerformanceObservation>()
      ]);
      expect((values.last as ChordPerformanceObservation).pitchClassStrengths,
          hasLength(12));
      await analyzer.stop();
      await subscription.cancel();
    });

    test('keeps only the latest pending frame while processing', () async {
      final source = _FakeAudioFrameSource();
      final kernel = _FakeFrameAnalyzer();
      final analyzer = WebPerformanceAnalyzer(
        frameSource: source,
        frameAnalyzer: kernel,
      );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      await analyzer.setTarget(NotePerformanceTarget(eventId: 'a', midi: 69));

      for (var timestamp = 1; timestamp <= 100; timestamp++) {
        source.emit(_frame(timestamp));
      }
      await _flushEvents();

      expect(kernel.processedTimestamps.length, lessThanOrEqualTo(1));
      expect(kernel.processedTimestamps.last, 100);
      await analyzer.stop();
    });

    test('stop waits for in-flight DSP and suppresses its late result',
        () async {
      final source = _FakeAudioFrameSource();
      final kernel = _FakeFrameAnalyzer()..blocker = Completer<void>();
      final analyzer = WebPerformanceAnalyzer(
        frameSource: source,
        frameAnalyzer: kernel,
      );
      final values = <PerformanceObservation>[];
      final subscription = analyzer.observations().listen(values.add);
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      await analyzer.setTarget(NotePerformanceTarget(eventId: 'a', midi: 69));
      kernel.next = NotePerformanceObservation(
        timestampMs: 1,
        onsetSequence: 1,
        confidence: 0.9,
        hz: 440,
        midi: 69,
        cents: 0,
      );
      source.emit(_frame(1));
      await Future<void>.delayed(Duration.zero);

      final stopped = analyzer.stop();
      var stopCompleted = false;
      unawaited(stopped.then((_) => stopCompleted = true));
      await Future<void>.delayed(Duration.zero);
      expect(stopCompleted, isFalse);
      kernel.blocker!.complete();
      await stopped;

      expect(values, isEmpty);
      expect(source.stopCalls, 1);
      await subscription.cancel();
    });

    test('maps permission errors and releases Web capture', () async {
      final source = _FakeAudioFrameSource();
      final analyzer = WebPerformanceAnalyzer(
        frameSource: source,
        frameAnalyzer: _FakeFrameAnalyzer(),
      );
      final error = Completer<Object>();
      final subscription = analyzer.observations().listen(
            (_) {},
            onError: error.complete,
          );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      source.emitError(StateError('NotAllowedError: microphone permission'));

      expect(
        await error.future,
        const LessonException(LessonErrorCode.audioPermissionDenied),
      );
      await _flushEvents();
      expect(source.stopCalls, 1);
      await subscription.cancel();
    });

    test('processing failure is typed and releases resources', () async {
      final source = _FakeAudioFrameSource();
      final kernel = _FakeFrameAnalyzer()..error = const FormatException('bad');
      final analyzer = WebPerformanceAnalyzer(
        frameSource: source,
        frameAnalyzer: kernel,
      );
      final error = Completer<Object>();
      final subscription = analyzer.observations().listen(
            (_) {},
            onError: error.complete,
          );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      source.emit(_frame(1));

      expect(
        await error.future,
        isA<LessonException>().having(
          (value) => value.code,
          'code',
          LessonErrorCode.performanceAnalyzerUnavailable,
        ),
      );
      await _flushEvents();
      expect(source.stopCalls, 1);
      await subscription.cancel();
    });
  });
}

AudioPcmFrame _frame(int timestampMs) => AudioPcmFrame(
      pcmFloat32: Float32List(1024),
      sampleRateHz: 48000,
      timestampMs: timestampMs,
    );

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeAudioFrameSource implements AudioFrameSource {
  final StreamController<AudioPcmFrame> _controller =
      StreamController<AudioPcmFrame>.broadcast(sync: true);
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<AudioPcmFrame> frames() => _controller.stream;

  @override
  Future<void> start() async => startCalls++;

  @override
  Future<void> stop() async => stopCalls++;

  void emit(AudioPcmFrame frame) => _controller.add(frame);

  void emitError(Object error) =>
      _controller.addError(error, StackTrace.current);
}

final class _FakeFrameAnalyzer implements WebPerformanceFrameAnalyzer {
  final List<PerformanceTarget?> targets = [];
  final List<int> processedTimestamps = [];
  PerformanceObservation? next;
  Object? error;
  Completer<void>? blocker;

  @override
  Future<PerformanceObservation?> process(
    AudioPcmFrame frame,
    PerformanceAnalyzerSettings settings,
  ) async {
    processedTimestamps.add(frame.timestampMs);
    if (blocker case final pending?) {
      await pending.future;
    }
    if (error case final processingError?) {
      throw processingError;
    }
    return next;
  }

  @override
  void reset() {}

  @override
  void setTarget(PerformanceTarget? target) => targets.add(target);
}
