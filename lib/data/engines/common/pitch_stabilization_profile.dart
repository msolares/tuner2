class PitchStabilizationProfile {
  const PitchStabilizationProfile({
    required this.minReliableConfidence,
    required this.maxHeldFrames,
    required this.noteConfirmationFrames,
    required this.noteSwitchToleranceCents,
    required this.fastSwitchConfidence,
    required this.fastSwitchHzJumpRatio,
    required this.fastResponseCentsDelta,
    required this.fastResponseAlpha,
  });

  final double minReliableConfidence;
  final int maxHeldFrames;
  final int noteConfirmationFrames;
  final double noteSwitchToleranceCents;
  final double fastSwitchConfidence;
  final double fastSwitchHzJumpRatio;
  final double fastResponseCentsDelta;
  final double fastResponseAlpha;
}

PitchStabilizationProfile stabilizationProfileForPreset(String preset) {
  return switch (preset) {
    'guitar_standard' => const PitchStabilizationProfile(
        minReliableConfidence: 0.38,
        maxHeldFrames: 6,
        noteConfirmationFrames: 2,
        noteSwitchToleranceCents: 34.0,
        fastSwitchConfidence: 0.86,
        fastSwitchHzJumpRatio: 0.06,
        fastResponseCentsDelta: 72.0,
        fastResponseAlpha: 0.38,
      ),
    'bass_standard' => const PitchStabilizationProfile(
        minReliableConfidence: 0.34,
        maxHeldFrames: 7,
        noteConfirmationFrames: 2,
        noteSwitchToleranceCents: 30.0,
        fastSwitchConfidence: 0.84,
        fastSwitchHzJumpRatio: 0.055,
        fastResponseCentsDelta: 66.0,
        fastResponseAlpha: 0.36,
      ),
    'ukulele_standard' || 'violin_standard' => const PitchStabilizationProfile(
        minReliableConfidence: 0.40,
        maxHeldFrames: 5,
        noteConfirmationFrames: 2,
        noteSwitchToleranceCents: 36.0,
        fastSwitchConfidence: 0.88,
        fastSwitchHzJumpRatio: 0.05,
        fastResponseCentsDelta: 76.0,
        fastResponseAlpha: 0.40,
      ),
    _ => const PitchStabilizationProfile(
        minReliableConfidence: 0.35,
        maxHeldFrames: 6,
        noteConfirmationFrames: 2,
        noteSwitchToleranceCents: 35.0,
        fastSwitchConfidence: 0.88,
        fastSwitchHzJumpRatio: 0.06,
        fastResponseCentsDelta: 72.0,
        fastResponseAlpha: 0.38,
      ),
  };
}
