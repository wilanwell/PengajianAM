import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_session_repository.dart';

class SharedPreferencesAuthSessionRepository implements AuthSessionRepository {
  SharedPreferencesAuthSessionRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _storageKey = 'pengajian_am_auth_session_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AuthSession?> loadSession() async {
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

      return AuthSession.fromJson(Map<String, dynamic>.from(decodedValue));
    } catch (_) {
      await _removeInvalidData();
      return null;
    }
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _preferences.setString(_storageKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clearSession() async {
    await _preferences.remove(_storageKey);
  }

  Future<void> _removeInvalidData() async {
    try {
      await _preferences.remove(_storageKey);
    } catch (_) {
      // Data sesi rosak diabaikan apabila remove gagal.
    }
  }
}
