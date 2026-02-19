class TunerErrorInfo {
  const TunerErrorInfo({
    required this.code,
    required this.message,
    required this.recoverable,
    required this.uxExpectation,
  });

  final String code;
  final String message;
  final bool recoverable;
  final String uxExpectation;
}

class TunerErrorPolicy {
  static const Map<String, TunerErrorInfo> _catalog = {
    'audio_permission_denied': TunerErrorInfo(
      code: 'audio_permission_denied',
      message: 'Permiso de microfono denegado.',
      recoverable: true,
      uxExpectation: 'Mostrar CTA para volver a conceder permiso.',
    ),
    'audio_device_unavailable': TunerErrorInfo(
      code: 'audio_device_unavailable',
      message: 'No se encontro dispositivo de entrada de audio.',
      recoverable: true,
      uxExpectation: 'Permitir reintento de inicio.',
    ),
    'engine_start_failed': TunerErrorInfo(
      code: 'engine_start_failed',
      message: 'No se pudo iniciar el motor de afinacion.',
      recoverable: true,
      uxExpectation: 'Mostrar mensaje y mantener controles Start/Stop.',
    ),
    'engine_stream_error': TunerErrorInfo(
      code: 'engine_stream_error',
      message: 'Se interrumpio el stream de audio/deteccion.',
      recoverable: true,
      uxExpectation: 'Volver a Idle o permitir Start inmediato.',
    ),
    'ffi_invalid_handle': TunerErrorInfo(
      code: 'ffi_invalid_handle',
      message: 'Sesion invalida del motor nativo.',
      recoverable: true,
      uxExpectation: 'Reinicializar engine al siguiente Start.',
    ),
    'ffi_invalid_frame': TunerErrorInfo(
      code: 'ffi_invalid_frame',
      message: 'Frame de audio invalido.',
      recoverable: true,
      uxExpectation: 'Descartar frame y continuar captura.',
    ),
    'ffi_invalid_sample_rate': TunerErrorInfo(
      code: 'ffi_invalid_sample_rate',
      message: 'Sample rate no soportado por el motor.',
      recoverable: true,
      uxExpectation: 'Aplicar fallback de parametros y reintentar.',
    ),
    'ffi_internal_error': TunerErrorInfo(
      code: 'ffi_internal_error',
      message: 'Falla interna del motor nativo.',
      recoverable: false,
      uxExpectation: 'Informar error y requerir reinicio de sesion.',
    ),
    'unknown_preset': TunerErrorInfo(
      code: 'unknown_preset',
      message: 'Preset no soportado.',
      recoverable: true,
      uxExpectation: 'Mantener preset anterior y notificar.',
    ),
    'settings_persistence_read_failed': TunerErrorInfo(
      code: 'settings_persistence_read_failed',
      message: 'No se pudo recuperar configuracion guardada.',
      recoverable: true,
      uxExpectation: 'Continuar con defaults sin bloquear.',
    ),
    'settings_persistence_write_failed': TunerErrorInfo(
      code: 'settings_persistence_write_failed',
      message: 'No se pudo guardar la configuracion.',
      recoverable: true,
      uxExpectation: 'Mantener sesion activa y advertir al usuario.',
    ),
    'unexpected_error': TunerErrorInfo(
      code: 'unexpected_error',
      message: 'Ocurrio un error inesperado.',
      recoverable: true,
      uxExpectation: 'Permitir recuperacion por Start/Stop.',
    ),
  };

  static TunerErrorInfo resolve(String code) {
    return _catalog[code] ?? _catalog['unexpected_error']!;
  }
}
