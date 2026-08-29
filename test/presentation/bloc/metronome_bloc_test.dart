import 'dart:async';

import 'package:afinador/domain/entities/metronome_settings.dart';
import 'package:afinador/domain/entities/metronome_tick.dart';
import 'package:afinador/domain/entities/time_signature.dart';
import 'package:afinador/domain/services/metronome_engine.dart';
import 'package:afinador/domain/services/metronome_settings_store.dart';
import 'package:afinador/presentation/bloc/metronome_bloc.dart';
import 'package:afinador/presentation/bloc/metronome_event.dart';
import 'package:afinador/presentation/bloc/metronome_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetronomeBloc', () {
    test('restores and persists configuration changes', () async {
      final restored = MetronomeSettings.defaults.copyWith(bpm: 96);
      final engine = _FakeMetronomeEngine();
      final store = _MemorySettingsStore(restored);
      final bloc = MetronomeBloc(engine: engine, settingsStore: store);
      addTearDown(bloc.close);

      await _waitFor(bloc, (state) => state.status == MetronomeStatus.idle);
      expect(bloc.state.settings, restored);

      bloc.add(const TempoChanged(142));
      await _waitFor(bloc, (state) => state.settings.bpm == 142);
      expect(store.saved?.bpm, 142);
    });

    test('updates tonic, signature and subdivision deterministically',
        () async {
      final bloc = MetronomeBloc(
        engine: _FakeMetronomeEngine(),
        settingsStore: _MemorySettingsStore(),
      );
      addTearDown(bloc.close);
      await _waitFor(bloc, (state) => state.status == MetronomeStatus.idle);

      bloc.add(
        TimeSignatureChanged(
          TimeSignature(numerator: 6, denominator: 8),
        ),
      );
      await _waitFor(bloc, (state) => state.settings.beats.length == 6);
      bloc.add(const StrongBeatChanged(3));
      await _waitFor(
        bloc,
        (state) => state.settings.beats[3].accent == BeatAccent.strong,
      );
      bloc.add(
        const BeatSubdivisionChanged(2, BeatSubdivision.triplet),
      );
      await _waitFor(
        bloc,
        (state) =>
            state.settings.beats[2].subdivision == BeatSubdivision.triplet,
      );

      expect(bloc.state.settings.beats[0].accent, BeatAccent.normal);
    });

    test('tap tempo uses recent intervals', () async {
      final times = <int>[1000, 1500, 2000, 2500];
      var index = 0;
      final bloc = MetronomeBloc(
        engine: _FakeMetronomeEngine(),
        settingsStore: _MemorySettingsStore(),
        nowMs: () => times[index++],
      );
      addTearDown(bloc.close);
      await _waitFor(bloc, (state) => state.status == MetronomeStatus.idle);

      bloc.add(const TapTempoPressed());
      bloc.add(const TapTempoPressed());
      await _waitFor(bloc, (state) => state.settings.bpm == 120);

      expect(bloc.state.settings.bpm, 120);
    });

    test('start receives ticks and stop ignores later ticks', () async {
      final engine = _FakeMetronomeEngine();
      final bloc = MetronomeBloc(
        engine: engine,
        settingsStore: _MemorySettingsStore(),
      );
      addTearDown(bloc.close);
      await _waitFor(bloc, (state) => state.status == MetronomeStatus.idle);

      bloc.add(const MetronomeStarted());
      await _waitFor(bloc, (state) => state.isPlaying);
      engine.emit(
        const MetronomeTick(
          beatIndex: 2,
          subdivisionIndex: 1,
          timestampMs: 100,
          accent: BeatAccent.normal,
        ),
      );
      await _waitFor(bloc, (state) => state.activeBeatIndex == 2);

      bloc.add(const MetronomeStopped());
      await _waitFor(bloc, (state) => state.status == MetronomeStatus.idle);
      expect(engine.stopCount, greaterThanOrEqualTo(1));
      expect(bloc.state.activeBeatIndex, isNull);
    });
  });
}

Future<void> _waitFor(
  MetronomeBloc bloc,
  bool Function(MetronomeState state) predicate,
) async {
  if (predicate(bloc.state)) {
    return;
  }
  await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 2));
}

class _FakeMetronomeEngine implements MetronomeEngine {
  final _controller = StreamController<MetronomeTick>.broadcast();
  int stopCount = 0;

  @override
  Future<void> start(MetronomeSettings settings) async {}

  @override
  Future<void> update(MetronomeSettings settings) async {}

  @override
  Stream<MetronomeTick> ticks() => _controller.stream;

  @override
  Future<void> stop() async {
    stopCount++;
  }

  void emit(MetronomeTick tick) => _controller.add(tick);
}

class _MemorySettingsStore implements MetronomeSettingsStore {
  _MemorySettingsStore([this.value]);

  MetronomeSettings? value;
  MetronomeSettings? saved;

  @override
  Future<MetronomeSettings?> load() async => value;

  @override
  Future<void> save(MetronomeSettings settings) async {
    saved = settings;
    value = settings;
  }
}
