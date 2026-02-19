import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../domain/entities/pitch_sample.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/services/tuner_engine.dart';
import '../../../domain/services/tuner_engine_exception.dart';
import '../../audio/audio_frame_source.dart';
import '../../audio/audio_pcm_frame.dart';
import '../common/simple_pitch_detector.dart';

class MobileFfiTunerEngine implements TunerEngine {
  MobileFfiTunerEngine({
    required AudioFrameSource frameSource,
    SimplePitchDetector? fallbackDetector,
  })  : _frameSource = frameSource,
        _fallbackDetector = fallbackDetector ?? SimplePitchDetector();

  final AudioFrameSource _frameSource;
  final SimplePitchDetector _fallbackDetector;
  final StreamController<PitchSample> _controller = StreamController<PitchSample>.broadcast();
  StreamSubscription<AudioPcmFrame>? _frameSubscription;
  _RustBindings? _ffi;
  int _handle = 0;
  TunerSettings _settings = TunerSettings.defaults;
  bool _started = false;

  @override
  Future<void> start(TunerSettings settings) async {
    if (_started && _ffi != null && _handle != 0) {
      final code = _ffi!.updateConfig(_handle, _encodeSettings(settings));
      if (code != _FfiErrorCode.ok) {
        throw TunerEngineException(_mapFfiCodeToPolicyCode(code));
      }
      _settings = settings;
      return;
    }
    await stop();
    _settings = settings;
    _ffi = _RustBindings.tryLoad();
    if (_ffi != null) {
      _handle = _ffi!.init(_encodeSettings(settings));
      if (_handle == 0) {
        throw const TunerEngineException('engine_start_failed');
      }
    }

    await _frameSource.start();
    _frameSubscription = _frameSource.frames().listen(
      _onFrame,
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
    await _frameSubscription?.cancel();
    _frameSubscription = null;
    await _frameSource.stop();
    if (_ffi != null && _handle != 0) {
      final code = _ffi!.dispose(_handle);
      _handle = 0;
      if (code != _FfiErrorCode.ok) {
        throw TunerEngineException(_mapFfiCodeToPolicyCode(code));
      }
    }
    _started = false;
  }

  void _onFrame(AudioPcmFrame frame) {
    if (!_started) {
      return;
    }
    final sample = _ffi != null ? _processFrameWithFfi(frame) : _processFrameWithFallback(frame);
    if (sample != null) {
      _controller.add(sample);
    }
  }

  PitchSample? _processFrameWithFfi(AudioPcmFrame frame) {
    if (_handle == 0 || _ffi == null) {
      throw const TunerEngineException('ffi_invalid_handle');
    }
    final result = _ffi!.processFrame(_handle, frame.pcmFloat32, frame.sampleRateHz);
    if (result.errorCode != _FfiErrorCode.ok) {
      throw TunerEngineException(_mapFfiCodeToPolicyCode(result.errorCode));
    }
    return PitchSample(
      hz: result.hz,
      note: result.note,
      cents: result.cents,
      confidence: result.confidence,
      timestampMs: frame.timestampMs,
    );
  }

  PitchSample? _processFrameWithFallback(AudioPcmFrame frame) {
    return _fallbackDetector.detect(
      pcm: frame.pcmFloat32,
      sampleRateHz: frame.sampleRateHz,
      a4Hz: _settings.a4Hz,
      timestampMs: frame.timestampMs,
    );
  }

  String _encodeSettings(TunerSettings settings) {
    return jsonEncode({
      'a4Hz': settings.a4Hz,
      'instrumentPreset': settings.instrumentPreset,
      'noiseGateDb': settings.noiseGateDb,
      'smoothing': settings.smoothing,
    });
  }

  String _mapFfiCodeToPolicyCode(int code) {
    return switch (code) {
      _FfiErrorCode.invalidHandle => 'ffi_invalid_handle',
      _FfiErrorCode.invalidFrame => 'ffi_invalid_frame',
      _FfiErrorCode.invalidSampleRate => 'ffi_invalid_sample_rate',
      _FfiErrorCode.internalError => 'ffi_internal_error',
      _ => 'unexpected_error',
    };
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

class _RustBindings {
  _RustBindings._(DynamicLibrary dylib)
      : _tunerInit = dylib.lookupFunction<_TunerInitNative, _TunerInit>('tuner_init'),
        _tunerProcessFrame =
            dylib.lookupFunction<_TunerProcessFrameNative, _TunerProcessFrame>('tuner_process_frame'),
        _tunerUpdateConfig =
            dylib.lookupFunction<_TunerUpdateConfigNative, _TunerUpdateConfig>('tuner_update_config'),
        _tunerDispose = dylib.lookupFunction<_TunerDisposeNative, _TunerDispose>('tuner_dispose');

  final _TunerInit _tunerInit;
  final _TunerProcessFrame _tunerProcessFrame;
  final _TunerUpdateConfig _tunerUpdateConfig;
  final _TunerDispose _tunerDispose;

  static _RustBindings? tryLoad() {
    try {
      return _RustBindings._(_openLibrary());
    } catch (_) {
      return null;
    }
  }

  static DynamicLibrary _openLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libafinador_engine.so');
    }
    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isMacOS) {
      return DynamicLibrary.open('libafinador_engine.dylib');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('afinador_engine.dll');
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('libafinador_engine.so');
    }
    throw const TunerEngineException('audio_device_unavailable');
  }

  int init(String configJson) {
    final ptr = configJson.toNativeUtf8();
    try {
      return _tunerInit(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  _PitchResultModel processFrame(int handle, Float32List pcm, int sampleRateHz) {
    final ptr = calloc<Float>(pcm.length);
    try {
      for (var i = 0; i < pcm.length; i++) {
        ptr[i] = pcm[i];
      }
      final raw = _tunerProcessFrame(handle, ptr, pcm.length, sampleRateHz);
      final noteBytes = <int>[];
      for (var i = 0; i < raw.noteLen; i++) {
        noteBytes.add(raw.note[i]);
      }
      return _PitchResultModel(
        errorCode: raw.errorCode,
        hz: raw.hz,
        cents: raw.cents,
        confidence: raw.confidence,
        note: noteBytes.isEmpty ? '--' : ascii.decode(noteBytes),
      );
    } finally {
      calloc.free(ptr);
    }
  }

  int updateConfig(int handle, String configJson) {
    final ptr = configJson.toNativeUtf8();
    try {
      return _tunerUpdateConfig(handle, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  int dispose(int handle) => _tunerDispose(handle);
}

class _PitchResultModel {
  const _PitchResultModel({
    required this.errorCode,
    required this.hz,
    required this.cents,
    required this.confidence,
    required this.note,
  });

  final int errorCode;
  final double hz;
  final double cents;
  final double confidence;
  final String note;
}

final class _PitchResult extends Struct {
  @Int32()
  external int errorCode;

  @Float()
  external double hz;

  @Float()
  external double cents;

  @Float()
  external double confidence;

  @Uint8()
  external int noteLen;

  @Array(8)
  external Array<Uint8> note;
}

typedef _TunerInitNative = Uint64 Function(Pointer<Utf8> configJsonPtr);
typedef _TunerInit = int Function(Pointer<Utf8> configJsonPtr);

typedef _TunerProcessFrameNative = _PitchResult Function(
  Uint64 handle,
  Pointer<Float> pcmPtr,
  IntPtr len,
  Uint32 sampleRate,
);
typedef _TunerProcessFrame = _PitchResult Function(
  int handle,
  Pointer<Float> pcmPtr,
  int len,
  int sampleRate,
);

typedef _TunerUpdateConfigNative = Int32 Function(Uint64 handle, Pointer<Utf8> configJsonPtr);
typedef _TunerUpdateConfig = int Function(int handle, Pointer<Utf8> configJsonPtr);

typedef _TunerDisposeNative = Int32 Function(Uint64 handle);
typedef _TunerDispose = int Function(int handle);

abstract class _FfiErrorCode {
  static const int ok = 0;
  static const int invalidHandle = 2;
  static const int invalidFrame = 3;
  static const int invalidSampleRate = 4;
  static const int internalError = 7;
}
