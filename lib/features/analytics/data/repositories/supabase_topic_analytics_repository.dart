import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/topic_analytics_snapshot.dart';
import '../../domain/entities/topic_performance.dart';
import '../../domain/exceptions/topic_analytics_failure.dart';
import '../../domain/repositories/topic_analytics_repository.dart';

class SupabaseTopicAnalyticsRepository implements TopicAnalyticsRepository {
  const SupabaseTopicAnalyticsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TopicAnalyticsSnapshot> fetchAnalytics() async {
    try {
      final response = await _client.rpc('get_my_topic_analytics');

      final responseMap = _readResponseMap(response);

      final rawPerformances = responseMap['performances'];

      if (rawPerformances is! List) {
        throw const TopicAnalyticsFailure(
          'Senarai analitik daripada server tidak sah.',
        );
      }

      final performances = <TopicPerformance>[];

      for (final rawPerformance in rawPerformances) {
        if (rawPerformance is! Map) {
          throw const TopicAnalyticsFailure('Data analitik topik tidak sah.');
        }

        performances.add(
          _readPerformance(Map<String, dynamic>.from(rawPerformance)),
        );
      }

      final topicIds = performances.map((performance) {
        return performance.topicId;
      }).toSet();

      if (topicIds.length != performances.length) {
        throw const TopicAnalyticsFailure(
          'Analitik mengandungi topik berulang.',
        );
      }

      performances.sort((first, second) {
        final scoreComparison = second.averageScore.compareTo(
          first.averageScore,
        );

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final attemptComparison = second.attemptCount.compareTo(
          first.attemptCount,
        );

        if (attemptComparison != 0) {
          return attemptComparison;
        }

        return first.topicTitle.compareTo(second.topicTitle);
      });

      return TopicAnalyticsSnapshot(
        generatedAt: _readDateTime(responseMap, 'generatedAt'),
        performances: List<TopicPerformance>.unmodifiable(performances),
      );
    } on TopicAnalyticsFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw TopicAnalyticsFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const TopicAnalyticsFailure(
        'Analitik prestasi tidak dapat dimuatkan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  TopicPerformance _readPerformance(Map<String, dynamic> json) {
    final attemptCount = _readInteger(json, 'attemptCount', minimum: 0);

    final totalQuestions = _readInteger(json, 'totalQuestions', minimum: 0);

    final totalCorrectAnswers = _readInteger(
      json,
      'totalCorrectAnswers',
      minimum: 0,
    );

    if (totalCorrectAnswers > totalQuestions) {
      throw const TopicAnalyticsFailure(
        'Jumlah jawapan betul melebihi '
        'jumlah soalan.',
      );
    }

    final bestScore = _readDouble(json, 'bestScore', minimum: 0, maximum: 100);

    return TopicPerformance(
      topicId: _readRequiredString(json, 'topicId'),
      topicCode: _readOptionalString(json, 'topicCode'),
      topicTitle: _readRequiredString(json, 'topicTitle'),
      attemptCount: attemptCount,
      totalQuestions: totalQuestions,
      totalCorrectAnswers: totalCorrectAnswers,
      bestScore: bestScore,
      totalEarnedXp: _readInteger(json, 'totalEarnedXp', minimum: 0),
    );
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const TopicAnalyticsFailure(
        'Response analitik daripada server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw TopicAnalyticsFailure('Data $key daripada server tidak sah.');
    }

    return value.trim();
  }

  String _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return '';
    }

    if (value is! String) {
      throw TopicAnalyticsFailure('Data $key daripada server tidak sah.');
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
      throw TopicAnalyticsFailure('Data $key daripada server tidak sah.');
    }

    final result = value.toInt();

    if (result < minimum) {
      throw TopicAnalyticsFailure(
        'Data $key daripada server berada '
        'di luar julat yang dibenarkan.',
      );
    }

    return result;
  }

  double _readDouble(
    Map<String, dynamic> json,
    String key, {
    required double minimum,
    required double maximum,
  }) {
    final value = json[key];

    if (value is! num) {
      throw TopicAnalyticsFailure('Data $key daripada server tidak sah.');
    }

    final result = value.toDouble();

    if (result < minimum || result > maximum) {
      throw TopicAnalyticsFailure(
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
      throw TopicAnalyticsFailure('Tarikh $key daripada server tidak sah.');
    }

    return parsedValue;
  }

  String _mapPostgrestMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai kebenaran '
          'untuk membuka analitik.';
    }

    return 'Operasi analitik gagal. '
        'Sila cuba semula.';
  }
}
