import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_localizations.dart';
import 'app/platform_dependencies.dart';
import 'app/we_band_theme.dart';
import 'data/song_tuning/openai_song_tuning_config.dart';
import 'data/song_tuning/openai_song_tuning_service.dart';
import 'data/settings/default_instrument_preset_catalog.dart';
import 'data/settings/shared_preferences_a4_calibration_store.dart';
import 'data/settings/shared_preferences_metronome_settings_store.dart';
import 'domain/services/audio_permission_service.dart';
import 'domain/services/metronome_engine.dart';
import 'domain/services/song_tuning_service.dart';
import 'domain/services/tuner_engine.dart';
import 'presentation/bloc/metronome_bloc.dart';
import 'presentation/bloc/song_tuning_bloc.dart';
import 'presentation/bloc/tuner_bloc.dart';
import 'presentation/screens/app_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = _buildTunerEngine();
    final metronomeEngine = _buildMetronomeEngine();
    final audioPermissionService = _buildAudioPermissionService();
    final songTuningService = _buildSongTuningService();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: resolveAppLocale,
      theme: WeBandTheme.theme(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => TunerBloc(
              engine: engine,
              audioPermissionService: audioPermissionService,
              a4CalibrationStore: SharedPreferencesA4CalibrationStore(),
              instrumentPresetCatalog: const DefaultInstrumentPresetCatalog(),
            ),
          ),
          BlocProvider(
            create: (_) => SongTuningBloc(songTuningService: songTuningService),
          ),
          BlocProvider(
            create: (_) => MetronomeBloc(
              engine: metronomeEngine,
              settingsStore: SharedPreferencesMetronomeSettingsStore(),
            ),
          ),
        ],
        child: const AppShell(),
      ),
    );
  }
}

SongTuningService _buildSongTuningService() {
  return OpenAiSongTuningService(
    config: OpenAiSongTuningConfig.fromDartDefine(),
  );
}

TunerEngine _buildTunerEngine() => createTunerEngine();

MetronomeEngine _buildMetronomeEngine() => createMetronomeEngine();

AudioPermissionService _buildAudioPermissionService() =>
    createAudioPermissionService();
