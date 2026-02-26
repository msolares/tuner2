import 'package:afinador/domain/services/song_tuning_lookup_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongTuningLookupException', () {
    test('marca errores recuperables esperados', () {
      const timeout = SongTuningLookupException(SongTuningErrorCode.timeout);
      const ambiguous = SongTuningLookupException(SongTuningErrorCode.ambiguousSong);

      expect(timeout.recoverable, isTrue);
      expect(ambiguous.recoverability, SongTuningRecoverability.recoverable);
    });

    test('marca errores no recuperables esperados', () {
      const unauthorized = SongTuningLookupException(SongTuningErrorCode.unauthorized);
      const invalidResponse = SongTuningLookupException(SongTuningErrorCode.invalidResponse);

      expect(unauthorized.recoverable, isFalse);
      expect(invalidResponse.recoverability, SongTuningRecoverability.nonRecoverable);
    });
  });
}

