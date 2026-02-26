enum SongTuningErrorCode {
  invalidQuery,
  notFound,
  ambiguousSong,
  timeout,
  rateLimited,
  providerUnavailable,
  unauthorized,
  invalidResponse,
  unknown,
}

enum SongTuningRecoverability {
  recoverable,
  nonRecoverable,
}

/// Error de dominio para consultas de afinacion por cancion.
class SongTuningLookupException implements Exception {
  const SongTuningLookupException(
    this.code, {
    this.message,
  });

  final SongTuningErrorCode code;
  final String? message;

  SongTuningRecoverability get recoverability {
    return switch (code) {
      SongTuningErrorCode.invalidQuery => SongTuningRecoverability.recoverable,
      SongTuningErrorCode.notFound => SongTuningRecoverability.recoverable,
      SongTuningErrorCode.ambiguousSong => SongTuningRecoverability.recoverable,
      SongTuningErrorCode.timeout => SongTuningRecoverability.recoverable,
      SongTuningErrorCode.rateLimited => SongTuningRecoverability.recoverable,
      SongTuningErrorCode.providerUnavailable => SongTuningRecoverability.recoverable,
      SongTuningErrorCode.unauthorized => SongTuningRecoverability.nonRecoverable,
      SongTuningErrorCode.invalidResponse => SongTuningRecoverability.nonRecoverable,
      SongTuningErrorCode.unknown => SongTuningRecoverability.nonRecoverable,
    };
  }

  bool get recoverable => recoverability == SongTuningRecoverability.recoverable;

  @override
  String toString() {
    return 'SongTuningLookupException(code: $code, recoverability: $recoverability, message: $message)';
  }
}

