import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/quiz_session_question.dart';
import '../../domain/entities/quiz_session_validation.dart';
import '../../domain/entities/quiz_submission.dart';
import '../../domain/exceptions/quiz_failure.dart';
import '../../domain/repositories/quiz_repository.dart';

class SupabaseQuizRepository implements QuizRepository {
  const SupabaseQuizRepository(this._client, this._requestExecutor);

  final SupabaseClient _client;
  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc(
            'start_quiz_v2',
            params: {
              'p_topic_id': topicId,
              'p_question_count': questionCount,
              'p_mode': mode.name,
            },
          );
        },
      );

      final responseMap = _readResponseMap(
        response,
        operationName: 'start_quiz_v2',
      );

      final rawQuestions = responseMap['questions'];

      if (rawQuestions is! List) {
        throw const QuizFailure(
          'Senarai soalan daripada server '
          'tidak sah.',
        );
      }

      final questions = <QuizSessionQuestion>[];

      for (final rawQuestion in rawQuestions) {
        if (rawQuestion is! Map) {
          throw const QuizFailure(
            'Data soalan daripada server '
            'tidak sah.',
          );
        }

        questions.add(
          QuizSessionQuestion.fromJson(Map<String, dynamic>.from(rawQuestion)),
        );
      }

      final responseQuestionCount = _readInt(responseMap, 'questionCount');

      if (questions.length != responseQuestionCount) {
        throw const QuizFailure(
          'Jumlah soalan daripada server '
          'tidak lengkap.',
        );
      }

      final uniqueQuestionIds = questions
          .map((question) => question.id)
          .toSet();

      if (uniqueQuestionIds.length != questions.length) {
        throw const QuizFailure(
          'Server mengembalikan soalan '
          'yang berulang.',
        );
      }

      final responseTopicId = _readString(responseMap, 'topicId');

      if (responseTopicId != topicId) {
        throw const QuizFailure(
          'Topik kuiz daripada server '
          'tidak sepadan.',
        );
      }

      final responseMode = _readQuizMode(responseMap, 'mode');

      if (responseMode != mode) {
        throw const QuizFailure(
          'Mode kuiz daripada server '
          'tidak sepadan.',
        );
      }

      final createdAt = _readDateTime(responseMap, 'createdAt');

      final serverTime = _readDateTime(responseMap, 'serverTime');

      final expiresAt = _readDateTime(responseMap, 'expiresAt');

      final hardExpiresAt = _readDateTime(responseMap, 'hardExpiresAt');

      final examDeadlineAt = _readOptionalDateTime(
        responseMap,
        'examDeadlineAt',
      );

      if (!hardExpiresAt.isAfter(createdAt)) {
        throw const QuizFailure(
          'Tempoh sesi kuiz daripada '
          'server tidak sah.',
        );
      }

      if (responseMode == QuizMode.exam) {
        if (examDeadlineAt == null) {
          throw const QuizFailure(
            'Deadline Exam Mode tidak '
            'disediakan oleh server.',
          );
        }

        if (!expiresAt.isAtSameMomentAs(examDeadlineAt)) {
          throw const QuizFailure(
            'Deadline Exam Mode daripada '
            'server tidak sepadan.',
          );
        }

        if (examDeadlineAt.isAfter(hardExpiresAt)) {
          throw const QuizFailure(
            'Deadline Exam Mode melepasi '
            'tempoh sesi yang dibenarkan.',
          );
        }
      } else {
        if (examDeadlineAt != null) {
          throw const QuizFailure(
            'Practice Mode tidak sepatutnya '
            'mempunyai exam deadline.',
          );
        }

        if (!expiresAt.isAtSameMomentAs(hardExpiresAt)) {
          throw const QuizFailure(
            'Tempoh Practice Mode daripada '
            'server tidak sepadan.',
          );
        }
      }

      return QuizSession(
        sessionId: _readString(responseMap, 'sessionId'),
        topicId: responseTopicId,
        mode: responseMode,
        questionCount: responseQuestionCount,
        expiresAt: expiresAt,
        createdAt: createdAt,
        serverTime: serverTime,
        hardExpiresAt: hardExpiresAt,
        examDeadlineAt: examDeadlineAt,
        questions: List<QuizSessionQuestion>.unmodifiable(questions),
      );
    } on QuizFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw QuizFailure(error.message);
    } on FormatException {
      throw const QuizFailure(
        'Format kuiz daripada server '
        'tidak sah.',
      );
    } on PostgrestException catch (error) {
      throw QuizFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const QuizFailure(
        'Kuiz tidak dapat dimulakan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  @override
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) async {
    final normalizedSessionId = sessionId.trim();

    if (normalizedSessionId.isEmpty) {
      throw const QuizFailure('ID sesi kuiz tidak sah.');
    }

    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc(
            'get_my_quiz_session_status',
            params: {'p_session_id': normalizedSessionId},
          );
        },
      );

      final responseMap = _readResponseMap(
        response,
        operationName: 'get_my_quiz_session_status',
      );

      final validation = QuizSessionValidation.fromJson(responseMap);

      if (validation.sessionId != normalizedSessionId) {
        throw const QuizFailure(
          'Pengesahan sesi kuiz daripada '
          'server tidak sepadan.',
        );
      }

      return validation;
    } on QuizFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw QuizFailure(error.message);
    } on FormatException {
      throw const QuizFailure(
        'Format pengesahan sesi kuiz '
        'daripada server tidak sah.',
      );
    } on PostgrestException catch (error) {
      throw QuizFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const QuizFailure(
        'Status sesi kuiz tidak dapat '
        'disemak. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  @override
  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) async {
    final normalizedSessionId = sessionId.trim();

    if (normalizedSessionId.isEmpty) {
      throw const QuizFailure('ID sesi kuiz tidak sah.');
    }

    try {
      final answerPayload = [
        for (final entry in selectedAnswers.entries)
          {'question_id': entry.key, 'selected_option_index': entry.value},
      ];

      /*
       * elapsedTime dan autoSubmitted masih
       * berada dalam repository interface
       * untuk compatibility dengan controller
       * dan fake repositories sedia ada.
       *
       * Nilai tersebut TIDAK dihantar kepada
       * server. Server v2 mengiranya sendiri.
       */
      final response = await _requestExecutor.run<Object?>(
        timeout: const Duration(seconds: 30),
        request: () {
          return _client.rpc(
            'submit_quiz_attempt_v2',
            params: {
              'p_session_id': normalizedSessionId,
              'p_answers': answerPayload,
            },
          );
        },
      );

      final responseMap = _readResponseMap(
        response,
        operationName: 'submit_quiz_attempt_v2',
      );

      final result = QuizResult.fromJson(responseMap);

      final earnedXp = _readInt(responseMap, 'earnedXp');

      if (result.earnedXp != earnedXp) {
        throw const QuizFailure(
          'Nilai XP keputusan kuiz '
          'tidak sepadan.',
        );
      }

      return QuizSubmission(
        attemptId: _readString(responseMap, 'attemptId'),
        earnedXp: earnedXp,
        completedAt: _readDateTime(responseMap, 'completedAt'),
        result: result,
      );
    } on QuizFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw QuizFailure(error.message);
    } on FormatException {
      throw const QuizFailure(
        'Format keputusan kuiz daripada '
        'server tidak sah.',
      );
    } on PostgrestException catch (error) {
      throw QuizFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const QuizFailure(
        'Jawapan tidak dapat dihantar. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  Map<String, dynamic> _readResponseMap(
    Object? response, {
    required String operationName,
  }) {
    if (response is! Map) {
      throw QuizFailure(
        'Response $operationName '
        'daripada server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw QuizFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value.trim();
  }

  int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! num) {
      throw QuizFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value.toInt();
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final rawValue = _readString(json, key);

    final parsedValue = DateTime.tryParse(rawValue);

    if (parsedValue == null) {
      throw QuizFailure(
        'Tarikh $key daripada server '
        'tidak sah.',
      );
    }

    return parsedValue;
  }

  DateTime? _readOptionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String || value.trim().isEmpty) {
      throw QuizFailure(
        'Tarikh pilihan $key daripada '
        'server tidak sah.',
      );
    }

    final parsedValue = DateTime.tryParse(value);

    if (parsedValue == null) {
      throw QuizFailure(
        'Tarikh pilihan $key daripada '
        'server tidak sah.',
      );
    }

    return parsedValue;
  }

  QuizMode _readQuizMode(Map<String, dynamic> json, String key) {
    final value = _readString(json, key);

    for (final mode in QuizMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }

    throw const QuizFailure(
      'Mode kuiz daripada server '
      'tidak sah.',
    );
  }

  String _mapPostgrestMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    if (message.contains('not enough unique questions')) {
      return 'Topik ini belum mempunyai '
          'soalan unik yang mencukupi.';
    }

    if (message.contains('selected topic is not available')) {
      return 'Topik yang dipilih '
          'tidak tersedia.';
    }

    if (message.contains('already been submitted')) {
      return 'Kuiz ini telah dihantar '
          'sebelumnya.';
    }

    if (message.contains('exam session deadline has passed')) {
      return 'Masa Exam Mode telah tamat. '
          'Jawapan tidak dapat dihantar.';
    }

    if (message.contains(
      'exam session deadline '
      'is not configured',
    )) {
      return 'Deadline Exam Mode tidak '
          'dikonfigurasi oleh server.';
    }

    if (message.contains('session has expired')) {
      return 'Sesi kuiz telah tamat. '
          'Mulakan kuiz baharu.';
    }

    if (message.contains('session was not found')) {
      return 'Sesi kuiz tidak ditemui.';
    }

    if (message.contains('belongs to another user')) {
      return 'Sesi kuiz ini tidak sah '
          'untuk akaun semasa.';
    }

    if (message.contains('outside this session')) {
      return 'Jawapan mengandungi soalan '
          'yang bukan daripada sesi ini.';
    }

    if (message.contains('duplicate answers')) {
      return 'Terdapat jawapan berganda '
          'untuk soalan yang sama.';
    }

    if (message.contains('selected option index')) {
      return 'Salah satu pilihan jawapan '
          'tidak sah.';
    }

    if (message.contains('session_id is required')) {
      return 'ID sesi kuiz tidak sah.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung dengan '
          'pelayan kuiz. Semak sambungan '
          'Internet anda.';
    }

    return 'Operasi kuiz gagal. '
        'Sila cuba semula.';
  }
}
