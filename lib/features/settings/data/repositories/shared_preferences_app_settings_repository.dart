import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';

class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  SharedPreferencesAppSettingsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _storageKey = 'pengajian_am_app_settings_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSettings?> loadSettings() async {
    final storedValue = await _preferences.getString(_storageKey);

    if (storedValue == null || storedValue.trim().isEmpty) {
      return null;
    }

    try {
      final decodedValue = jsonDecode(storedValue);

      if (decodedValue is! Map) {
        await _removeInvalidData();
        return null;
      }

      return AppSettings.fromJson(Map<String, dynamic>.from(decodedValue));
    } catch (_) {
      await _removeInvalidData();
      return null;
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final encodedValue = jsonEncode(settings.toJson());

    await _preferences.setString(_storageKey, encodedValue);
  }

  @override
  Future<void> clearSettings() async {
    await _preferences.remove(_storageKey);
  }

  Future<void> _removeInvalidData() async {
    try {
      await _preferences.remove(_storageKey);
    } catch (_) {
      // Data rosak diabaikan jika proses remove gagal.
    }
  }
}
