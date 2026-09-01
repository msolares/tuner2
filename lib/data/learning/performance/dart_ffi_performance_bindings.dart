import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../../domain/learning/lesson_errors.dart';
import '../../../domain/learning/performance.dart';
import 'performance_ffi_bindings.dart';

const int _performanceAbiVersion = 1;

final class DartFfiPerformanceBindings implements PerformanceFfiBindings {
  DartFfiPerformanceBindings._(DynamicLibrary library)
      : _performanceInit =
            library.lookupFunction<_PerformanceInitNative, _PerformanceInit>(
                'performance_init'),
        _performanceSetTarget = library.lookupFunction<
            _PerformanceSetTargetNative,
            _PerformanceSetTarget>('performance_set_target'),
        _performanceProcessFrame = library.lookupFunction<
            _PerformanceProcessFrameNative,
            _PerformanceProcessFrame>('performance_process_frame'),
        _performanceDispose = library.lookupFunction<_PerformanceDisposeNative,
            _PerformanceDispose>('performance_dispose');

  final _PerformanceInit _performanceInit;
  final _PerformanceSetTarget _performanceSetTarget;
  final _PerformanceProcessFrame _performanceProcessFrame;
  final _PerformanceDispose _performanceDispose;

  static PerformanceFfiBindings? tryOpen() {
    try {
      return DartFfiPerformanceBindings._(_openLibrary());
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
    throw const LessonException(
      LessonErrorCode.performanceAnalyzerUnavailable,
      context: 'unsupported_mobile_platform',
    );
  }

  @override
  int init(PerformanceAnalyzerSettings settings) {
    final config = calloc<_PerformanceConfigV1>();
    try {
      config.ref
        ..abiVersion = _performanceAbiVersion
        ..structSize = sizeOf<_PerformanceConfigV1>()
        ..a4Hz = settings.a4Hz
        ..noiseGateDb = -60;
      return _performanceInit(config);
    } finally {
      calloc.free(config);
    }
  }

  @override
  int setTarget(int handle, PerformanceFfiTarget? target) {
    if (target == null) {
      return _performanceSetTarget(handle, nullptr);
    }
    final pointer = calloc<_PerformanceTargetV1>();
    try {
      pointer.ref
        ..abiVersion = _performanceAbiVersion
        ..structSize = sizeOf<_PerformanceTargetV1>()
        ..targetKind = target.kind.rawValue
        ..midi = target.midi
        ..pitchClassCount = target.pitchClasses.length;
      for (var index = 0; index < target.pitchClasses.length; index++) {
        pointer.ref.pitchClasses[index] = target.pitchClasses[index];
      }
      return _performanceSetTarget(handle, pointer);
    } finally {
      calloc.free(pointer);
    }
  }

  @override
  PerformanceFfiResult processFrame(
    int handle,
    Float32List pcm,
    int sampleRateHz,
    int timestampMs,
  ) {
    final pointer = calloc<Float>(pcm.length);
    try {
      pointer.asTypedList(pcm.length).setAll(0, pcm);
      final result = _performanceProcessFrame(
        handle,
        pointer,
        pcm.length,
        sampleRateHz,
        timestampMs,
      );
      return PerformanceFfiResult(
        errorCode: result.errorCode,
        kind: PerformanceFfiObservationKind.fromRaw(result.observationKind),
        timestampMs: result.timestampMs,
        onsetSequence: result.onsetSequence,
        confidence: result.confidence,
        hz: result.hz,
        cents: result.cents,
        midi: result.midi,
        pitchClassStrengths: List<double>.generate(
          12,
          (index) => result.pitchClassStrengths[index],
          growable: false,
        ),
        onsetConfidence: result.onsetConfidence,
      );
    } finally {
      calloc.free(pointer);
    }
  }

  @override
  int dispose(int handle) => _performanceDispose(handle);
}

final class _PerformanceConfigV1 extends Struct {
  @Uint32()
  external int abiVersion;

  @Uint32()
  external int structSize;

  @Float()
  external double a4Hz;

  @Float()
  external double noiseGateDb;

  @Array(4)
  external Array<Uint32> reserved;
}

final class _PerformanceTargetV1 extends Struct {
  @Uint32()
  external int abiVersion;

  @Uint32()
  external int structSize;

  @Uint32()
  external int targetKind;

  @Int32()
  external int midi;

  @Uint32()
  external int pitchClassCount;

  @Array(3)
  external Array<Uint8> pitchClasses;

  @Uint8()
  external int reservedUint8;

  @Array(4)
  external Array<Uint32> reserved;
}

final class _PerformanceResultV1 extends Struct {
  @Uint32()
  external int abiVersion;

  @Uint32()
  external int structSize;

  @Int32()
  external int errorCode;

  @Uint32()
  external int observationKind;

  @Uint64()
  external int timestampMs;

  @Uint64()
  external int onsetSequence;

  @Float()
  external double confidence;

  @Float()
  external double hz;

  @Float()
  external double cents;

  @Int32()
  external int midi;

  @Array(12)
  external Array<Float> pitchClassStrengths;

  @Float()
  external double onsetConfidence;

  @Array(3)
  external Array<Uint32> reserved;
}

typedef _PerformanceInitNative = Uint64 Function(
  Pointer<_PerformanceConfigV1> config,
);
typedef _PerformanceInit = int Function(Pointer<_PerformanceConfigV1> config);

typedef _PerformanceSetTargetNative = Int32 Function(
  Uint64 handle,
  Pointer<_PerformanceTargetV1> target,
);
typedef _PerformanceSetTarget = int Function(
  int handle,
  Pointer<_PerformanceTargetV1> target,
);

typedef _PerformanceProcessFrameNative = _PerformanceResultV1 Function(
  Uint64 handle,
  Pointer<Float> pcm,
  IntPtr len,
  Uint32 sampleRate,
  Uint64 timestampMs,
);
typedef _PerformanceProcessFrame = _PerformanceResultV1 Function(
  int handle,
  Pointer<Float> pcm,
  int len,
  int sampleRate,
  int timestampMs,
);

typedef _PerformanceDisposeNative = Int32 Function(Uint64 handle);
typedef _PerformanceDispose = int Function(int handle);
