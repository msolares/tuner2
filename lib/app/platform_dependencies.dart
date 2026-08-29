import '../domain/services/audio_permission_service.dart';
import '../domain/services/metronome_engine.dart';
import '../domain/services/tuner_engine.dart';
import '../data/metronome/create_metronome_audio_sink.dart';
import '../data/metronome/scheduled_metronome_engine.dart';
import 'platform_dependencies_stub.dart'
    if (dart.library.js_interop) 'platform_dependencies_web.dart'
    if (dart.library.io) 'platform_dependencies_io.dart' as platform;

TunerEngine createTunerEngine() => platform.createTunerEngine();

MetronomeEngine createMetronomeEngine() {
  return ScheduledMetronomeEngine(audioSink: createMetronomeAudioSink());
}

AudioPermissionService createAudioPermissionService() {
  return platform.createAudioPermissionService();
}
