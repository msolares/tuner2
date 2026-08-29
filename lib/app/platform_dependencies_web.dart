import '../data/audio/web_audio_session.dart';
import '../data/engines/web/web_tuner_engine.dart';
import '../data/permissions/noop_audio_permission_service.dart';
import '../domain/services/audio_permission_service.dart';
import '../domain/services/tuner_engine.dart';

TunerEngine createTunerEngine() {
  WebAudioSession.instance.installActivationListener();
  return WebTunerEngine();
}

AudioPermissionService createAudioPermissionService() {
  return const NoopAudioPermissionService();
}
