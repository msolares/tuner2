import '../entities/instrument_preset_profile.dart';

abstract class InstrumentPresetCatalog {
  List<InstrumentPresetProfile> all();

  InstrumentPresetProfile? byId(String id);
}
