import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pitch_sample.dart';
import '../../domain/entities/tuner_settings.dart';
import '../../domain/services/a4_calibration_store.dart';
import '../../domain/services/audio_permission_service.dart';
import '../../domain/services/instrument_preset_catalog.dart';
import '../../domain/services/tuner_engine.dart';
import '../../domain/services/tuner_engine_exception.dart';
import 'tuner_event.dart';
import 'tuner_error_policy.dart';
import 'tuner_state.dart';

class TunerBloc extends Bloc<TunerEvent, TunerState> {
  TunerBloc({
    required TunerEngine engine,
    required AudioPermissionService audioPermissionService,
    A4CalibrationStore? a4CalibrationStore,
    InstrumentPresetCatalog? instrumentPresetCatalog,
    TunerSettings initialSettings = TunerSettings.defaults,
    bool initialPermissionGranted = false,
  })  : _engine = engine,
        _audioPermissionService = audioPermissionService,
        _a4CalibrationStore = a4CalibrationStore,
        _instrumentPresetCatalog = instrumentPresetCatalog,
        _settings = initialSettings,
        _audioPermissionGranted = initialPermissionGranted,
        super(Idle(settings: initialSettings)) {
    on<AudioPermissionChecked>(_onAudioPermissionChecked);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<UpdateA4>(_onUpdateA4);
    on<SelectPreset>(_onSelectPreset);
    on<_SampleReceived>((event, emit) => onSample(event.sample, emit));
    on<_EngineFailed>((event, emit) => onEngineFailure(event.code, emit));
    _restoreA4FromStore();
  }

  final TunerEngine _engine;
  final AudioPermissionService _audioPermissionService;
  final A4CalibrationStore? _a4CalibrationStore;
  final InstrumentPresetCatalog? _instrumentPresetCatalog;
  TunerSettings _settings;
  bool _audioPermissionGranted;
  StreamSubscription<PitchSample>? _samplesSubscription;

  Future<void> _onAudioPermissionChecked(
    AudioPermissionChecked event,
    Emitter<TunerState> emit,
  ) async {
    _audioPermissionGranted = event.granted;
    if (!event.granted) {
      await _stopEngineSafely();
      _emitPolicyError(emit, 'audio_permission_denied');
      return;
    }
    if (state is ErrorState) {
      emit(Idle(settings: _settings, sample: state.sample));
    }
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<TunerState> emit,
  ) async {
    final granted = await _resolveAudioPermission();
    if (!granted) {
      _emitPolicyError(emit, 'audio_permission_denied');
      return;
    }

    await _stopEngineSafely();
    try {
      await _engine.start(_settings);
      _samplesSubscription = _engine.samples().listen(
        (sample) => add(_SampleReceived(sample)),
        onError: (_) {
          add(const _EngineFailed('engine_stream_error'));
        },
      );
      emit(Listening(settings: _settings, sample: state.sample));
    } on TunerEngineException catch (error) {
      _emitPolicyError(emit, error.code);
    } catch (_) {
      _emitPolicyError(emit, 'audio_device_unavailable');
    }
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<TunerState> emit,
  ) async {
    await _stopEngineSafely();
    emit(Idle(settings: _settings, sample: state.sample));
  }

  Future<void> _onUpdateA4(
    UpdateA4 event,
    Emitter<TunerState> emit,
  ) async {
    final normalized = TunerSettings.normalizeA4Hz(event.a4Hz);
    _settings = _settings.copyWith(a4Hz: normalized);
    await _persistA4(normalized);
    if (state is Listening || state is InTune || state is OutOfTune) {
      final applied = await _applySettingsToRunningEngine(emit);
      if (!applied) {
        return;
      }
    }
    emit(_mapStateWithSettings(state, _settings));
  }

  Future<void> _onSelectPreset(
    SelectPreset event,
    Emitter<TunerState> emit,
  ) async {
    final preset = _instrumentPresetCatalog?.byId(event.instrumentPreset);
    if (preset == null && _instrumentPresetCatalog != null) {
      _emitPolicyError(emit, 'unknown_preset');
      return;
    }
    _settings = _settings.copyWith(
      instrumentPreset: event.instrumentPreset,
      noiseGateDb: preset?.noiseGateDb,
      smoothing: preset?.smoothing,
    );
    if (state is Listening || state is InTune || state is OutOfTune) {
      final applied = await _applySettingsToRunningEngine(emit);
      if (!applied) {
        return;
      }
    }
    emit(_mapStateWithSettings(state, _settings));
  }

  Future<bool> _applySettingsToRunningEngine(Emitter<TunerState> emit) async {
    try {
      await _engine.start(_settings);
      return true;
    } on TunerEngineException catch (error) {
      _emitPolicyError(emit, error.code);
    } catch (_) {
      _emitPolicyError(emit, 'engine_stream_error');
    }
    return false;
  }

  Future<void> _stopEngineSafely() async {
    await _samplesSubscription?.cancel();
    _samplesSubscription = null;
    try {
      await _engine.stop();
    } catch (_) {
      // No propagar excepciones de stop para mantener recuperacion estable.
    }
  }

  Future<void> _restoreA4FromStore() async {
    try {
      final stored = await _a4CalibrationStore?.readA4Hz();
      if (stored == null) {
        return;
      }
      add(UpdateA4(stored));
    } catch (_) {
      // Si la lectura falla, mantener default de dominio.
      add(const _EngineFailed('settings_persistence_read_failed'));
    }
  }

  Future<void> _persistA4(double a4Hz) async {
    try {
      await _a4CalibrationStore?.writeA4Hz(a4Hz);
    } catch (_) {
      // Persistencia best-effort para no romper flujo de afinacion.
      add(const _EngineFailed('settings_persistence_write_failed'));
    }
  }

  Future<bool> _resolveAudioPermission() async {
    if (_audioPermissionGranted) {
      return true;
    }
    try {
      final alreadyGranted = await _audioPermissionService.isGranted();
      if (alreadyGranted) {
        _audioPermissionGranted = true;
        return true;
      }
      final requested = await _audioPermissionService.request();
      _audioPermissionGranted = requested;
      return requested;
    } catch (_) {
      return false;
    }
  }

  TunerState _mapStateWithSettings(TunerState current, TunerSettings settings) {
    if (current is ErrorState) {
      return ErrorState(
        settings: settings,
        code: current.code,
        message: current.message,
        recoverable: current.recoverable,
        sample: current.sample,
      );
    }
    if (current is InTune) {
      return InTune(settings: settings, sample: current.sample!);
    }
    if (current is OutOfTune) {
      return OutOfTune(settings: settings, sample: current.sample!);
    }
    if (current is Listening) {
      return Listening(settings: settings, sample: current.sample);
    }
    return Idle(settings: settings, sample: current.sample);
  }

  void onSample(PitchSample sample, Emitter<TunerState> emit) {
    final isInTune = sample.confidence >= 0.6 && sample.cents.abs() <= 5.0;
    if (isInTune) {
      emit(InTune(settings: _settings, sample: sample));
    } else {
      emit(OutOfTune(settings: _settings, sample: sample));
    }
  }

  void onEngineFailure(String code, Emitter<TunerState> emit) {
    _emitPolicyError(emit, code);
  }

  void _emitPolicyError(Emitter<TunerState> emit, String code) {
    final info = TunerErrorPolicy.resolve(code);
    emit(
      ErrorState(
        settings: _settings,
        code: info.code,
        message: info.message,
        recoverable: info.recoverable,
        sample: state.sample,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _stopEngineSafely();
    return super.close();
  }
}

class _SampleReceived extends TunerEvent {
  const _SampleReceived(this.sample);

  final PitchSample sample;

  @override
  List<Object?> get props => [sample];
}

class _EngineFailed extends TunerEvent {
  const _EngineFailed(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
