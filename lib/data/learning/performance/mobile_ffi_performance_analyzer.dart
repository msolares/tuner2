import 'dart:async';

import '../../../domain/learning/lesson_errors.dart';
import '../../../domain/learning/lesson_ports.dart';
import '../../../domain/learning/performance.dart';
import '../../audio/audio_frame_source.dart';
import '../../audio/audio_pcm_frame.dart';
import 'dart_ffi_performance_bindings.dart';
import 'performance_ffi_bindings.dart';

typedef PerformanceFfiBindingsLoader = PerformanceFfiBindings? Function();

final class MobileFfiPerformanceAnalyzer implements PerformanceAnalyzer {
  MobileFfiPerformanceAnalyzer({
    required AudioFrameSource frameSource,
    PerformanceFfiBindings? bindings,
    PerformanceFfiBindingsLoader? bindingsLoader,
  })  : _frameSource = frameSource,
        _injectedBindings = bindings,
        _bindingsLoader = bindingsLoader ?? DartFfiPerformanceBindings.tryOpen;

  final AudioFrameSource _frameSource;
  final PerformanceFfiBindings? _injectedBindings;
  final PerformanceFfiBindingsLoader _bindingsLoader;
  final StreamController<PerformanceObservation> _controller =
      StreamController<PerformanceObservation>.broadcast();

  Future<void> _lifecycle = Future<void>.value();
  StreamSubscription<AudioPcmFrame>? _frameSubscription;
  PerformanceFfiBindings? _activeBindings;
  PerformanceAnalyzerSettings? _settings;
  PerformanceTarget? _target;
  int _handle = 0;
  bool _started = false;
  bool _acceptFrames = false;

  @override
  Stream<PerformanceObservation> observations() => _controller.stream;

  @override
  Future<void> start(PerformanceAnalyzerSettings settings) {
    return _serialize(() async {
      if (_started && _settings == settings) {
        return;
      }
      await _stopInternal(clearTarget: false);
      final bindings = _injectedBindings ?? _bindingsLoader();
      if (bindings == null) {
        throw const LessonException(
          LessonErrorCode.performanceAnalyzerUnavailable,
          context: 'performance_ffi_library_unavailable',
        );
      }

      _activeBindings = bindings;
      _settings = settings;
      _handle = bindings.init(settings);
      if (_handle == 0) {
        _activeBindings = null;
        throw const LessonException(
          LessonErrorCode.performanceAnalyzerUnavailable,
          context: 'performance_init_failed',
        );
      }

      try {
        final targetCode = bindings.setTarget(
          _handle,
          _target == null ? null : _mapTarget(_target!),
        );
        _requireOk(targetCode, 'performance_set_target');
        _frameSubscription = _frameSource.frames().listen(
              _onFrame,
              onError: _onCaptureError,
              cancelOnError: false,
            );
        await _frameSource.start();
        _started = true;
        _acceptFrames = true;
      } catch (error, stackTrace) {
        try {
          await _stopInternal(clearTarget: false);
        } catch (_) {
          // Preserve the start error; cleanup was still attempted in full.
        }
        Error.throwWithStackTrace(_mapError(error), stackTrace);
      }
    });
  }

  @override
  Future<void> setTarget(PerformanceTarget? target) {
    return _serialize(() async {
      if (_target == target) {
        return;
      }
      if (!_started) {
        _target = target;
        return;
      }
      final bindings = _activeBindings;
      if (bindings == null || _handle == 0) {
        throw const LessonException(
          LessonErrorCode.performanceAnalyzerUnavailable,
          context: 'performance_handle_unavailable',
        );
      }
      try {
        final code = bindings.setTarget(
          _handle,
          target == null ? null : _mapTarget(target),
        );
        _requireOk(code, 'performance_set_target');
        _target = target;
      } catch (error, stackTrace) {
        try {
          await _stopInternal(clearTarget: false);
        } catch (_) {
          // Preserve the target error; cleanup was still attempted in full.
        }
        Error.throwWithStackTrace(_mapError(error), stackTrace);
      }
    });
  }

  @override
  Future<void> stop() {
    return _serialize(() => _stopInternal(clearTarget: true));
  }

  void _onFrame(AudioPcmFrame frame) {
    if (!_acceptFrames || !_started) {
      return;
    }
    try {
      final bindings = _activeBindings;
      if (bindings == null || _handle == 0) {
        throw const LessonException(
          LessonErrorCode.performanceAnalyzerUnavailable,
          context: 'performance_handle_unavailable',
        );
      }
      final result = bindings.processFrame(
        _handle,
        frame.pcmFloat32,
        frame.sampleRateHz,
        frame.timestampMs,
      );
      _requireOk(result.errorCode, 'performance_process_frame');
      final observation = _mapObservation(result);
      if (observation != null) {
        _controller.add(observation);
      }
    } catch (error, stackTrace) {
      _failStream(error, stackTrace);
    }
  }

  void _onCaptureError(Object error, StackTrace stackTrace) {
    _failStream(error, stackTrace);
  }

  void _failStream(Object error, StackTrace stackTrace) {
    if (!_acceptFrames) {
      return;
    }
    _acceptFrames = false;
    _controller.addError(_mapError(error), stackTrace);
    unawaited(_serialize(() => _stopInternal(clearTarget: false)));
  }

  Future<void> _stopInternal({required bool clearTarget}) async {
    _acceptFrames = false;
    _started = false;
    final subscription = _frameSubscription;
    final bindings = _activeBindings;
    final handle = _handle;
    final hadResources = _started || subscription != null || handle != 0;
    _frameSubscription = null;
    _activeBindings = null;
    _handle = 0;
    _settings = null;
    if (clearTarget) {
      _target = null;
    }

    Object? firstError;
    StackTrace? firstStackTrace;
    Future<void> capture(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    await capture(() async => subscription?.cancel());
    if (hadResources) {
      await capture(_frameSource.stop);
    }
    if (bindings != null && handle != 0) {
      await capture(() async {
        _requireOk(bindings.dispose(handle), 'performance_dispose');
      });
    }
    if (firstError != null) {
      Error.throwWithStackTrace(
        _mapError(firstError!),
        firstStackTrace ?? StackTrace.current,
      );
    }
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final completer = Completer<void>();
    _lifecycle = _lifecycle.then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  PerformanceFfiTarget _mapTarget(PerformanceTarget target) {
    return switch (target) {
      NotePerformanceTarget note => PerformanceFfiTarget.note(note.midi),
      ChordPerformanceTarget chord =>
        PerformanceFfiTarget.chord(chord.requiredPitchClasses),
    };
  }

  PerformanceObservation? _mapObservation(PerformanceFfiResult result) {
    return switch (result.kind) {
      PerformanceFfiObservationKind.none => null,
      PerformanceFfiObservationKind.note => NotePerformanceObservation(
          timestampMs: result.timestampMs,
          onsetSequence: result.onsetSequence,
          confidence: result.confidence,
          hz: result.hz,
          midi: result.midi,
          cents: result.cents,
        ),
      PerformanceFfiObservationKind.chord => ChordPerformanceObservation(
          timestampMs: result.timestampMs,
          onsetSequence: result.onsetSequence,
          confidence: result.confidence,
          pitchClassStrengths: result.pitchClassStrengths,
          onsetConfidence: result.onsetConfidence,
        ),
      null => throw const LessonException(
          LessonErrorCode.performanceAnalyzerUnavailable,
          context: 'performance_invalid_observation_kind',
        ),
    };
  }

  void _requireOk(int code, String operation) {
    if (code != PerformanceFfiErrorCode.ok) {
      throw LessonException(
        LessonErrorCode.performanceAnalyzerUnavailable,
        context: '${operation}_error_$code',
      );
    }
  }

  LessonException _mapError(Object error) {
    if (error is LessonException) {
      return error;
    }
    final normalized = error.toString().toLowerCase();
    if (normalized.contains('permission')) {
      return const LessonException(LessonErrorCode.audioPermissionDenied);
    }
    return LessonException(
      LessonErrorCode.performanceAnalyzerUnavailable,
      context: error.runtimeType.toString(),
    );
  }
}
