import '../data/audio/recorder_audio_frame_source.dart';
import '../data/engines/mobile/mobile_ffi_tuner_engine.dart';
import '../data/permissions/permission_handler_audio_permission_service.dart';
import '../domain/services/audio_permission_service.dart';
import '../domain/services/tuner_engine.dart';

TunerEngine createTunerEngine() {
  return MobileFfiTunerEngine(
    frameSource: RecorderAudioFrameSource(),
  );
}

AudioPermissionService createAudioPermissionService() {
  return PermissionHandlerAudioPermissionService();
}
