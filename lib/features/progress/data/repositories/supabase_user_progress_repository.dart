import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/exceptions/user_progress_failure.dart';
import '../../domain/repositories/user_progress_repository.dart';

class SupabaseUserProgressRepository implements UserProgressRepository {
  const SupabaseUserProgressRepository(this._client, this._requestExecutor);

  final SupabaseClient _client;

  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<UserProgress?> loadProgress() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const UserProgressFailure(
        'Sesi pengguna tidak tersedia. '
        'Sila log masuk semula.',
      );
    }

    final requestedUserId = user.id;

    try {
      /*
       * Profil pengguna menyimpan maklumat
       * identiti dan semester.
       */
      final profile = await _requestExecutor.run<Map<String, dynamic>>(
        request: () async {
          final response = await _client
              .from('profiles')
              .select(
                'id, display_name, '
                'semester_label, created_at',
              )
              .eq('id', requestedUserId)
              .single();

          return Map<String, dynamic>.from(response);
        },
      );

      /*
       * user_progress masih digunakan untuk
       * statistik sepanjang hayat.
       *
       * weekly_xp dan monthly_xp tidak lagi
       * dibaca kerana kedua-duanya ialah
       * counter lama yang tidak mengikut
       * sempadan minggu dan bulan sebenar.
       */
      final progress = await _requestExecutor.run<Map<String, dynamic>>(
        request: () async {
          final response = await _client
              .from('user_progress')
              .select(
                'user_id, total_xp, '
                'completed_quizzes, '
                'total_correct_answers, '
                'total_quiz_questions, '
                'highest_score, '
                'completed_topics, '
                'current_streak_days, '
                'best_streak_days, '
                'weekly_answered_questions',
              )
              .eq('user_id', requestedUserId)
              .single();

          return Map<String, dynamic>.from(response);
        },
      );

      /*
       * Dapatkan jumlah topik aktif untuk
       * memastikan completedTopics tidak
       * melebihi jumlah topik sebenar.
       */
      final activeTopics = await _requestExecutor
          .run<List<Map<String, dynamic>>>(
            request: () async {
              final response = await _client
                  .from('topics')
                  .select('id')
                  .eq('is_active', true);

              return List<Map<String, dynamic>>.from(response);
            },
          );

      /*
       * Weekly dan monthly XP kini dikira
       * secara server-side berdasarkan:
       *
       * - quiz_attempts.earned_xp;
       * - quiz_attempts.completed_at;
       * - timezone Asia/Kuala_Lumpur.
       */
      final periodXpResponse = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc('get_my_period_xp');
        },
      );

      final periodXp = _readPeriodXpSnapshot(periodXpResponse);

      /*
       * Pastikan akaun tidak bertukar ketika
       * request masih berjalan.
       *
       * Ini menghalang data akaun lama daripada
       * ditulis kepada controller akaun baharu.
       */
      _ensureSameAuthenticatedUser(requestedUserId);

      final totalTopics = activeTopics.length;

      final storedCompletedTopics = _readInteger(progress, 'completed_topics');

      final completedTopics = storedCompletedTopics > totalTopics
          ? totalTopics
          : storedCompletedTopics;

      return UserProgress(
        userId: _readRequiredString(profile, 'id'),
        displayName: _readRequiredString(profile, 'display_name'),
        email: _client.auth.currentUser?.email ?? user.email ?? '',
        semesterLabel: _readRequiredString(profile, 'semester_label'),
        joinedAt: _readDateTime(profile, 'created_at'),
        totalXp: _readInteger(progress, 'total_xp'),

        /*
         * Gunakan nilai tempoh sebenar daripada
         * get_my_period_xp(), bukan counter lama
         * dalam public.user_progress.
         */
        weeklyXp: periodXp.weeklyXp,
        monthlyXp: periodXp.monthlyXp,

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
    } on NetworkRequestTimeoutFailure catch (error) {
      throw UserProgressFailure(error.message);
    } on PostgrestException catch (error) {
      throw UserProgressFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const UserProgressFailure(
        'Progress pengguna tidak dapat '
        'dimuatkan. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const UserProgressFailure('Sesi pengguna tidak tersedia.');
    }

    final normalizedDisplayName = progress.displayName.trim();

    if (normalizedDisplayName.length < 2 || normalizedDisplayName.length > 30) {
      throw const UserProgressFailure(
        'Nama paparan mestilah antara '
        '2 hingga 30 aksara.',
      );
    }

    try {
      await _requestExecutor.run<Map<String, dynamic>>(
        request: () async {
          final response = await _client
              .from('profiles')
              .update({'display_name': normalizedDisplayName})
              .eq('id', user.id)
              .select('display_name')
              .single();

          return Map<String, dynamic>.from(response);
        },
      );
    } on UserProgressFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw UserProgressFailure(error.message);
    } on PostgrestException catch (error) {
      throw UserProgressFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const UserProgressFailure(
        'Nama paparan tidak dapat '
        'dikemas kini. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  @override
  Future<void> clearProgress() async {
    try {
      await _requestExecutor.run<Object?>(
        timeout: const Duration(seconds: 30),
        request: () {
          return _client.rpc('reset_my_learning_data');
        },
      );
    } on NetworkRequestTimeoutFailure catch (error) {
      throw UserProgressFailure(error.message);
    } on PostgrestException catch (error) {
      throw UserProgressFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const UserProgressFailure(
        'Data pembelajaran tidak dapat '
        'direset. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  void _ensureSameAuthenticatedUser(String requestedUserId) {
    final currentUserId = _client.auth.currentUser?.id;

    if (currentUserId == null) {
      throw const UserProgressFailure(
        'Sesi pengguna telah tamat. '
        'Sila log masuk semula.',
      );
    }

    if (currentUserId != requestedUserId) {
      throw const UserProgressFailure(
        'Akaun pengguna telah berubah ketika '
        'progress sedang dimuatkan. '
        'Sila cuba semula.',
      );
    }
  }

  _PeriodXpSnapshot _readPeriodXpSnapshot(Object? response) {
    final responseMap = _readResponseMap(response);

    final weeklyXp = _readInteger(responseMap, 'weeklyXp');

    final monthlyXp = _readInteger(responseMap, 'monthlyXp');

    final weekStartsAt = _readDateTime(responseMap, 'weekStartsAt');

    final weekEndsAt = _readDateTime(responseMap, 'weekEndsAt');

    final monthStartsAt = _readDateTime(responseMap, 'monthStartsAt');

    final monthEndsAt = _readDateTime(responseMap, 'monthEndsAt');

    final timezone = _readRequiredString(responseMap, 'timezone');

    /*
     * Server time turut dibaca untuk
     * memastikan response RPC lengkap dan sah.
     */
    _readDateTime(responseMap, 'serverTime');

    if (timezone != 'Asia/Kuala_Lumpur') {
      throw const UserProgressFailure(
        'Timezone XP tempoh daripada '
        'server tidak sah.',
      );
    }

    if (!weekEndsAt.isAfter(weekStartsAt)) {
      throw const UserProgressFailure(
        'Julat XP mingguan daripada '
        'server tidak sah.',
      );
    }

    if (!monthEndsAt.isAfter(monthStartsAt)) {
      throw const UserProgressFailure(
        'Julat XP bulanan daripada '
        'server tidak sah.',
      );
    }

    return _PeriodXpSnapshot(weeklyXp: weeklyXp, monthlyXp: monthlyXp);
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const UserProgressFailure(
        'Response XP tempoh daripada '
        'server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw UserProgressFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value.trim();
  }

  int _readInteger(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! num) {
      throw UserProgressFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    final result = value.toInt();

    if (result < 0) {
      throw UserProgressFailure(
        'Data $key daripada server '
        'berada di luar julat.',
      );
    }

    return result;
  }

  double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! num) {
      throw UserProgressFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    final result = value.toDouble();

    if (result < 0 || result > 100) {
      throw UserProgressFailure(
        'Data $key daripada server '
        'berada di luar julat.',
      );
    }

    return result;
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final rawValue = _readRequiredString(json, key);

    final parsedValue = DateTime.tryParse(rawValue);

    if (parsedValue == null) {
      throw UserProgressFailure(
        'Tarikh $key daripada server '
        'tidak sah.',
      );
    }

    return parsedValue;
  }

  List<int> _readWeeklyActivity(Map<String, dynamic> json, String key) {
    final rawValue = json[key];

    if (rawValue is! List) {
      throw const UserProgressFailure(
        'Data aktiviti mingguan '
        'tidak sah.',
      );
    }

    final result = List<int>.filled(7, 0);

    for (
      var index = 0;
      index < rawValue.length && index < result.length;
      index++
    ) {
      final item = rawValue[index];

      if (item is! num) {
        throw const UserProgressFailure(
          'Data aktiviti mingguan '
          'tidak sah.',
        );
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
      return 'Anda tidak mempunyai '
          'kebenaran untuk mengakses '
          'data ini.';
    }

    if (message.contains('multiple (or no) rows returned') ||
        message.contains(
          'json object requested, '
          'multiple (or no) rows returned',
        )) {
      return 'Profil atau progress '
          'pengguna tidak ditemui.';
    }

    if (message.contains('could not find the function') ||
        message.contains('get_my_period_xp')) {
      return 'Fungsi XP mingguan dan '
          'bulanan belum tersedia pada '
          'server.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung '
          'dengan pelayan progress. '
          'Semak sambungan Internet anda.';
    }

    return 'Operasi progress gagal. '
        'Sila cuba semula.';
  }
}

class _PeriodXpSnapshot {
  const _PeriodXpSnapshot({required this.weeklyXp, required this.monthlyXp});

  final int weeklyXp;

  final int monthlyXp;
}
