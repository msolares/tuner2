import 'dart:async';

import 'package:afinador/app/app_theme.dart';
import 'package:afinador/data/settings/default_instrument_preset_catalog.dart';
import 'package:afinador/domain/entities/guitar_tuning.dart';
import 'package:afinador/domain/entities/instrument_preset_profile.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:afinador/domain/entities/song_tuning_query.dart';
import 'package:afinador/domain/entities/song_tuning_result.dart';
import 'package:afinador/domain/entities/tuner_settings.dart';
import 'package:afinador/domain/services/audio_permission_service.dart';
import 'package:afinador/domain/services/song_tuning_service.dart';
import 'package:afinador/domain/services/tuner_engine.dart';
import 'package:afinador/presentation/bloc/song_tuning_bloc.dart';
import 'package:afinador/presentation/bloc/tuner_bloc.dart';
import 'package:afinador/presentation/bloc/tuner_event.dart';
import 'package:afinador/presentation/bloc/song_tuning_event.dart';
import 'package:afinador/presentation/bloc/song_tuning_state.dart';
import 'package:afinador/presentation/screens/tuner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TunerScreen', () {
    testWidgets('renderiza branding y paneles base',
        (WidgetTester tester) async {
      final harness = _TestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(
        harness.tunerBloc.state.settings.instrumentPreset,
        'guitar_standard',
      );
      expect(find.byKey(const ValueKey('tuner-brand-logo')), findsOneWidget);
      expect(find.byKey(const ValueKey('tuner-core-card')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('tuner-status-text')))
            .data,
        'READY',
      );

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('TUNER SETUP'), findsOneWidget);
      expect(find.text('Calibration'), findsOneWidget);
      expect(find.text('Calibration & preset'), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byKey(const ValueKey('song-tuning-panel')), findsNothing);
      expect(find.text('SONG TUNING'), findsNothing);
    });

    testWidgets('cambia el preset desde la insignia superior sin scroll',
        (WidgetTester tester) async {
      final harness = _TestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      final selector = find.byKey(
        const ValueKey('header-preset-selector'),
      );
      expect(selector, findsOneWidget);
      expect(
        find.byTooltip(
          'Change tuning. Current: Guitar (EADGBE)',
        ),
        findsOneWidget,
      );
      final presetSize = tester.getSize(selector);
      expect(presetSize.height, 48);
      expect(
        find.byKey(const ValueKey('header-status-chip')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('header-confidence-chip')),
        findsNothing,
      );

      await tester.tap(selector);
      await tester.pumpAndSettle();

      for (final preset in kMvpInstrumentPresets) {
        expect(
          find.byKey(ValueKey('preset-option-${preset.id}')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('active-preset-check')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('preset-option-chromatic')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.tunerBloc.state.settings.instrumentPreset,
        'chromatic',
      );
      expect(find.text('CHROMATIC'), findsNWidgets(2));
    });

    testWidgets('la seleccion manual limpia la afinacion por cancion',
        (WidgetTester tester) async {
      final harness = _TestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      harness.songTuningBloc.add(const SongNameChanged('Everlong'));
      harness.songTuningBloc.add(const SongTuningSubmitted());
      await tester.pumpAndSettle();
      expect(harness.songTuningBloc.state.status, SongTuningStatus.success);

      await tester.tap(
        find.byKey(const ValueKey('header-preset-selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('preset-option-bass_standard')),
      );
      await tester.pumpAndSettle();

      expect(harness.songTuningBloc.state.status, SongTuningStatus.idle);
      expect(harness.songTuningBloc.state.result, isNull);
      expect(
        harness.tunerBloc.state.settings.instrumentPreset,
        'bass_standard',
      );
    });

    testWidgets('el selector no desborda a 320 px',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = _TestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey('header-preset-selector')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('preset-option-violin_standard')),
        findsOneWidget,
      );
    });

    testWidgets('muestra estado in tune con una muestra estable',
        (WidgetTester tester) async {
      final harness = _TestHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.build());

      harness.tunerBloc.add(const StartListening());
      await tester.pump();

      harness.engine.emit(
        const PitchSample(
          hz: 440.0,
          note: 'E4',
          cents: 1.2,
          confidence: 0.92,
          timestampMs: 1000,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('current-note-text')))
            .data,
        'E',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('tuner-status-text')))
            .data,
        'IN TUNE',
      );
      expect(find.text('440.0 Hz'), findsOneWidget);

      final markerCenter =
          tester.getCenter(find.byKey(const ValueKey('cents-marker')));
      final centerBand =
          tester.getRect(find.byKey(const ValueKey('cents-center-band')));
      expect(markerCenter.dx,
          moreOrLessEquals(centerBand.center.dx, epsilon: 1.0));
    });
  });
}

class _TestHarness {
  _TestHarness()
      : engine = _FakeTunerEngine(),
        songTuningBloc =
            SongTuningBloc(songTuningService: const _FakeSongTuningService()) {
    tunerBloc = TunerBloc(
      engine: engine,
      audioPermissionService: const _GrantedPermissionService(),
      instrumentPresetCatalog: const DefaultInstrumentPresetCatalog(),
      initialPermissionGranted: true,
    );
  }

  final _FakeTunerEngine engine;
  late final TunerBloc tunerBloc;
  final SongTuningBloc songTuningBloc;

  Widget build() {
    return MaterialApp(
      theme: AppTheme.theme(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TunerBloc>.value(value: tunerBloc),
          BlocProvider<SongTuningBloc>.value(value: songTuningBloc),
        ],
        child: const TunerScreen(),
      ),
    );
  }

  Future<void> dispose() async {
    await tunerBloc.close();
    await songTuningBloc.close();
    await engine.dispose();
  }
}

class _FakeTunerEngine implements TunerEngine {
  final StreamController<PitchSample> _controller =
      StreamController<PitchSample>.broadcast();

  TunerSettings? lastSettings;

  @override
  Future<void> start(TunerSettings settings) async {
    lastSettings = settings;
  }

  @override
  Stream<PitchSample> samples() => _controller.stream;

  @override
  Future<void> stop() async {}

  void emit(PitchSample sample) {
    _controller.add(sample);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _GrantedPermissionService implements AudioPermissionService {
  const _GrantedPermissionService();

  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async => true;
}

class _FakeSongTuningService implements SongTuningService {
  const _FakeSongTuningService();

  @override
  Future<SongTuningResult> resolve(SongTuningQuery query) async {
    return SongTuningResult(
      query: query,
      primaryTuning: const GuitarTuning(
        id: 'standard',
        displayName: 'Standard',
        stringsLowToHigh: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
      ),
    );
  }
}
