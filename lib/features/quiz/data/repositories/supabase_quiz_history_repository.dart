import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/quiz_attempt.dart';
import '../../domain/entities/quiz_history_snapshot.dart';
import '../../domain/exceptions/quiz_history_failure.dart';
import '../../domain/repositories/quiz_history_repository.dart';

class SupabaseQuizHistoryRepository implements QuizHistoryRepository {
  const SupabaseQuizHistoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<QuizHistorySnapshot> fetchHistory({int limit = 30}) async {
    if (limit < 1 || limit > 100) {
      throw const QuizHistoryFailure('Had sejarah mestilah antara 1 dan 100.');
    }

    try {
      final response = await _client.rpc(
        'get_my_quiz_history',
        params: {'p_limit': limit},
      );

      final responseMap = _readResponseMap(response);

      final rawAttempts = responseMap['attempts'];

      if (rawAttempts is! List) {
        throw const QuizHistoryFailure(
          'Senarai sejarah daripada server tidak sah.',
        );
      }

      final attempts = <QuizAttempt>[];

      for (final rawAttempt in rawAttempts) {
        if (rawAttempt is! Map) {
          throw const QuizHistoryFailure('Data percubaan kuiz tidak sah.');
        }

        attempts.add(
          QuizAttempt.fromJson(Map<String, dynamic>.from(rawAttempt)),
        );
      }

      final attemptIds = attempts.map((attempt) => attempt.id).toSet();

      if (attemptIds.length != attempts.length) {
        throw const QuizHistoryFailure(
          'Sejarah mengandungi percubaan berulang.',
        );
      }

      attempts.sort((first, second) {
        return second.completedAt.compareTo(first.completedAt);
      });

      final totalCount = _readInteger(responseMap, 'totalCount', minimum: 0);

      if (totalCount < attempts.length) {
        throw const QuizHistoryFailure(
          'Jumlah rekod sejarah daripada server tidak sah.',
        );
      }

      return QuizHistorySnapshot(
        generatedAt: _readDateTime(responseMap, 'generatedAt'),
        totalCount: totalCount,
        attempts: List<QuizAttempt>.unmodifiable(attempts),
      );
    } on QuizHistoryFailure {
      rethrow;
    } on FormatException {
      throw const QuizHistoryFailure(
        'Format sejarah kuiz daripada server tidak sah.',
      );
    } on PostgrestException catch (error) {
      throw QuizHistoryFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const QuizHistoryFailure(
        'Sejarah kuiz tidak dapat dimuatkan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  @override
  Future<void> deleteAttempt(String attemptId) async {
    final normalizedId = attemptId.trim();

    if (normalizedId.isEmpty) {
      throw const QuizHistoryFailure('ID percubaan kuiz tidak sah.');
    }

    try {
      final response = await _client.rpc(
        'delete_my_quiz_attempt',
        params: {'p_attempt_id': normalizedId},
      );

      final responseMap = _readResponseMap(response);

      final deletedAttemptId = _readRequiredString(
        responseMap,
        'deletedAttemptId',
      );

      if (deletedAttemptId != normalizedId) {
        throw const QuizHistoryFailure(
          'Pengesahan pemadaman sejarah tidak sah.',
        );
      }
    } on QuizHistoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw QuizHistoryFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const QuizHistoryFailure('Rekod kuiz tidak dapat dipadamkan.');
    }
  }

  @override
  Future<int> clearHistory() async {
    try {
      final response = await _client.rpc('clear_my_quiz_history');

      final responseMap = _readResponseMap(response);

      return _readInteger(responseMap, 'deletedCount', minimum: 0);
    } on QuizHistoryFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw QuizHistoryFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const QuizHistoryFailure(
        'Semua sejarah kuiz tidak dapat dipadamkan.',
      );
    }
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const QuizHistoryFailure(
        'Response sejarah kuiz daripada server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw QuizHistoryFailure('Data $key daripada server tidak sah.');
    }

    return value.trim();
  }

  int _readInteger(
    Map<String, dynamic> json,
    String key, {
    required int minimum,
  }) {
    final value = json[key];

    if (value is! num) {
      throw QuizHistoryFailure('Data $key daripada server tidak sah.');
    }

    final result = value.toInt();

    if (result < minimum) {
      throw QuizHistoryFailure(
        'Data $key daripada server berada '
        'di luar julat yang dibenarkan.',
      );
    }

    return result;
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final rawValue = _readRequiredString(json, key);

    final parsedValue = DateTime.tryParse(rawValue);

    if (parsedValue == null) {
      throw QuizHistoryFailure('Tarikh $key daripada server tidak sah.');
    }

    return parsedValue;
  }

  String _mapPostgrestMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    if (message.contains('quiz attempt was not found')) {
      return 'Rekod kuiz tidak ditemui.';
    }

    if (message.contains('attempt_id is required')) {
      return 'ID percubaan kuiz tidak sah.';
    }

    if (message.contains('limit must be')) {
      return 'Had sejarah kuiz tidak sah.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai kebenaran '
          'untuk mengakses sejarah ini.';
    }

    return 'Operasi sejarah kuiz gagal. '
        'Sila cuba semula.';
  }
}
