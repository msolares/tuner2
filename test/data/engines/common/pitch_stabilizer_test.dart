import 'package:afinador/data/engines/common/pitch_range.dart';
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
