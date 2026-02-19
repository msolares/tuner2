/// Configuracion activa del afinador para el motor de deteccion.
class TunerSettings {
  static const double minA4Hz = 430.0;
  static const double maxA4Hz = 450.0;
  static const double defaultA4Hz = 440.0;

  const TunerSettings({
    required this.a4Hz,
    required this.instrumentPreset,
    required this.noiseGateDb,
    required this.smoothing,
  });

  /// Referencia de afinacion para A4 en Hertz (tipico 440.0).
  final double a4Hz;

  /// Preset de instrumento (por ejemplo `chromatic`, `guitar_standard`).
  final String instrumentPreset;

  /// Umbral de ruido en dB para filtrar detecciones inestables.
  final double noiseGateDb;

  /// Factor de suavizado de salida esperado en rango [0.0, 1.0].
  final double smoothing;

  static const TunerSettings defaults = TunerSettings(
    a4Hz: defaultA4Hz,
    instrumentPreset: 'chromatic',
    noiseGateDb: -60.0,
    smoothing: 0.2,
  );

  TunerSettings copyWith({
    double? a4Hz,
    String? instrumentPreset,
    double? noiseGateDb,
    double? smoothing,
  }) {
    return TunerSettings(
      a4Hz: a4Hz ?? this.a4Hz,
      instrumentPreset: instrumentPreset ?? this.instrumentPreset,
      noiseGateDb: noiseGateDb ?? this.noiseGateDb,
      smoothing: smoothing ?? this.smoothing,
    );
  }

  static double normalizeA4Hz(double value) {
    return value.clamp(minA4Hz, maxA4Hz).toDouble();
  }

  @override
  String toString() {
    return 'TunerSettings(a4Hz: $a4Hz, instrumentPreset: $instrumentPreset, noiseGateDb: $noiseGateDb, smoothing: $smoothing)';
  }
}
