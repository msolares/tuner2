import '../entities/metronome_settings.dart';

abstract class MetronomeSettingsStore {
  Future<MetronomeSettings?> load();

  Future<void> save(MetronomeSettings settings);
}
