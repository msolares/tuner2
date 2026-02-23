class PitchRange {
  const PitchRange({
    required this.minHz,
    required this.maxHz,
  });

  final double minHz;
  final double maxHz;
}

PitchRange rangeForPreset(String preset) {
  return switch (preset) {
    'guitar_standard' => const PitchRange(minHz: 70.0, maxHz: 420.0),
    'bass_standard' => const PitchRange(minHz: 30.0, maxHz: 260.0),
    'ukulele_standard' => const PitchRange(minHz: 180.0, maxHz: 500.0),
    'violin_standard' => const PitchRange(minHz: 180.0, maxHz: 1200.0),
    _ => const PitchRange(minHz: 50.0, maxHz: 2000.0),
  };
}
