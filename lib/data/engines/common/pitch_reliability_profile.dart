import 'dart:math';

class PitchReliabilityProfile {
  const PitchReliabilityProfile({
    required this.minReliableConfidence,
    required this.confirmationFrames,
    required this.switchConfirmationFrames,
    required this.releaseFrames,
    required this.attackSuppressionFrames,
    required this.attackTargetWindowCents,
    required this.attackMaxCentsDelta,
    required this.attackConfidenceBypass,
    required this.fastSwitchConfidence,
    required this.fastSwitchHzJumpRatio,
    required this.softTargetPenaltyStartCents,
    required this.hardTargetPenaltyCents,
    required this.targetConfidenceFloor,
    required this.targets,
  });

  final double minReliableConfidence;
  final int confirmationFrames;
  final int switchConfirmationFrames;
  final int releaseFrames;
  final int attackSuppressionFrames;
  final double attackTargetWindowCents;
  final double attackMaxCentsDelta;
  final double attackConfidenceBypass;
  final double fastSwitchConfidence;
  final double fastSwitchHzJumpRatio;
  final double softTargetPenaltyStartCents;
  final double hardTargetPenaltyCents;
  final double targetConfidenceFloor;
  final List<PitchTarget> targets;
}

class PitchTarget {
  const PitchTarget({
    required this.id,
    required this.note,
    required this.hz,
  });

  final String id;
  final String note;
  final double hz;
}

PitchReliabilityProfile reliabilityProfileForPreset(String preset) {
  return switch (preset) {
    'guitar_standard' => const PitchReliabilityProfile(
        minReliableConfidence: 0.24,
        confirmationFrames: 2,
        switchConfirmationFrames: 2,
        releaseFrames: 7,
        attackSuppressionFrames: 1,
        attackTargetWindowCents: 190.0,
        attackMaxCentsDelta: 72.0,
        attackConfidenceBypass: 0.96,
        fastSwitchConfidence: 0.94,
        fastSwitchHzJumpRatio: 0.22,
        softTargetPenaltyStartCents: 90.0,
        hardTargetPenaltyCents: 210.0,
        targetConfidenceFloor: 0.35,
        targets: [
          PitchTarget(id: 'guitar_e2', note: 'E2', hz: 82.41),
          PitchTarget(id: 'guitar_a2', note: 'A2', hz: 110.00),
          PitchTarget(id: 'guitar_d3', note: 'D3', hz: 146.83),
          PitchTarget(id: 'guitar_g3', note: 'G3', hz: 196.00),
          PitchTarget(id: 'guitar_b3', note: 'B3', hz: 246.94),
          PitchTarget(id: 'guitar_e4', note: 'E4', hz: 329.63),
        ],
      ),
    'bass_standard' => const PitchReliabilityProfile(
        minReliableConfidence: 0.24,
        confirmationFrames: 2,
        switchConfirmationFrames: 2,
        releaseFrames: 8,
        attackSuppressionFrames: 1,
        attackTargetWindowCents: 190.0,
        attackMaxCentsDelta: 72.0,
        attackConfidenceBypass: 0.95,
        fastSwitchConfidence: 0.92,
        fastSwitchHzJumpRatio: 0.18,
        softTargetPenaltyStartCents: 90.0,
        hardTargetPenaltyCents: 200.0,
        targetConfidenceFloor: 0.35,
        targets: [
          PitchTarget(id: 'bass_e1', note: 'E1', hz: 41.20),
          PitchTarget(id: 'bass_a1', note: 'A1', hz: 55.00),
          PitchTarget(id: 'bass_d2', note: 'D2', hz: 73.42),
          PitchTarget(id: 'bass_g2', note: 'G2', hz: 98.00),
        ],
      ),
    'ukulele_standard' => const PitchReliabilityProfile(
        minReliableConfidence: 0.26,
        confirmationFrames: 2,
        switchConfirmationFrames: 1,
        releaseFrames: 6,
        attackSuppressionFrames: 1,
        attackTargetWindowCents: 120.0,
        attackMaxCentsDelta: 72.0,
        attackConfidenceBypass: 0.96,
        fastSwitchConfidence: 0.93,
        fastSwitchHzJumpRatio: 0.16,
        softTargetPenaltyStartCents: 85.0,
        hardTargetPenaltyCents: 180.0,
        targetConfidenceFloor: 0.35,
        targets: [
          PitchTarget(id: 'uke_g4', note: 'G4', hz: 392.00),
          PitchTarget(id: 'uke_c4', note: 'C4', hz: 261.63),
          PitchTarget(id: 'uke_e4', note: 'E4', hz: 329.63),
          PitchTarget(id: 'uke_a4', note: 'A4', hz: 440.00),
        ],
      ),
    'violin_standard' => const PitchReliabilityProfile(
        minReliableConfidence: 0.26,
        confirmationFrames: 2,
        switchConfirmationFrames: 1,
        releaseFrames: 6,
        attackSuppressionFrames: 1,
        attackTargetWindowCents: 150.0,
        attackMaxCentsDelta: 72.0,
        attackConfidenceBypass: 0.96,
        fastSwitchConfidence: 0.93,
        fastSwitchHzJumpRatio: 0.16,
        softTargetPenaltyStartCents: 85.0,
        hardTargetPenaltyCents: 180.0,
        targetConfidenceFloor: 0.35,
        targets: [
          PitchTarget(id: 'violin_g3', note: 'G3', hz: 196.00),
          PitchTarget(id: 'violin_d4', note: 'D4', hz: 293.66),
          PitchTarget(id: 'violin_a4', note: 'A4', hz: 440.00),
          PitchTarget(id: 'violin_e5', note: 'E5', hz: 659.25),
        ],
      ),
    _ => const PitchReliabilityProfile(
        minReliableConfidence: 0.28,
        confirmationFrames: 2,
        switchConfirmationFrames: 2,
        releaseFrames: 6,
        attackSuppressionFrames: 0,
        attackTargetWindowCents: 0.0,
        attackMaxCentsDelta: 0.0,
        attackConfidenceBypass: 1.0,
        fastSwitchConfidence: 1.0,
        fastSwitchHzJumpRatio: 1.0,
        softTargetPenaltyStartCents: 0.0,
        hardTargetPenaltyCents: 0.0,
        targetConfidenceFloor: 1.0,
        targets: [],
      ),
  };
}

PitchTarget? nearestTargetForHz(double hz, PitchReliabilityProfile profile) {
  if (profile.targets.isEmpty || hz <= 0) {
    return null;
  }
  var current = profile.targets.first;
  var bestDistance = absCentsBetween(hz, current.hz);
  for (final target in profile.targets.skip(1)) {
    final distance = absCentsBetween(hz, target.hz);
    if (distance < bestDistance) {
      current = target;
      bestDistance = distance;
    }
  }
  return current;
}

double absCentsBetween(double leftHz, double rightHz) {
  return signedCentsBetween(leftHz, rightHz).abs();
}

double signedCentsBetween(double leftHz, double rightHz) {
  if (leftHz <= 0 || rightHz <= 0) {
    return double.infinity;
  }
  return 1200 * (log(leftHz / rightHz) / ln2);
}
