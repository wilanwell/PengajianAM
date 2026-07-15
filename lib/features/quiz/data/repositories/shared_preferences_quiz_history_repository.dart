import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_attempt.dart';
import '../../domain/repositories/quiz_history_repository.dart';

class SharedPreferencesQuizHistoryRepository implements QuizHistoryRepository {
  SharedPreferencesQuizHistoryRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _storageKey = 'pengajian_am_quiz_history_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<QuizAttempt>> loadAttempts() async {
    final storedValue = await _preferences.getString(_storageKey);

    if (storedValue == null || storedValue.trim().isEmpty) {
      return const [];
    }

    try {
      final decodedValue = jsonDecode(storedValue);

      if (decodedValue is! List) {
        await _removeInvalidData();
        return const [];
      }

      final attempts = <QuizAttempt>[];

      for (final rawAttempt in decodedValue) {
        if (rawAttempt is! Map) {
          throw const FormatException('Invalid quiz attempt entry.');
        }

        attempts.add(
          QuizAttempt.fromJson(Map<String, dynamic>.from(rawAttempt)),
        );
      }

      attempts.sort(
        (first, second) => second.completedAt.compareTo(first.completedAt),
      );

      return List<QuizAttempt>.unmodifiable(attempts);
    } catch (_) {
      await _removeInvalidData();
      return const [];
    }
  }

  @override
  Future<void> saveAttempts(List<QuizAttempt> attempts) async {
    final encodedValue = jsonEncode([
      for (final attempt in attempts) attempt.toJson(),
    ]);

    await _preferences.setString(_storageKey, encodedValue);
  }

  @override
  Future<void> clearAttempts() async {
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
