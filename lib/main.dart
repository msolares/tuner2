import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/audio/recorder_audio_frame_source.dart';
import 'data/engines/mobile/mobile_ffi_tuner_engine.dart';
import 'data/engines/web/web_tuner_engine.dart';
import 'data/permissions/noop_audio_permission_service.dart';
import 'data/permissions/permission_handler_audio_permission_service.dart';
import 'data/settings/default_instrument_preset_catalog.dart';
import 'data/settings/shared_preferences_a4_calibration_store.dart';
import 'domain/services/audio_permission_service.dart';
import 'domain/services/tuner_engine.dart';
import 'presentation/bloc/tuner_bloc.dart';
import 'presentation/screens/tuner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = _buildTunerEngine();
    final audioPermissionService = _buildAudioPermissionService();
    return MaterialApp(
      title: 'Afinador MVP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => TunerBloc(
          engine: engine,
          audioPermissionService: audioPermissionService,
          a4CalibrationStore: SharedPreferencesA4CalibrationStore(),
          instrumentPresetCatalog: const DefaultInstrumentPresetCatalog(),
        ),
        child: const TunerScreen(),
      ),
    );
  }
}

TunerEngine _buildTunerEngine() {
  if (kIsWeb) {
    return WebTunerEngine();
  }
  return MobileFfiTunerEngine(
    frameSource: RecorderAudioFrameSource(),
  );
}

AudioPermissionService _buildAudioPermissionService() {
  if (kIsWeb) {
    return const NoopAudioPermissionService();
  }
  return PermissionHandlerAudioPermissionService();
}
