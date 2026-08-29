import '../../../domain/entities/pitch_sample.dart';
import 'pitch_stabilization_profile.dart';

class PitchEmissionGate {
  PitchEmissionGate({
    this.baseIntervalMs = 60,
  });

  final int baseIntervalMs;
  PitchSample? _lastEmitted;

  void reset() {
    _lastEmitted = null;
  }

  bool shouldEmit({
    required PitchSample sample,
    required PitchStabilizationProfile profile,
  }) {
    final previous = _lastEmitted;
    if (previous == null) {
      _lastEmitted = sample;
      return true;
    }

    final elapsedMs = sample.timestampMs - previous.timestampMs;
    if (elapsedMs < 0) {
      _lastEmitted = sample;
      return true;
    }

    final noteChanged = sample.note != previous.note;
    final transitionedToSilence = previous.note != '--' && sample.note == '--';
    final transitionedFromSilence =
        previous.note == '--' && sample.note != '--';
    final hzJumpRatio = previous.hz > 0 && sample.hz > 0
        ? (sample.hz - previous.hz).abs() / previous.hz
        : (sample.hz != previous.hz ? 1.0 : 0.0);
    final centsDelta = (sample.cents - previous.cents).abs();
    final confidenceRise = sample.confidence - previous.confidence;

    final requiresImmediateEmit = noteChanged ||
        transitionedToSilence ||
        transitionedFromSilence ||
        hzJumpRatio >= profile.fastSwitchHzJumpRatio ||
        centsDelta >= profile.fastResponseCentsDelta ||
        (elapsedMs >= baseIntervalMs ~/ 2 &&
            sample.confidence >= profile.minReliableConfidence &&
            confidenceRise >= 0.12);

    if (requiresImmediateEmit || elapsedMs >= baseIntervalMs) {
      _lastEmitted = sample;
      return true;
    }

    return false;
  }
}
