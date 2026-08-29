import '../domain/services/audio_permission_service.dart';
import '../domain/services/tuner_engine.dart';

TunerEngine createTunerEngine() {
  throw UnsupportedError(
      'No existe una implementacion de TunerEngine para esta plataforma.');
}

AudioPermissionService createAudioPermissionService() {
  throw UnsupportedError(
      'No existe servicio de permisos para esta plataforma.');
}
