import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/study_topic.dart';
import '../../domain/exceptions/topics_failure.dart';
import '../../domain/repositories/topics_repository.dart';

class SupabaseTopicsRepository implements TopicsRepository {
  const SupabaseTopicsRepository(this._client, this._requestExecutor);

  final SupabaseClient _client;
  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<List<StudyTopic>> fetchTopics() async {
    try {
      final rows = await _requestExecutor.run<List<Map<String, dynamic>>>(
        request: () async {
          final response = await _client
              .from('topics')
              .select(
                'id, code, semester, title, '
                'description, question_count, '
                'sort_order',
              )
              .eq('is_active', true)
              .order('sort_order', ascending: true);

          return List<Map<String, dynamic>>.from(response);
        },
      );

      final topics = <StudyTopic>[];

      for (final row in rows) {
        topics.add(_mapTopic(row));
      }

      return List<StudyTopic>.unmodifiable(topics);
    } on TopicsFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw TopicsFailure(error.message);
    } on PostgrestException catch (error) {
      throw TopicsFailure(_mapPostgrestErrorMessage(error.message));
    } catch (_) {
      throw const TopicsFailure(
        'Tidak dapat berhubung dengan '
        'pelayan topik. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  StudyTopic _mapTopic(Map<String, dynamic> row) {
    final questionCount = _readInteger(row, 'question_count');

    return StudyTopic(
      id: _readRequiredString(row, 'id'),
      code: _readRequiredString(row, 'code'),
      semester: _readInteger(row, 'semester'),
      title: _readRequiredString(row, 'title'),
      description: _readOptionalString(row, 'description'),
      questionCount: questionCount,

      /*
       * Per-topic progress akan dibaca daripada
       * sumber progress apabila tersedia.
       */
      completedQuestionCount: 0,
    );
  }

  String _readRequiredString(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! String || value.trim().isEmpty) {
      throw TopicsFailure(
        'Data topik tidak sah pada '
        'ruangan $key.',
      );
    }

    return value.trim();
  }

  String _readOptionalString(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value == null) {
      return '';
    }

    if (value is! String) {
      throw TopicsFailure(
        'Data topik tidak sah pada '
        'ruangan $key.',
      );
    }

    return value.trim();
  }

  int _readInteger(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! num) {
      throw TopicsFailure(
        'Data topik tidak sah pada '
        'ruangan $key.',
      );
    }

    return value.toInt();
  }

  String _mapPostgrestErrorMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai kebenaran '
          'untuk membaca senarai topik.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung dengan '
          'pelayan topik. '
          'Semak sambungan Internet anda.';
    }

    return 'Topik tidak dapat dimuatkan '
        'daripada Supabase.';
  }
}
