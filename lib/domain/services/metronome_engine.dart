import '../entities/metronome_settings.dart';
import '../entities/metronome_tick.dart';

/// Contrato de reproducción común para móvil y Web.
abstract class MetronomeEngine {
  Future<void> start(MetronomeSettings settings);

  Future<void> update(MetronomeSettings settings);

  Stream<MetronomeTick> ticks();

  Future<void> stop();
}
