import '../entities/pitch_sample.dart';
import '../entities/tuner_settings.dart';

/// Contrato unificado del motor de afinacion para todas las plataformas.
abstract class TunerEngine {
  /// Inicia captura/procesamiento aplicando [settings].
  Future<void> start(TunerSettings settings);

  /// Stream continuo de muestras de pitch.
  Stream<PitchSample> samples();

  /// Detiene captura/procesamiento y libera recursos del motor.
  Future<void> stop();
}
