class InstrumentPresetProfile {
  const InstrumentPresetProfile({
    required this.id,
    required this.displayName,
    required this.noiseGateDb,
    required this.smoothing,
  });

  final String id;
  final String displayName;
  final double noiseGateDb;
  final double smoothing;
}

const List<InstrumentPresetProfile> kMvpInstrumentPresets = [
  InstrumentPresetProfile(
    id: 'chromatic',
    displayName: 'Chromatic',
    noiseGateDb: -60.0,
    smoothing: 0.20,
  ),
  InstrumentPresetProfile(
    id: 'guitar_standard',
    displayName: 'Guitar (EADGBE)',
    noiseGateDb: -55.0,
    smoothing: 0.24,
  ),
  InstrumentPresetProfile(
    id: 'ukulele_standard',
    displayName: 'Ukulele (GCEA)',
    noiseGateDb: -53.0,
    smoothing: 0.22,
  ),
  InstrumentPresetProfile(
    id: 'bass_standard',
    displayName: 'Bass (EADG)',
    noiseGateDb: -58.0,
    smoothing: 0.28,
  ),
  InstrumentPresetProfile(
    id: 'violin_standard',
    displayName: 'Violin (GDAE)',
    noiseGateDb: -50.0,
    smoothing: 0.18,
  ),
];
