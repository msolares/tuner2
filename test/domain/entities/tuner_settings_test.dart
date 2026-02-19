import 'package:afinador/domain/entities/tuner_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TunerSettings', () {
    test('expone defaults esperados para MVP', () {
      expect(TunerSettings.defaults.a4Hz, 440.0);
      expect(TunerSettings.defaults.instrumentPreset, 'chromatic');
      expect(TunerSettings.defaults.noiseGateDb, -60.0);
      expect(TunerSettings.defaults.smoothing, 0.2);
    });

    test('copyWith actualiza solo los campos indicados', () {
      final initial = TunerSettings.defaults;
      final updated = initial.copyWith(
        a4Hz: 442.0,
        instrumentPreset: 'guitar_standard',
      );

      expect(updated.a4Hz, 442.0);
      expect(updated.instrumentPreset, 'guitar_standard');
      expect(updated.noiseGateDb, initial.noiseGateDb);
      expect(updated.smoothing, initial.smoothing);
    });
  });
}
