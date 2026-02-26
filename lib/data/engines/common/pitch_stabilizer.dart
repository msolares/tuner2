import '../../../domain/entities/pitch_sample.dart';
import 'pitch_stabilization_profile.dart';
import 'pitch_range.dart';

class PitchStabilizer {
  PitchStabilizer({
    double minReliableConfidence = 0.35,
    int maxHeldFrames = 12,
    int noteConfirmationFrames = 2,
  })  : _minReliableConfidence = minReliableConfidence,
        _maxHeldFrames = maxHeldFrames,
        _noteConfirmationFrames = noteConfirmationFrames;

  final double _minReliableConfidence;
  final int _maxHeldFrames;
  final int _noteConfirmationFrames;

  PitchSample? _lastStableSample;
  int _heldFrames = 0;
  String? _pendingNoteCandidate;
  int _pendingNoteFrames = 0;

  void reset() {
    _lastStableSample = null;
    _heldFrames = 0;
    _pendingNoteCandidate = null;
    _pendingNoteFrames = 0;
  }

  PitchSample stabilize({
    required PitchSample sample,
    required PitchRange range,
    required double smoothing,
    PitchStabilizationProfile? profile,
  }) {
    final effectiveProfile = profile ??
        PitchStabilizationProfile(
          minReliableConfidence: _minReliableConfidence,
          maxHeldFrames: _maxHeldFrames,
          noteConfirmationFrames: _noteConfirmationFrames,
          noteSwitchToleranceCents: 35.0,
          fastSwitchConfidence: 0.9,
          fastSwitchHzJumpRatio: 0.06,
          fastResponseCentsDelta: 72.0,
          fastResponseAlpha: 0.38,
        );

    var candidate = sample;
    if (candidate.hz > 0 && (candidate.hz < range.minHz || candidate.hz > range.maxHz)) {
      candidate = candidate.copyWith(hz: 0, note: '--', cents: 0, confidence: 0);
    }

    if (candidate.hz <= 0 || candidate.confidence < effectiveProfile.minReliableConfidence) {
      final held = _holdLastStable(candidate.timestampMs, profile: effectiveProfile);
      if (held != null) {
        return held;
      }
      _clearPendingNote();
      return candidate.copyWith(hz: 0, note: '--', cents: 0, confidence: 0);
    }

    _heldFrames = 0;
    final previous = _lastStableSample;
    if (previous == null) {
      _clearPendingNote();
      _lastStableSample = candidate;
      return candidate;
    }

    final resolvedNote = _resolveNote(
      sample: candidate,
      previous: previous,
      profile: effectiveProfile,
    );
    final alpha = _blendAlpha(
      smoothing,
      sample: candidate,
      previous: previous,
      profile: effectiveProfile,
    );
    final stabilized = candidate.copyWith(
      note: resolvedNote,
      hz: _lerp(previous.hz, candidate.hz, alpha),
      cents: _lerp(previous.cents, candidate.cents, alpha),
      confidence: _lerp(previous.confidence, candidate.confidence, (alpha + 0.25).clamp(0.0, 1.0)),
    );
    _lastStableSample = stabilized;
    return stabilized;
  }

  PitchSample? _holdLastStable(
    int timestampMs, {
    required PitchStabilizationProfile profile,
  }) {
    final previous = _lastStableSample;
    if (previous == null || _heldFrames >= profile.maxHeldFrames) {
      _lastStableSample = null;
      return null;
    }
    _heldFrames += 1;
    final confidence = (previous.confidence - 0.08 * _heldFrames).clamp(0.0, 1.0);
    return previous.copyWith(confidence: confidence, timestampMs: timestampMs);
  }

  String _resolveNote({
    required PitchSample sample,
    required PitchSample previous,
    required PitchStabilizationProfile profile,
  }) {
    if (sample.note == previous.note || sample.note == '--') {
      _clearPendingNote();
      return previous.note;
    }

    if (_shouldSwitchImmediately(
      sample: sample,
      previous: previous,
      profile: profile,
    )) {
      _clearPendingNote();
      return sample.note;
    }

    if (sample.cents.abs() > profile.noteSwitchToleranceCents) {
      _clearPendingNote();
      return previous.note;
    }

    if (_pendingNoteCandidate == sample.note) {
      _pendingNoteFrames += 1;
    } else {
      _pendingNoteCandidate = sample.note;
      _pendingNoteFrames = 1;
    }

    if (_pendingNoteFrames >= profile.noteConfirmationFrames) {
      _clearPendingNote();
      return sample.note;
    }
    return previous.note;
  }

  bool _shouldSwitchImmediately({
    required PitchSample sample,
    required PitchSample previous,
    required PitchStabilizationProfile profile,
  }) {
    if (sample.confidence < profile.fastSwitchConfidence || previous.hz <= 0) {
      return false;
    }
    final hzJump = (sample.hz - previous.hz).abs() / previous.hz;
    return hzJump >= profile.fastSwitchHzJumpRatio;
  }

  void _clearPendingNote() {
    _pendingNoteCandidate = null;
    _pendingNoteFrames = 0;
  }

  double _blendAlpha(
    double smoothing, {
    required PitchSample sample,
    required PitchSample previous,
    required PitchStabilizationProfile profile,
  }) {
    final normalized = smoothing.clamp(0.0, 1.0);
    final baseAlpha = (normalized * 0.45).clamp(0.05, 0.20);
    final centsDelta = (sample.cents - previous.cents).abs();
    if (centsDelta >= profile.fastResponseCentsDelta) {
      return baseAlpha.clamp(profile.fastResponseAlpha, 0.45).toDouble();
    }
    return baseAlpha;
  }

  double _lerp(double previous, double current, double alpha) {
    return previous + (current - previous) * alpha;
  }
}
