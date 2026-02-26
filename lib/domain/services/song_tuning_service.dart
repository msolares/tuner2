import '../entities/song_tuning_query.dart';
import '../entities/song_tuning_result.dart';

/// Contrato de dominio para obtener afinacion de guitarra por cancion.
abstract class SongTuningService {
  /// Resuelve la afinacion sugerida para [query].
  ///
  /// Puede lanzar [SongTuningLookupException] para errores funcionales del flujo.
  Future<SongTuningResult> resolve(SongTuningQuery query);
}

