import '../../domain/services/audio_permission_service.dart';

class NoopAudioPermissionService implements AudioPermissionService {
  const NoopAudioPermissionService();

  @override
  Future<bool> isGranted() async => true;

  @override
  Future<bool> request() async => true;
}
