import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_progress.dart';
import '../../domain/exceptions/user_progress_failure.dart';
import '../../domain/repositories/user_progress_repository.dart';

class SupabaseUserProgressRepository implements UserProgressRepository {
  const SupabaseUserProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProgress?> loadProgress() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const UserProgressFailure(
        'Sesi pengguna tidak tersedia. '
        'Sila log masuk semula.',
      );
    }

    try {
      final rawProfile = await _client
          .from('profiles')
          .select('id, display_name, semester_label, created_at')
          .eq('id', user.id)
          .single();

      final rawProgress = await _client
          .from('user_progress')
          .select(
            'user_id, total_xp, weekly_xp, monthly_xp, '
            'completed_quizzes, total_correct_answers, '
            'total_quiz_questions, highest_score, '
            'completed_topics, current_streak_days, '
            'best_streak_days, weekly_answered_questions',
          )
          .eq('user_id', user.id)
          .single();

      final rawTopics = await _client
          .from('topics')
          .select('id')
          .eq('is_active', true);

      final profile = Map<String, dynamic>.from(rawProfile);

      final progress = Map<String, dynamic>.from(rawProgress);

      final totalTopics = rawTopics.length;

      final storedCompletedTopics = _readInteger(progress, 'completed_topics');

      final completedTopics = storedCompletedTopics > totalTopics
          ? totalTopics
          : storedCompletedTopics;

      return UserProgress(
        userId: _readRequiredString(profile, 'id'),
        displayName: _readRequiredString(profile, 'display_name'),
        email: user.email ?? '',
        semesterLabel: _readRequiredString(profile, 'semester_label'),
        joinedAt: _readDateTime(profile, 'created_at'),
        totalXp: _readInteger(progress, 'total_xp'),
        weeklyXp: _readInteger(progress, 'weekly_xp'),
        monthlyXp: _readInteger(progress, 'monthly_xp'),
        completedQuizzes: _readInteger(progress, 'completed_quizzes'),
        totalCorrectAnswers: _readInteger(progress, 'total_correct_answers'),
        totalQuizQuestions: _readInteger(progress, 'total_quiz_questions'),
        highestScore: _readDouble(progress, 'highest_score'),
        completedTopics: completedTopics,
        totalTopics: totalTopics,
        currentStreakDays: _readInteger(progress, 'current_streak_days'),
        bestStreakDays: _readInteger(progress, 'best_streak_days'),
        weeklyAnsweredQuestions: List<int>.unmodifiable(
          _readWeeklyActivity(progress, 'weekly_answered_questions'),
        ),
      );
    } on UserProgressFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw UserProgressFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const UserProgressFailure(
        'Progress pengguna tidak dapat dimuatkan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const UserProgressFailure('Sesi pengguna tidak tersedia.');
    }

    try {
      await _client
          .from('profiles')
          .update({'display_name': progress.displayName.trim()})
          .eq('id', user.id)
          .select('display_name')
          .single();
    } on PostgrestException catch (error) {
      throw UserProgressFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const UserProgressFailure('Nama paparan tidak dapat dikemas kini.');
    }
  }

  @override
  Future<void> clearProgress() async {
    try {
      await _client.rpc('reset_my_learning_data');
    } on PostgrestException catch (error) {
      throw UserProgressFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const UserProgressFailure('Data pembelajaran tidak dapat direset.');
    }
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw UserProgressFailure('Data $key daripada server tidak sah.');
    }

    return value.trim();
  }

  int _readInteger(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! num) {
      throw UserProgressFailure('Data $key daripada server tidak sah.');
    }

    return value.toInt();
  }

  double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! num) {
      throw UserProgressFailure('Data $key daripada server tidak sah.');
    }

    return value.toDouble();
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final rawValue = _readRequiredString(json, key);

    final parsedValue = DateTime.tryParse(rawValue);

    if (parsedValue == null) {
      throw UserProgressFailure('Tarikh $key daripada server tidak sah.');
    }

    return parsedValue;
  }

  List<int> _readWeeklyActivity(Map<String, dynamic> json, String key) {
    final rawValue = json[key];

    if (rawValue is! List) {
      throw UserProgressFailure('Data aktiviti mingguan tidak sah.');
    }

    final result = List<int>.filled(7, 0);

    for (
      var index = 0;
      index < rawValue.length && index < result.length;
      index++
    ) {
      final item = rawValue[index];

      if (item is! num) {
        throw const UserProgressFailure('Data aktiviti mingguan tidak sah.');
      }

      final normalizedValue = item.toInt();

      result[index] = normalizedValue < 0 ? 0 : normalizedValue;
    }

    return result;
  }

  String _mapPostgrestMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    if (message.contains('row-level security') ||
        message.contains('permission denied')) {
      return 'Anda tidak mempunyai kebenaran '
          'untuk mengakses data ini.';
    }

    if (message.contains('multiple (or no) rows returned')) {
      return 'Profil atau progress pengguna '
          'tidak ditemui.';
    }

    return 'Operasi progress gagal. '
        'Sila cuba semula.';
  }
}
