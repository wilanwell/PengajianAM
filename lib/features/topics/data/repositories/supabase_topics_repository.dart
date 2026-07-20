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
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc('get_my_topics_with_progress');
        },
      );

      final responseMap = _readResponseMap(response);

      final rawTopics = responseMap['topics'];

      if (rawTopics is! List) {
        throw const TopicsFailure(
          'Senarai topik daripada server '
          'tidak sah.',
        );
      }

      final topics = <StudyTopic>[];
      final topicIds = <String>{};

      for (final rawTopic in rawTopics) {
        if (rawTopic is! Map) {
          throw const TopicsFailure(
            'Data topik daripada server '
            'tidak sah.',
          );
        }

        final topic = _mapTopic(Map<String, dynamic>.from(rawTopic));

        if (!topicIds.add(topic.id)) {
          throw const TopicsFailure(
            'Server mengembalikan topik '
            'yang berulang.',
          );
        }

        topics.add(topic);
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
        'Topik dan progress tidak dapat '
        'dimuatkan. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  StudyTopic _mapTopic(Map<String, dynamic> json) {
    final questionCount = _readInteger(json, 'questionCount', minimum: 0);

    final completedQuestionCount = _readInteger(
      json,
      'completedQuestionCount',
      minimum: 0,
    );

    if (completedQuestionCount > questionCount) {
      throw const TopicsFailure(
        'Progress topik daripada server '
        'melebihi jumlah soalan topik.',
      );
    }

    return StudyTopic(
      id: _readRequiredString(json, 'id'),
      code: _readRequiredString(json, 'code'),
      semester: _readInteger(json, 'semester', minimum: 1),
      title: _readRequiredString(json, 'title'),
      description: _readOptionalString(json, 'description'),
      questionCount: questionCount,
      completedQuestionCount: completedQuestionCount,
      lastAttemptAt: _readOptionalDateTime(json, 'lastAttemptAt'),
    );
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const TopicsFailure(
        'Response topik daripada server '
        'tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw TopicsFailure(
        'Data topik tidak sah pada '
        'ruangan $key.',
      );
    }

    return value.trim();
  }

  String _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];

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

  int _readInteger(
    Map<String, dynamic> json,
    String key, {
    required int minimum,
  }) {
    final value = json[key];

    if (value is! num) {
      throw TopicsFailure(
        'Data topik tidak sah pada '
        'ruangan $key.',
      );
    }

    final result = value.toInt();

    if (result < minimum) {
      throw TopicsFailure(
        'Data topik pada ruangan $key '
        'berada di luar julat.',
      );
    }

    return result;
  }

  DateTime? _readOptionalDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw TopicsFailure(
        'Tarikh topik pada ruangan $key '
        'tidak sah.',
      );
    }

    final parsedValue = DateTime.tryParse(value);

    if (parsedValue == null) {
      throw TopicsFailure(
        'Tarikh topik pada ruangan $key '
        'tidak sah.',
      );
    }

    return parsedValue;
  }

  String _mapPostgrestErrorMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai '
          'kebenaran untuk membaca '
          'senarai topik.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung '
          'dengan pelayan topik. '
          'Semak sambungan Internet anda.';
    }

    return 'Topik dan progress tidak dapat '
        'dimuatkan daripada Supabase.';
  }
}
