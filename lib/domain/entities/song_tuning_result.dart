import 'guitar_tuning.dart';
import 'song_tuning_query.dart';

/// Resultado de dominio para una consulta de afinacion por cancion.
class SongTuningResult {
  const SongTuningResult({
    required this.query,
    required this.primaryTuning,
    this.alternativeTunings = const <GuitarTuning>[],
  });

  /// Query original utilizada para resolver la afinacion.
  final SongTuningQuery query;

  /// Afinacion principal sugerida para la cancion.
  final GuitarTuning primaryTuning;

  /// Afinaciones alternativas validas cuando existen multiples versiones.
  final List<GuitarTuning> alternativeTunings;

  bool get hasAlternatives => alternativeTunings.isNotEmpty;

  SongTuningResult copyWith({
    SongTuningQuery? query,
    GuitarTuning? primaryTuning,
    List<GuitarTuning>? alternativeTunings,
  }) {
    return SongTuningResult(
      query: query ?? this.query,
      primaryTuning: primaryTuning ?? this.primaryTuning,
      alternativeTunings: alternativeTunings ?? this.alternativeTunings,
    );
  }

  @override
  String toString() {
    return 'SongTuningResult(query: $query, primaryTuning: $primaryTuning, alternativeTunings: $alternativeTunings)';
  }
}

