import 'package:afinador/data/engines/common/pitch_emission_gate.dart';
import 'package:afinador/data/engines/common/pitch_stabilization_profile.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PitchEmissionGate', () {
    const profile = PitchStabilizationProfile(
      minReliableConfidence: 0.38,
      maxHeldFrames: 4,
      noteConfirmationFrames: 2,
      noteSwitchToleranceCents: 34.0,
      fastSwitchConfidence: 0.86,
      fastSwitchHzJumpRatio: 0.06,
      fastResponseCentsDelta: 72.0,
      fastResponseAlpha: 0.42,
    );

    test('emits the first sample immediately', () {
      final gate = PitchEmissionGate(baseIntervalMs: 60);

      final emitted = gate.shouldEmit(
        sample: _sample(note: 'E2', hz: 82.41, cents: 4.0, confidence: 0.9, timestampMs: 100),
        profile: profile,
      );

      expect(emitted, isTrue);
    });

    test('throttles minor same-note updates inside the interval', () {
      final gate = PitchEmissionGate(baseIntervalMs: 60);

      gate.shouldEmit(
        sample: _sample(note: 'E2', hz: 82.41, cents: 4.0, confidence: 0.9, timestampMs: 100),
        profile: profile,
      );
      final emitted = gate.shouldEmit(
        sample: _sample(note: 'E2', hz: 82.44, cents: 5.0, confidence: 0.91, timestampMs: 140),
        profile: profile,
      );

      expect(emitted, isFalse);
    });

    test('allows rapid emission for a real note change inside the interval', () {
      final gate = PitchEmissionGate(baseIntervalMs: 60);

      gate.shouldEmit(
        sample: _sample(note: 'E2', hz: 82.41, cents: 4.0, confidence: 0.9, timestampMs: 100),
        profile: profile,
      );
      final emitted = gate.shouldEmit(
        sample: _sample(note: 'A2', hz: 110.0, cents: 3.0, confidence: 0.91, timestampMs: 140),
        profile: profile,
      );

      expect(emitted, isTrue);
    });

    test('allows rapid emission for a large cents jump inside the interval', () {
      final gate = PitchEmissionGate(baseIntervalMs: 60);

      gate.shouldEmit(
        sample: _sample(note: 'A4', hz: 440.0, cents: 1.0, confidence: 0.9, timestampMs: 100),
        profile: profile,
      );
      final emitted = gate.shouldEmit(
        sample: _sample(note: 'A4', hz: 460.0, cents: 95.0, confidence: 0.91, timestampMs: 140),
        profile: profile,
      );

      expect(emitted, isTrue);
    });
  });
}

PitchSample _sample({
  required String note,
  required double hz,
  required double cents,
  required double confidence,
  required int timestampMs,
}) {
  return PitchSample(
    hz: hz,
    note: note,
    cents: cents,
    confidence: confidence,
    timestampMs: timestampMs,
  );
}
