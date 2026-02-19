/// Contrato de permisos de microfono para flujo cross-platform.
abstract class AudioPermissionService {
  /// Verifica si el permiso ya fue concedido por el sistema operativo.
  Future<bool> isGranted();

  /// Solicita permiso runtime al sistema operativo.
  Future<bool> request();
}
