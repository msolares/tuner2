import 'package:permission_handler/permission_handler.dart';

import '../../domain/services/audio_permission_service.dart';

class PermissionHandlerAudioPermissionService implements AudioPermissionService {
  @override
  Future<bool> isGranted() async {
    return Permission.microphone.status.isGranted;
  }

  @override
  Future<bool> request() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}
