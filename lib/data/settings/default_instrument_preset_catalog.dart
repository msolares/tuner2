import '../../domain/entities/instrument_preset_profile.dart';
import '../../domain/services/instrument_preset_catalog.dart';

class DefaultInstrumentPresetCatalog implements InstrumentPresetCatalog {
  const DefaultInstrumentPresetCatalog();

  @override
  List<InstrumentPresetProfile> all() => kMvpInstrumentPresets;

  @override
  InstrumentPresetProfile? byId(String id) {
    for (final preset in kMvpInstrumentPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}
