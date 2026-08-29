import '../../../domain/entities/pitch_sample.dart';
import 'pitch_reliability_profile.dart';

class PitchReliabilityGate {
  String? _pendingBucket;
  int _pendingFrames = 0;
  double? _lastPendingCents;
  PitchTarget? _confirmedTarget;
  int _silentFrames = 0;
  int _attackStableFrames = 0;
  double? _lastLockedCents;

  void reset() {
    _pendingBucket = null;
    _pendingFrames = 0;
    _lastPendingCents = null;
    _confirmedTarget = null;
    _silentFrames = 0;
    _attackStableFrames = 0;
    _lastLockedCents = null;
  }

  PitchSample filter({
    required PitchSample sample,
    required PitchReliabilityProfile profile,
  }) {
    if (profile.targets.isEmpty) {
      return _filterWithoutTargets(sample, profile);
    }
    if (sample.hz <= 0 || sample.note == '--') {
      return _handleSilence(sample.timestampMs, profile);
    }

    final adjusted = _applyTargetPenalty(sample, profile);
    if (adjusted.confidence < profile.minReliableConfidence) {
      return _handleSilence(adjusted.timestampMs, profile);
    }

    _silentFrames = 0;
    final target = nearestTargetForHz(adjusted.hz, profile);
    if (target == null) {
      return _handleSilence(adjusted.timestampMs, profile);
    }

    final normalized = _normalizeToTarget(adjusted, target);
    if (_confirmedTarget == null) {
      return _attemptInitialLock(normalized, target, profile);
    }
    if (_confirmedTarget!.id == target.id) {
      _clearPending();
      return _emitLocked(normalized, profile);
    }
    return _attemptSwitch(normalized, target, profile);
  }

  PitchSample _filterWithoutTargets(
    PitchSample sample,
    PitchReliabilityProfile profile,
  ) {
    if (sample.hz <= 0 ||
        sample.note == '--' ||
        sample.confidence < profile.minReliableConfidence) {
      return _handleSilence(sample.timestampMs, profile);
    }

    _silentFrames = 0;
    final bucket = sample.note;
    if (_confirmedTarget != null && _confirmedTarget!.id == bucket) {
      _clearPending();
      return sample;
    }

    if (_pendingBucket == bucket) {
      _pendingFrames += 1;
    } else {
      _pendingBucket = bucket;
      _pendingFrames = 1;
    }

    final requiredFrames = _confirmedTarget == null
        ? profile.confirmationFrames
        : profile.switchConfirmationFrames;
    if (_pendingFrames >= requiredFrames) {
      _confirmedTarget =
          PitchTarget(id: bucket, note: sample.note, hz: sample.hz);
      _clearPending();
      return sample;
    }

    return _silence(sample.timestampMs);
  }

  PitchSample _attemptInitialLock(
    PitchSample sample,
    PitchTarget target,
    PitchReliabilityProfile profile,
  ) {
    if (!_advancePending(target.id, sample.cents, profile)) {
      return _silence(sample.timestampMs);
    }
    if (_pendingFrames < profile.confirmationFrames) {
      return _silence(sample.timestampMs);
    }

    _beginLock(target);
    _clearPending();
    return _emitLocked(sample, profile);
  }

  PitchSample _attemptSwitch(
    PitchSample sample,
    PitchTarget target,
    PitchReliabilityProfile profile,
  ) {
    if (_shouldFastSwitch(sample, profile)) {
      _beginLock(target);
      _clearPending();
      return _emitLocked(sample, profile);
    }

    if (!_advancePending(target.id, sample.cents, profile)) {
      return _silence(sample.timestampMs);
    }
    if (_pendingFrames < profile.switchConfirmationFrames) {
      return _silence(sample.timestampMs);
    }

    _beginLock(target);
    _clearPending();
    return _emitLocked(sample, profile);
  }

  PitchSample _emitLocked(
    PitchSample sample,
    PitchReliabilityProfile profile,
  ) {
    final stableFrame = _isStableAttackFrame(sample, profile);
    if (profile.attackSuppressionFrames > 0) {
      _attackStableFrames = stableFrame ? _attackStableFrames + 1 : 0;
      _lastLockedCents = sample.cents;
      if (_attackStableFrames < profile.attackSuppressionFrames) {
        return _silence(sample.timestampMs);
      }
    }
    _attackStableFrames = profile.attackSuppressionFrames == 0
        ? 0
        : (_attackStableFrames == 0 ? 1 : _attackStableFrames);
    _lastLockedCents = sample.cents;
    return sample;
  }

  PitchSample _handleSilence(
    int timestampMs,
    PitchReliabilityProfile profile,
  ) {
    _silentFrames += 1;
    if (_silentFrames >= profile.releaseFrames) {
      _confirmedTarget = null;
      _attackStableFrames = 0;
      _lastLockedCents = null;
      _clearPending();
    }
    return _silence(timestampMs);
  }

  PitchSample _applyTargetPenalty(
    PitchSample sample,
    PitchReliabilityProfile profile,
  ) {
    final nearestTarget = nearestTargetForHz(sample.hz, profile);
    if (nearestTarget == null) {
      return sample;
    }

    final centsDistance = absCentsBetween(sample.hz, nearestTarget.hz);
    if (centsDistance <= profile.softTargetPenaltyStartCents) {
      return sample;
    }

    final normalized = ((centsDistance - profile.softTargetPenaltyStartCents) /
            (profile.hardTargetPenaltyCents -
                profile.softTargetPenaltyStartCents))
        .clamp(0.0, 1.0);
    final factor = 1.0 - normalized * (1.0 - profile.targetConfidenceFloor);
    return sample.copyWith(
      confidence: (sample.confidence * factor).clamp(0.0, 1.0),
    );
  }

  PitchSample _normalizeToTarget(PitchSample sample, PitchTarget target) {
    return sample.copyWith(
      note: target.note,
      cents: signedCentsBetween(sample.hz, target.hz),
    );
  }

  bool _shouldFastSwitch(
    PitchSample sample,
    PitchReliabilityProfile profile,
  ) {
    final lockedTarget = _confirmedTarget;
    if (lockedTarget == null ||
        sample.confidence < profile.fastSwitchConfidence) {
      return false;
    }
    final hzJump = (sample.hz - lockedTarget.hz).abs() / lockedTarget.hz;
    return hzJump >= profile.fastSwitchHzJumpRatio;
  }

  bool _advancePending(
    String bucket,
    double cents,
    PitchReliabilityProfile profile,
  ) {
    final sameBucket = _pendingBucket == bucket;
    final canCount = _isStablePendingFrame(
      cents,
      profile,
      sameBucket: sameBucket,
    );
    if (sameBucket && canCount) {
      _pendingFrames += 1;
    } else {
      _pendingBucket = bucket;
      _pendingFrames = canCount ? 1 : 0;
    }
    _lastPendingCents = cents;
    return _pendingFrames > 0;
  }

  bool _isStablePendingFrame(
    double cents,
    PitchReliabilityProfile profile, {
    required bool sameBucket,
  }) {
    if (cents.abs() > profile.attackTargetWindowCents) {
      return false;
    }
    if (!sameBucket || _lastPendingCents == null) {
      return true;
    }
    return (cents - _lastPendingCents!).abs() <= profile.attackMaxCentsDelta;
  }

  bool _isStableAttackFrame(
    PitchSample sample,
    PitchReliabilityProfile profile,
  ) {
    if (sample.confidence >= profile.attackConfidenceBypass) {
      return true;
    }
    if (sample.cents.abs() > profile.attackTargetWindowCents) {
      return false;
    }
    if (_lastLockedCents == null) {
      return true;
    }
    return (sample.cents - _lastLockedCents!).abs() <=
        profile.attackMaxCentsDelta;
  }

  PitchSample _silence(int timestampMs) {
    return PitchSample(
      hz: 0.0,
      note: '--',
      cents: 0.0,
      confidence: 0.0,
      timestampMs: timestampMs,
    );
  }

  void _beginLock(PitchTarget target) {
    _confirmedTarget = target;
    _silentFrames = 0;
    _attackStableFrames = 0;
    _lastLockedCents = null;
  }

  void _clearPending() {
    _pendingBucket = null;
    _pendingFrames = 0;
    _lastPendingCents = null;
  }
}
