/// Muestra de pitch normalizada para la capa de dominio.
///
/// Este contrato es compartido por motores movil (Rust/FFI) y Web (Dart).
class PitchSample {
  const PitchSample({
    required this.hz,
    required this.note,
    required this.cents,
    required this.confidence,
    required this.timestampMs,
  });

  /// Frecuencia fundamental detectada en Hertz.
  final double hz;

  /// Nota musical formateada para UI (por ejemplo `A4`, `C#3`).
  final String note;

  /// Desviacion respecto de la nota objetivo en cents.
  final double cents;

  /// Confianza normalizada del detector en rango [0.0, 1.0].
  final double confidence;

  /// Timestamp Unix epoch en milisegundos del frame procesado.
  final int timestampMs;

  PitchSample copyWith({
    double? hz,
    String? note,
    double? cents,
    double? confidence,
    int? timestampMs,
  }) {
    return PitchSample(
      hz: hz ?? this.hz,
      note: note ?? this.note,
      cents: cents ?? this.cents,
      confidence: confidence ?? this.confidence,
      timestampMs: timestampMs ?? this.timestampMs,
    );
  }

  @override
  String toString() {
    return 'PitchSample(hz: $hz, note: $note, cents: $cents, confidence: $confidence, timestampMs: $timestampMs)';
  }
}
