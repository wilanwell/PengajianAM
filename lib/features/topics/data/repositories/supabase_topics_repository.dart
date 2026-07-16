import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/study_topic.dart';
import '../../domain/exceptions/topics_failure.dart';
import '../../domain/repositories/topics_repository.dart';

class SupabaseTopicsRepository implements TopicsRepository {
  const SupabaseTopicsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<StudyTopic>> fetchTopics() async {
    try {
      final rows = await _client
          .from('topics')
          .select(
            'id, code, semester, title, '
            'description, question_count, sort_order',
          )
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final topics = <StudyTopic>[];

      for (final row in rows) {
        topics.add(_mapTopic(Map<String, dynamic>.from(row)));
      }

      return List<StudyTopic>.unmodifiable(topics);
    } on PostgrestException {
      throw const TopicsFailure(
        'Topik tidak dapat dimuatkan daripada Supabase.',
      );
    } catch (_) {
      throw const TopicsFailure(
        'Tidak dapat berhubung dengan pelayan topik. '
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
      // Per-topic progress akan dipindahkan ke Supabase
      // pada milestone seterusnya.
      completedQuestionCount: 0,
    );
  }

  String _readRequiredString(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! String || value.trim().isEmpty) {
      throw TopicsFailure('Data topik tidak sah pada ruangan $key.');
    }

    return value.trim();
  }

  String _readOptionalString(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value == null) {
      return '';
    }

    if (value is! String) {
      throw TopicsFailure('Data topik tidak sah pada ruangan $key.');
    }

    return value.trim();
  }

  int _readInteger(Map<String, dynamic> row, String key) {
    final value = row[key];

    if (value is! num) {
      throw TopicsFailure('Data topik tidak sah pada ruangan $key.');
    }

    return value.toInt();
  }
}
