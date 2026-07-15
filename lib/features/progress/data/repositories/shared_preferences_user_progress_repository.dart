import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/user_progress_repository.dart';

class SharedPreferencesUserProgressRepository
    implements UserProgressRepository {
  SharedPreferencesUserProgressRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _storageKey = 'pengajian_am_user_progress_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<UserProgress?> loadProgress() async {
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

      return UserProgress.fromJson(Map<String, dynamic>.from(decodedValue));
    } catch (_) {
      await _removeInvalidData();
      return null;
    }
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    final encodedValue = jsonEncode(progress.toJson());

    await _preferences.setString(_storageKey, encodedValue);
  }

  @override
  Future<void> clearProgress() async {
    await _preferences.remove(_storageKey);
  }

  Future<void> _removeInvalidData() async {
    try {
      await _preferences.remove(_storageKey);
    } catch (_) {
      // Data rosak akan diabaikan jika proses remove gagal.
    }
  }
}
