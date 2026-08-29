import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/metronome_settings.dart';
import '../../domain/services/metronome_engine.dart';
import '../../domain/services/metronome_settings_store.dart';
import 'metronome_event.dart';
import 'metronome_state.dart';

class MetronomeBloc extends Bloc<MetronomeEvent, MetronomeState> {
  MetronomeBloc({
    required MetronomeEngine engine,
    required MetronomeSettingsStore settingsStore,
    MetronomeSettings? initialSettings,
    int Function()? nowMs,
  })  : _engine = engine,
        _settingsStore = settingsStore,
        _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch),
        super(
          MetronomeState.initial(
            initialSettings ?? MetronomeSettings.defaults,
          ),
        ) {
    on<MetronomeInitialized>(_onInitialized);
    on<MetronomeStarted>(_onStarted);
    on<MetronomeStopped>(_onStopped);
    on<TempoChanged>(_onTempoChanged);
    on<TapTempoPressed>(_onTapTempo);
    on<TimeSignatureChanged>(_onTimeSignatureChanged);
    on<StrongBeatChanged>(_onStrongBeatChanged);
    on<BeatMutedChanged>(_onBeatMutedChanged);
    on<BeatSubdivisionChanged>(_onBeatSubdivisionChanged);
    on<MetronomeTickReceived>(_onTick);
    on<MetronomeFailed>(_onFailed);
    add(const MetronomeInitialized());
  }

  final MetronomeEngine _engine;
  final MetronomeSettingsStore _settingsStore;
  final int Function() _nowMs;
  final List<int> _tapTimes = [];
  StreamSubscription? _tickSubscription;

  Future<void> _onInitialized(
    MetronomeInitialized event,
    Emitter<MetronomeState> emit,
  ) async {
    try {
      final restored = await _settingsStore.load();
      emit(
        state.copyWith(
          status: MetronomeStatus.idle,
          settings: restored ?? state.settings,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MetronomeStatus.idle,
          errorMessage: 'No se pudo recuperar la configuración guardada.',
        ),
      );
    }
  }

  Future<void> _onStarted(
    MetronomeStarted event,
    Emitter<MetronomeState> emit,
  ) async {
    await _stopEngine();
    try {
      await _engine.start(state.settings);
      _tickSubscription = _engine.ticks().listen(
            (tick) => add(MetronomeTickReceived(tick)),
            onError: (_) => add(
              const MetronomeFailed(
                  'No se pudo mantener el audio del metrónomo.'),
            ),
          );
      emit(
        state.copyWith(
          status: MetronomeStatus.playing,
          clearActiveTick: true,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MetronomeStatus.failure,
          errorMessage: 'No se pudo iniciar la salida de audio.',
          clearActiveTick: true,
        ),
      );
    }
  }

  Future<void> _onStopped(
    MetronomeStopped event,
    Emitter<MetronomeState> emit,
  ) async {
    await _stopEngine();
    emit(
      state.copyWith(
        status: MetronomeStatus.idle,
        clearActiveTick: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onTempoChanged(
    TempoChanged event,
    Emitter<MetronomeState> emit,
  ) async {
    final bpm = event.bpm.clamp(
      MetronomeSettings.minBpm,
      MetronomeSettings.maxBpm,
    );
    await _applySettings(state.settings.copyWith(bpm: bpm), emit);
  }

  Future<void> _onTapTempo(
    TapTempoPressed event,
    Emitter<MetronomeState> emit,
  ) async {
    final now = _nowMs();
    if (_tapTimes.isNotEmpty && now - _tapTimes.last > 2000) {
      _tapTimes.clear();
    }
    _tapTimes.add(now);
    if (_tapTimes.length > 5) {
      _tapTimes.removeAt(0);
    }
    if (_tapTimes.length < 2) {
      return;
    }
    final intervals = <int>[
      for (var index = 1; index < _tapTimes.length; index++)
        _tapTimes[index] - _tapTimes[index - 1],
    ]..sort();
    final median = intervals[intervals.length ~/ 2];
    if (median <= 0) {
      return;
    }
    final bpm = (60000 / median).round().clamp(
          MetronomeSettings.minBpm,
          MetronomeSettings.maxBpm,
        );
    await _applySettings(state.settings.copyWith(bpm: bpm), emit);
  }

  Future<void> _onTimeSignatureChanged(
    TimeSignatureChanged event,
    Emitter<MetronomeState> emit,
  ) async {
    await _applySettings(
      state.settings.copyWith(timeSignature: event.timeSignature),
      emit,
    );
  }

  Future<void> _onStrongBeatChanged(
    StrongBeatChanged event,
    Emitter<MetronomeState> emit,
  ) async {
    await _applySettings(
      state.settings.withStrongBeat(event.beatIndex),
      emit,
    );
  }

  Future<void> _onBeatMutedChanged(
    BeatMutedChanged event,
    Emitter<MetronomeState> emit,
  ) async {
    try {
      await _applySettings(
        state.settings.withBeatMuted(event.beatIndex, event.muted),
        emit,
      );
    } on StateError {
      emit(
        state.copyWith(
          errorMessage: 'Mueve la tónica antes de silenciar este tiempo.',
        ),
      );
    }
  }

  Future<void> _onBeatSubdivisionChanged(
    BeatSubdivisionChanged event,
    Emitter<MetronomeState> emit,
  ) async {
    await _applySettings(
      state.settings.withBeatSubdivision(
        event.beatIndex,
        event.subdivision,
      ),
      emit,
    );
  }

  void _onTick(
    MetronomeTickReceived event,
    Emitter<MetronomeState> emit,
  ) {
    if (!state.isPlaying) {
      return;
    }
    emit(
      state.copyWith(
        activeBeatIndex: event.tick.beatIndex,
        activeSubdivisionIndex: event.tick.subdivisionIndex,
      ),
    );
  }

  Future<void> _onFailed(
    MetronomeFailed event,
    Emitter<MetronomeState> emit,
  ) async {
    await _stopEngine();
    emit(
      state.copyWith(
        status: MetronomeStatus.failure,
        errorMessage: event.message,
        clearActiveTick: true,
      ),
    );
  }

  Future<void> _applySettings(
    MetronomeSettings settings,
    Emitter<MetronomeState> emit,
  ) async {
    final wasPlaying = state.isPlaying;
    emit(
      state.copyWith(
        status: state.status == MetronomeStatus.failure
            ? MetronomeStatus.idle
            : state.status,
        settings: settings,
        clearError: true,
      ),
    );
    try {
      await _settingsStore.save(settings);
      if (wasPlaying) {
        await _engine.update(settings);
      }
    } catch (_) {
      if (wasPlaying) {
        await _stopEngine();
      }
      emit(
        state.copyWith(
          status: MetronomeStatus.failure,
          errorMessage: 'No se pudo aplicar la configuración.',
        ),
      );
    }
  }

  Future<void> _stopEngine() async {
    await _tickSubscription?.cancel();
    _tickSubscription = null;
    try {
      await _engine.stop();
    } catch (_) {
      // Stop es best-effort para conservar un flujo recuperable.
    }
  }

  @override
  Future<void> close() async {
    await _stopEngine();
    return super.close();
  }
}
