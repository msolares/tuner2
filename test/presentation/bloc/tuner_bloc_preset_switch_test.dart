import 'dart:async';

import 'package:afinador/data/settings/default_instrument_preset_catalog.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:afinador/domain/entities/tuner_settings.dart';
import 'package:afinador/domain/services/audio_permission_service.dart';
import 'package:afinador/domain/services/tuner_engine.dart';
import 'package:afinador/presentation/bloc/tuner_bloc.dart';
import 'package:afinador/presentation/bloc/tuner_event.dart';
import 'package:afinador/presentation/bloc/tuner_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reconecta samples al cambiar guitarra y volver a cromatico', () async {
    final engine = _RestartingStreamTunerEngine();
    final bloc = TunerBloc(
      engine: engine,
      audioPermissionService: const _GrantedPermissionService(),
      instrumentPresetCatalog: const DefaultInstrumentPresetCatalog(),
      initialPermissionGranted: true,
      initialSettings: TunerSettings.defaults.copyWith(
        instrumentPreset: 'chromatic',
        smoothing: 0.20,
      ),
    );
    addTearDown(bloc.close);

    bloc.add(const StartListening());
    await _waitFor(bloc, (state) => state is Listening);
    engine.emit(_sample(note: 'A4', hz: 440.0, timestampMs: 100));
    await _waitFor(bloc, (state) => state.sample?.note == 'A4');

    bloc.add(const SelectPreset('guitar_standard'));
    await _waitFor(
      bloc,
      (state) =>
          state.settings.instrumentPreset == 'guitar_standard' &&
          engine.startCalls == 2,
    );
    engine.emit(_sample(note: 'E2', hz: 82.41, timestampMs: 200));
    await _waitFor(bloc, (state) => state.sample?.note == 'E2');

    bloc.add(const SelectPreset('chromatic'));
    await _waitFor(
      bloc,
      (state) =>
          state.settings.instrumentPreset == 'chromatic' &&
          engine.startCalls == 3,
    );
    engine.emit(_sample(note: 'A3', hz: 220.0, timestampMs: 300));
    final recovered = await _waitFor(
      bloc,
      (state) => state.sample?.note == 'A3',
    );

    expect(recovered, isA<InTune>());
    expect(engine.stopCalls, 3);
  });

  test('mantiene Listening cuando el engine emite una muestra vacia', () async {
    final engine = _RestartingStreamTunerEngine();
    final bloc = TunerBloc(
      engine: engine,
      audioPermissionService: const _GrantedPermissionService(),
      initialPermissionGranted: true,
    );
    addTearDown(bloc.close);

    bloc.add(const StartListening());
    await _waitFor(bloc, (state) => state is Listening);
    engine.emit(
      const PitchSample(
        hz: 0.0,
        note: '--',
        cents: 0.0,
        confidence: 0.0,
        timestampMs: 100,
      ),
    );
    final state = await _waitFor(
      bloc,
      (state) => state is Listening && state.sample?.timestampMs == 100,
    );

    expect(state, isA<Listening>());
    expect(state, isNot(isA<OutOfTune>()));
  });
}

PitchSample _sample({
  required String note,
  required double hz,
  required int timestampMs,
}) {
  return PitchSample(
    hz: hz,
    note: note,
    cents: 0.0,
    confidence: 0.95,
    timestampMs: timestampMs,
  );
}

Future<TunerState> _waitFor(
  TunerBloc bloc,
  bool Function(TunerState state) predicate,
) {
  if (predicate(bloc.state)) {
    return Future.value(bloc.state);
  }
  return bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 2));
}

class _RestartingStreamTunerEngine implements TunerEngine {
  StreamController<PitchSample>? _controller;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> start(TunerSettings settings) async {
    startCalls++;
    _controller = StreamController<PitchSample>.broadcast();
  }

  @override
  Stream<PitchSample> samples() {
    return _controller?.stream ?? const Stream<PitchSample>.empty();
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    await _controller?.close();
    _controller = null;
  }

  void emit(PitchSample sample) => _controller!.add(sample);
}

class _GrantedPermissionService implements AudioPermissionService {
  const _GrantedPermissionService();

  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async => true;
}
