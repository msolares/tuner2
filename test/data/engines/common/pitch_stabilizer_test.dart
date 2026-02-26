import 'package:afinador/data/engines/common/pitch_range.dart';
import 'package:afinador/data/engines/common/pitch_stabilization_profile.dart';
import 'package:afinador/data/engines/common/pitch_stabilizer.dart';
import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PitchStabilizer', () {
    test('requiere confirmacion para cambiar de nota y evita flicker', () {
      final stabilizer = PitchStabilizer(noteConfirmationFrames: 2);
      const range = PitchRange(minHz: 50, maxHz: 2000);

      final first = stabilizer.stabilize(
        sample: _sample(note: 'A4', hz: 440, cents: 2, confidence: 0.92, timestampMs: 100),
        range: range,
        smoothing: 0.2,
      );
      expect(first.note, 'A4');

      final transient = stabilizer.stabilize(
        sample: _sample(note: 'B4', hz: 493.88, cents: 3, confidence: 0.80, timestampMs: 220),
        range: range,
        smoothing: 0.2,
      );
      expect(transient.note, 'A4');

      final confirmed = stabilizer.stabilize(
        sample: _sample(note: 'B4', hz: 493.88, cents: 1, confidence: 0.80, timestampMs: 340),
        range: range,
        smoothing: 0.2,
      );
      expect(confirmed.note, 'B4');
    });

    test('retiene brevemente la muestra estable cuando cae confidence', () {
      final stabilizer = PitchStabilizer(maxHeldFrames: 2);
      const range = PitchRange(minHz: 50, maxHz: 2000);

      final stable = stabilizer.stabilize(
        sample: _sample(note: 'E4', hz: 329.63, cents: 0.5, confidence: 0.90, timestampMs: 100),
        range: range,
        smoothing: 0.2,
      );
      final held = stabilizer.stabilize(
        sample: _sample(note: '--', hz: 0.0, cents: 0.0, confidence: 0.1, timestampMs: 220),
        range: range,
        smoothing: 0.2,
      );

      expect(stable.note, 'E4');
      expect(held.note, 'E4');
      expect(held.confidence, lessThan(stable.confidence));
    });

    test('libera retencion despues del limite de frames', () {
      final stabilizer = PitchStabilizer(maxHeldFrames: 2);
      const range = PitchRange(minHz: 50, maxHz: 2000);

      stabilizer.stabilize(
        sample: _sample(note: 'D4', hz: 293.66, cents: 0.0, confidence: 0.92, timestampMs: 100),
        range: range,
        smoothing: 0.2,
      );
      stabilizer.stabilize(
        sample: _sample(note: '--', hz: 0.0, cents: 0.0, confidence: 0.1, timestampMs: 220),
        range: range,
        smoothing: 0.2,
      );
      stabilizer.stabilize(
        sample: _sample(note: '--', hz: 0.0, cents: 0.0, confidence: 0.1, timestampMs: 340),
        range: range,
        smoothing: 0.2,
      );
      final released = stabilizer.stabilize(
        sample: _sample(note: '--', hz: 0.0, cents: 0.0, confidence: 0.1, timestampMs: 460),
        range: range,
        smoothing: 0.2,
      );

      expect(released.note, '--');
      expect(released.hz, 0.0);
      expect(released.confidence, 0.0);
    });

    test('descarta frecuencias fuera de rango del preset', () {
      final stabilizer = PitchStabilizer();
      const guitarRange = PitchRange(minHz: 70, maxHz: 420);

      final outOfRange = stabilizer.stabilize(
        sample: _sample(note: 'A5', hz: 880.0, cents: 0.0, confidence: 0.95, timestampMs: 100),
        range: guitarRange,
        smoothing: 0.2,
      );

      expect(outOfRange.note, '--');
      expect(outOfRange.hz, 0.0);
      expect(outOfRange.confidence, 0.0);
    });

    test('mantiene nota previa si candidata nueva queda cerca del borde de cents', () {
      final stabilizer = PitchStabilizer(noteConfirmationFrames: 1);
      const range = PitchRange(minHz: 50, maxHz: 2000);
      const profile = PitchStabilizationProfile(
        minReliableConfidence: 0.35,
        maxHeldFrames: 6,
        noteConfirmationFrames: 1,
        noteSwitchToleranceCents: 35.0,
        fastSwitchConfidence: 0.95,
        fastSwitchHzJumpRatio: 0.08,
        fastResponseCentsDelta: 72.0,
        fastResponseAlpha: 0.38,
      );

      final stable = stabilizer.stabilize(
        sample: _sample(note: 'A4', hz: 440, cents: 20, confidence: 0.92, timestampMs: 100),
        range: range,
        smoothing: 0.2,
        profile: profile,
      );
      final nearBoundary = stabilizer.stabilize(
        sample: _sample(note: 'A#4', hz: 466.16, cents: -46, confidence: 0.82, timestampMs: 220),
        range: range,
        smoothing: 0.2,
        profile: profile,
      );

      expect(stable.note, 'A4');
      expect(nearBoundary.note, 'A4');
    });

    test('acelera respuesta en salto grande de cents para cambio real', () {
      final stabilizer = PitchStabilizer();
      const range = PitchRange(minHz: 50, maxHz: 2000);
      const slowProfile = PitchStabilizationProfile(
        minReliableConfidence: 0.35,
        maxHeldFrames: 6,
        noteConfirmationFrames: 2,
        noteSwitchToleranceCents: 35.0,
        fastSwitchConfidence: 0.95,
        fastSwitchHzJumpRatio: 0.08,
        fastResponseCentsDelta: 70.0,
        fastResponseAlpha: 0.40,
      );

      final baseline = stabilizer.stabilize(
        sample: _sample(note: 'A4', hz: 440, cents: 1, confidence: 0.92, timestampMs: 100),
        range: range,
        smoothing: 0.8,
        profile: slowProfile,
      );
      final jumped = stabilizer.stabilize(
        sample: _sample(note: 'E5', hz: 659.25, cents: 1, confidence: 0.92, timestampMs: 220),
        range: range,
        smoothing: 0.8,
        profile: slowProfile,
      );

      expect(baseline.hz, closeTo(440, 0.01));
      expect(jumped.hz, closeTo(527.7, 0.5));
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
