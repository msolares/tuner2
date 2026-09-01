import 'dart:async';
import 'dart:typed_data';

import 'package:afinador/data/audio/audio_frame_source.dart';
import 'package:afinador/data/audio/audio_pcm_frame.dart';
import 'package:afinador/data/learning/performance/mobile_ffi_performance_analyzer.dart';
import 'package:afinador/data/learning/performance/performance_ffi_bindings.dart';
import 'package:afinador/domain/learning/lesson_errors.dart';
import 'package:afinador/domain/learning/performance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MobileFfiPerformanceAnalyzer', () {
    test('start, target and stop are idempotent without duplicate resources',
        () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      final settings = PerformanceAnalyzerSettings(a4Hz: 440);
      final target = NotePerformanceTarget(eventId: 'note-a', midi: 69);

      await analyzer.setTarget(target);
      await analyzer.start(settings);
      await analyzer.start(settings);
      await analyzer.setTarget(target);

      expect(source.startCalls, 1);
      expect(bindings.initCalls, 1);
      expect(bindings.targets, hasLength(1));
      expect(bindings.targets.single?.kind, PerformanceFfiObservationKind.note);
      expect(bindings.targets.single?.midi, 69);

      await analyzer.stop();
      await analyzer.stop();
      expect(source.stopCalls, 1);
      expect(bindings.disposeCalls, [bindings.handle]);
    });

    test('maps note and chord observations and ignores none results', () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      final observations = <PerformanceObservation>[];
      final subscription = analyzer.observations().listen(observations.add);
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));

      await analyzer.setTarget(
        NotePerformanceTarget(eventId: 'note-a', midi: 69),
      );
      bindings.nextResult = _noteResult(timestampMs: 100);
      source.emit(_frame(timestampMs: 100));
      await _flushEvents();

      await analyzer.setTarget(
        ChordPerformanceTarget(
          eventId: 'chord-c',
          requiredPitchClasses: const {7, 0, 4},
        ),
      );
      bindings.nextResult = _chordResult(timestampMs: 220);
      source.emit(_frame(timestampMs: 220));
      await _flushEvents();

      bindings.nextResult = _noneResult(timestampMs: 300);
      source.emit(_frame(timestampMs: 300));
      await _flushEvents();

      expect(observations, hasLength(2));
      final note = observations[0] as NotePerformanceObservation;
      expect(note.midi, 69);
      expect(note.hz, 440);
      final chord = observations[1] as ChordPerformanceObservation;
      expect(chord.pitchClassStrengths, hasLength(12));
      expect(chord.pitchClassStrengths[0], 0.9);
      expect(bindings.targets.last?.pitchClasses, [0, 4, 7]);

      await analyzer.stop();
      await subscription.cancel();
    });

    test('stop and restart replace capture, subscription and native handle',
        () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      final settings = PerformanceAnalyzerSettings(a4Hz: 440);

      await analyzer.start(settings);
      await analyzer.stop();
      await analyzer.start(settings);
      bindings.nextResult = _noteResult(timestampMs: 500);
      await analyzer.setTarget(
        NotePerformanceTarget(eventId: 'note-b', midi: 69),
      );
      final observation = analyzer.observations().first;
      source.emit(_frame(timestampMs: 500));

      expect(await observation, isA<NotePerformanceObservation>());
      expect(source.startCalls, 2);
      expect(source.stopCalls, 1);
      expect(bindings.initCalls, 2);
      expect(bindings.disposeCalls, hasLength(1));
      await analyzer.stop();
      expect(bindings.disposeCalls, hasLength(2));
    });

    test('processing error is typed and releases all owned resources',
        () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      final errorCompleter = Completer<Object>();
      final subscription = analyzer.observations().listen(
            (_) {},
            onError: (Object error) => errorCompleter.complete(error),
          );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      bindings.nextResult = _noteResult(
        timestampMs: 100,
        errorCode: PerformanceFfiErrorCode.invalidFrame,
      );
      source.emit(_frame(timestampMs: 100));

      final error = await errorCompleter.future as LessonException;
      expect(error.code, LessonErrorCode.performanceAnalyzerUnavailable);
      await _flushEvents();
      expect(source.stopCalls, 1);
      expect(bindings.disposeCalls, [bindings.handle]);
      await subscription.cancel();
    });

    test('target error is typed and releases capture and native handle',
        () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      bindings.setTargetCode = PerformanceFfiErrorCode.invalidTarget;

      await expectLater(
        analyzer.setTarget(
          NotePerformanceTarget(eventId: 'note-error', midi: 69),
        ),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.performanceAnalyzerUnavailable,
          ),
        ),
      );
      expect(source.stopCalls, 1);
      expect(bindings.disposeCalls, [bindings.handle]);
    });

    test('capture permission error is typed and releases native handle',
        () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      final errorCompleter = Completer<Object>();
      final subscription = analyzer.observations().listen(
            (_) {},
            onError: (Object error) => errorCompleter.complete(error),
          );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));
      source.emitError(StateError('microphone permission denied'));

      final error = await errorCompleter.future as LessonException;
      expect(error.code, LessonErrorCode.audioPermissionDenied);
      await _flushEvents();
      expect(source.stopCalls, 1);
      expect(bindings.disposeCalls, [bindings.handle]);
      await subscription.cancel();
    });

    test('start failure rolls back subscription, capture and handle', () async {
      final source = _FakeAudioFrameSource()
        ..startError = StateError('audio device unavailable');
      final bindings = _FakePerformanceBindings();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );

      await expectLater(
        analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440)),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.performanceAnalyzerUnavailable,
          ),
        ),
      );
      expect(source.stopCalls, 1);
      expect(bindings.disposeCalls, [bindings.handle]);
    });

    test('unavailable native library fails before opening capture', () async {
      final source = _FakeAudioFrameSource();
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindingsLoader: () => null,
      );

      await expectLater(
        analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440)),
        throwsA(
          isA<LessonException>().having(
            (error) => error.code,
            'code',
            LessonErrorCode.performanceAnalyzerUnavailable,
          ),
        ),
      );
      expect(source.startCalls, 0);
      expect(source.stopCalls, 0);
    });

    test('dispose error is reported after capture and subscription cleanup',
        () async {
      final source = _FakeAudioFrameSource();
      final bindings = _FakePerformanceBindings()
        ..disposeCode = PerformanceFfiErrorCode.invalidHandle;
      final analyzer = MobileFfiPerformanceAnalyzer(
        frameSource: source,
        bindings: bindings,
      );
      await analyzer.start(PerformanceAnalyzerSettings(a4Hz: 440));

      await expectLater(
        analyzer.stop(),
        throwsA(isA<LessonException>()),
      );
      expect(source.stopCalls, 1);
      expect(bindings.disposeCalls, [bindings.handle]);
      await analyzer.stop();
      expect(source.stopCalls, 1);
    });
  });
}

AudioPcmFrame _frame({required int timestampMs}) {
  return AudioPcmFrame(
    pcmFloat32: Float32List.fromList(List<double>.filled(1024, 0.2)),
    sampleRateHz: 48000,
    timestampMs: timestampMs,
  );
}

PerformanceFfiResult _noteResult({
  required int timestampMs,
  int errorCode = PerformanceFfiErrorCode.ok,
}) {
  return PerformanceFfiResult(
    errorCode: errorCode,
    kind: PerformanceFfiObservationKind.note,
    timestampMs: timestampMs,
    onsetSequence: 1,
    confidence: 0.92,
    hz: 440,
    cents: 0.5,
    midi: 69,
    pitchClassStrengths: List<double>.filled(12, 0),
    onsetConfidence: 0,
  );
}

PerformanceFfiResult _chordResult({required int timestampMs}) {
  final strengths = List<double>.filled(12, 0.05);
  strengths[0] = 0.9;
  strengths[4] = 0.8;
  strengths[7] = 1;
  return PerformanceFfiResult(
    errorCode: PerformanceFfiErrorCode.ok,
    kind: PerformanceFfiObservationKind.chord,
    timestampMs: timestampMs,
    onsetSequence: 2,
    confidence: 0.88,
    hz: 0,
    cents: 0,
    midi: -1,
    pitchClassStrengths: strengths,
    onsetConfidence: 0.75,
  );
}

PerformanceFfiResult _noneResult({required int timestampMs}) {
  return PerformanceFfiResult(
    errorCode: PerformanceFfiErrorCode.ok,
    kind: PerformanceFfiObservationKind.none,
    timestampMs: timestampMs,
    onsetSequence: 2,
    confidence: 0,
    hz: 0,
    cents: 0,
    midi: -1,
    pitchClassStrengths: List<double>.filled(12, 0),
    onsetConfidence: 0,
  );
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeAudioFrameSource implements AudioFrameSource {
  final StreamController<AudioPcmFrame> _controller =
      StreamController<AudioPcmFrame>.broadcast();
  int startCalls = 0;
  int stopCalls = 0;
  Object? startError;

  @override
  Stream<AudioPcmFrame> frames() => _controller.stream;

  @override
  Future<void> start() async {
    startCalls++;
    if (startError case final error?) {
      throw error;
    }
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  void emit(AudioPcmFrame frame) => _controller.add(frame);

  void emitError(Object error) =>
      _controller.addError(error, StackTrace.current);
}

final class _FakePerformanceBindings implements PerformanceFfiBindings {
  int handle = 41;
  int initCalls = 0;
  int disposeCode = PerformanceFfiErrorCode.ok;
  int setTargetCode = PerformanceFfiErrorCode.ok;
  final List<PerformanceFfiTarget?> targets = [];
  final List<int> disposeCalls = [];
  PerformanceFfiResult nextResult = _noneResult(timestampMs: 0);

  @override
  int init(PerformanceAnalyzerSettings settings) {
    initCalls++;
    return handle + initCalls - 1;
  }

  @override
  int setTarget(int handle, PerformanceFfiTarget? target) {
    targets.add(target);
    return setTargetCode;
  }

  @override
  PerformanceFfiResult processFrame(
    int handle,
    Float32List pcm,
    int sampleRateHz,
    int timestampMs,
  ) {
    return nextResult;
  }

  @override
  int dispose(int handle) {
    disposeCalls.add(handle);
    return disposeCode;
  }
}
