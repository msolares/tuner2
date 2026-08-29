import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/metronome_settings.dart';
import '../../domain/services/metronome_settings_store.dart';

class SharedPreferencesMetronomeSettingsStore
    implements MetronomeSettingsStore {
  static const _key = 'metronome_settings_v1';

  @override
  Future<MetronomeSettings?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) {
      return null;
    }
    try {
      return MetronomeSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(MetronomeSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(settings.toJson()));
  }
}
