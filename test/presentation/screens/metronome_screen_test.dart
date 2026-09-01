import 'package:afinador/app/app_theme.dart';
import 'package:afinador/app/app_localizations.dart';
import 'package:afinador/domain/entities/metronome_settings.dart';
import 'package:afinador/domain/entities/metronome_tick.dart';
import 'package:afinador/domain/services/metronome_engine.dart';
import 'package:afinador/domain/services/metronome_settings_store.dart';
import 'package:afinador/presentation/bloc/metronome_bloc.dart';
import 'package:afinador/presentation/screens/metronome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edits tempo and per-beat pattern at 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = MetronomeBloc(
      engine: _FakeEngine(),
      settingsStore: _MemoryStore(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.theme(),
        home: BlocProvider.value(
          value: bloc,
          child: const MetronomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial layout');

    await tester.tap(find.byTooltip('Aumentar tempo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'tempo layout');
    expect(bloc.state.settings.bpm, 121);

    await tester.drag(
      find.byKey(const ValueKey('metronome-scroll')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'beat sequence layout');
    await tester.tap(find.byKey(const ValueKey('metronome-beat-1')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('metronome-scroll')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('strong-beat-control')));
    await tester.pumpAndSettle();
    expect(bloc.state.settings.beats[1].accent, BeatAccent.strong);

    await tester.tap(
      find.widgetWithText(ChoiceChip, 'Tresillo de Corcheas'),
    );
    await tester.pumpAndSettle();
    expect(
      bloc.state.settings.beats[1].subdivision,
      BeatSubdivision.triplet,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeEngine implements MetronomeEngine {
  @override
  Future<void> start(MetronomeSettings settings) async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<MetronomeTick> ticks() => const Stream.empty();

  @override
  Future<void> update(MetronomeSettings settings) async {}
}

class _MemoryStore implements MetronomeSettingsStore {
  @override
  Future<MetronomeSettings?> load() async => null;

  @override
  Future<void> save(MetronomeSettings settings) async {}
}
