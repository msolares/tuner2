import 'dart:async';

import '../../../domain/learning/lesson_errors.dart';
import '../../../domain/learning/lesson_ports.dart';
import '../../../domain/learning/performance.dart';
import '../../audio/audio_capture_profile.dart';
import '../../audio/audio_frame_source.dart';
import '../../audio/audio_pcm_frame.dart';
import '../../audio/create_web_audio_frame_source.dart';
import 'web_performance_analysis_kernel.dart';

final class WebPerformanceAnalyzer implements PerformanceAnalyzer {
  WebPerformanceAnalyzer({
    AudioFrameSource? frameSource,
    WebPerformanceFrameAnalyzer? frameAnalyzer,
  })  : _frameSource = frameSource ??
            createWebAudioFrameSource(
              profile: kAudioCaptureProfiles[AudioCapturePlatform.web],
            ),
        _frameAnalyzer = frameAnalyzer ?? WebPerformanceAnalysisKernel();

  final AudioFrameSource _frameSource;
  final WebPerformanceFrameAnalyzer _frameAnalyzer;
  final StreamController<PerformanceObservation> _controller =
      StreamController<PerformanceObservation>.broadcast();

  Future<void> _lifecycle = Future<void>.value();
  StreamSubscription<AudioPcmFrame>? _frameSubscription;
  PerformanceAnalyzerSettings? _settings;
  PerformanceTarget? _target;
  AudioPcmFrame? _pendingFrame;
  Completer<void>? _drainCompleter;
  int _generation = 0;
  bool _processing = false;
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
      _settings = settings;
      final generation = ++_generation;
      try {
        _frameSubscription = _frameSource.frames().listen(
              (frame) => _onFrame(frame, generation),
              onError: _onCaptureError,
              cancelOnError: false,
            );
        _started = true;
        _acceptFrames = true;
        await _frameSource.start();
      } catch (error, stackTrace) {
        try {
          await _stopInternal(clearTarget: false);
        } catch (_) {
          // Se conserva el error original tras intentar liberar la captura.
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
      _target = target;
      _pendingFrame = null;
      if (_started) {
        _frameAnalyzer.setTarget(target);
      }
    });
  }

  @override
  Future<void> stop() {
    return _serialize(() => _stopInternal(clearTarget: true));
  }

  void _onFrame(AudioPcmFrame frame, int generation) {
    if (!_acceptFrames || !_started || generation != _generation) {
      return;
    }
    // Solo se conserva el frame mas reciente mientras hay DSP en curso. Esto
    // evita backlog y crecimiento de memoria cuando el navegador se ralentiza.
    _pendingFrame = frame;
    if (!_processing) {
      _processing = true;
      _drainCompleter = Completer<void>();
      unawaited(Future<void>(() => _drainFrames(generation)));
    }
  }

  Future<void> _drainFrames(int generation) async {
    try {
      while (_acceptFrames && generation == _generation) {
        final frame = _pendingFrame;
        _pendingFrame = null;
        if (frame == null) {
          break;
        }
        final settings = _settings;
        if (settings == null) {
          break;
        }
        final observation = await _frameAnalyzer.process(frame, settings);
        if (observation != null && _acceptFrames && generation == _generation) {
          _controller.add(observation);
        }
      }
    } catch (error, stackTrace) {
      _failStream(error, stackTrace);
    } finally {
      _processing = false;
      _drainCompleter?.complete();
      _drainCompleter = null;
      if (_pendingFrame != null && _acceptFrames && generation == _generation) {
        _processing = true;
        _drainCompleter = Completer<void>();
        unawaited(Future<void>(() => _drainFrames(generation)));
      }
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
    _pendingFrame = null;
    _controller.addError(_mapError(error), stackTrace);
    unawaited(_serialize(() => _stopInternal(clearTarget: false)));
  }

  Future<void> _stopInternal({required bool clearTarget}) async {
    final subscription = _frameSubscription;
    final hadResources = _started || subscription != null;
    _acceptFrames = false;
    _started = false;
    _generation++;
    _pendingFrame = null;
    _frameSubscription = null;
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
    final drain = _drainCompleter;
    if (drain != null) {
      await drain.future;
    }
    if (hadResources) {
      await capture(_frameSource.stop);
    }
    _frameAnalyzer.reset();
    if (!clearTarget) {
      _frameAnalyzer.setTarget(_target);
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

  LessonException _mapError(Object error) {
    if (error is LessonException) {
      return error;
    }
    final normalized = error.toString().toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('notallowederror')) {
      return const LessonException(LessonErrorCode.audioPermissionDenied);
    }
    return LessonException(
      LessonErrorCode.performanceAnalyzerUnavailable,
      context: error.runtimeType.toString(),
    );
  }
}
