import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_draft.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../../domain/repositories/quiz_draft_repository.dart';

class SharedPreferencesQuizDraftRepository implements QuizDraftRepository {
  const SharedPreferencesQuizDraftRepository();

  static const String _keyPrefix = 'quiz_draft_v1_';

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    final normalizedUserId = _normalizeUserId(ownerUserId);

    try {
      final preferences = await SharedPreferences.getInstance();

      final key = _buildKey(normalizedUserId);

      final rawValue = preferences.getString(key);

      if (rawValue == null || rawValue.trim().isEmpty) {
        return null;
      }

      try {
        final decodedValue = jsonDecode(rawValue);

        if (decodedValue is! Map) {
          await preferences.remove(key);
          return null;
        }

        return QuizDraft.fromJson(Map<String, dynamic>.from(decodedValue));
      } on FormatException {
        await preferences.remove(key);
        return null;
      }
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure('Draft kuiz tidak dapat dimuatkan.');
    }
  }

  @override
  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    final normalizedUserId = _normalizeUserId(ownerUserId);

    try {
      final preferences = await SharedPreferences.getInstance();

      final encodedValue = jsonEncode(draft.toJson());

      final saved = await preferences.setString(
        _buildKey(normalizedUserId),
        encodedValue,
      );

      if (!saved) {
        throw const QuizDraftFailure('Draft kuiz tidak dapat disimpan.');
      }
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure('Draft kuiz tidak dapat disimpan.');
    }
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    final normalizedUserId = _normalizeUserId(ownerUserId);

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.remove(_buildKey(normalizedUserId));
    } catch (_) {
      throw const QuizDraftFailure('Draft kuiz tidak dapat dipadamkan.');
    }
  }

  String _normalizeUserId(String ownerUserId) {
    final normalizedValue = ownerUserId.trim();

    if (normalizedValue.isEmpty) {
      throw const QuizDraftFailure(
        'ID pengguna untuk draft kuiz '
        'tidak sah.',
      );
    }

    return normalizedValue;
  }

  String _buildKey(String ownerUserId) {
    return '$_keyPrefix$ownerUserId';
  }
}
