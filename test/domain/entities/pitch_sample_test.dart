import 'package:afinador/domain/entities/pitch_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PitchSample', () {
    const sample = PitchSample(
      hz: 440.0,
      note: 'A4',
      cents: 0.0,
      confidence: 0.95,
      timestampMs: 1700000000000,
    );

    test('mantiene todos los campos del contrato', () {
      expect(sample.hz, 440.0);
      expect(sample.note, 'A4');
      expect(sample.cents, 0.0);
      expect(sample.confidence, 0.95);
      expect(sample.timestampMs, 1700000000000);
    });

    test('copyWith actualiza solo los campos indicados', () {
      final updated = sample.copyWith(
        cents: -3.2,
        confidence: 0.7,
      );

      expect(updated.hz, sample.hz);
      expect(updated.note, sample.note);
      expect(updated.cents, -3.2);
      expect(updated.confidence, 0.7);
      expect(updated.timestampMs, sample.timestampMs);
    });
  });
}
