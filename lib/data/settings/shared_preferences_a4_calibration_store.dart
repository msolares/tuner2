import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/tuner_settings.dart';
import '../../domain/services/a4_calibration_store.dart';

class SharedPreferencesA4CalibrationStore implements A4CalibrationStore {
  static const String _keyA4Hz = 'tuner.a4_hz';

  @override
  Future<double?> readA4Hz() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_keyA4Hz);
    if (value == null) {
      return null;
    }
    return TunerSettings.normalizeA4Hz(value);
  }

  @override
  Future<void> writeA4Hz(double a4Hz) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyA4Hz, TunerSettings.normalizeA4Hz(a4Hz));
  }
}
