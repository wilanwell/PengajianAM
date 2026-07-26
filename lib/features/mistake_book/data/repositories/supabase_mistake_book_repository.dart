import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/mistake_book_snapshot.dart';
import '../../domain/entities/mistake_book_topic_summary.dart';
import '../../domain/exceptions/mistake_book_failure.dart';
import '../../domain/repositories/mistake_book_repository.dart';

class SupabaseMistakeBookRepository implements MistakeBookRepository {
  const SupabaseMistakeBookRepository(this._client, this._requestExecutor);

  final SupabaseClient _client;
  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() async {
    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc('get_my_mistake_book');
        },
      );

      final responseMap = _readResponseMap(response);

      final needsReviewCount = _readInteger(
        responseMap,
        'needsReviewCount',
        minimum: 0,
      );

      final masteredCount = _readInteger(
        responseMap,
        'masteredCount',
        minimum: 0,
      );

      final rawTopics = responseMap['topics'];

      if (rawTopics is! List) {
        throw const MistakeBookFailure(
          'Senarai Buku Kesilapan daripada server tidak sah.',
        );
      }

      final topics = <MistakeBookTopicSummary>[];

      for (final rawTopic in rawTopics) {
        if (rawTopic is! Map) {
          throw const MistakeBookFailure(
            'Data topik Buku Kesilapan tidak sah.',
          );
        }

        topics.add(_readTopicSummary(Map<String, dynamic>.from(rawTopic)));
      }

      final topicIds = topics.map((topic) {
        return topic.topicId;
      }).toSet();

      if (topicIds.length != topics.length) {
        throw const MistakeBookFailure(
          'Buku Kesilapan mengandungi topik berulang.',
        );
      }

      final calculatedNeedsReviewCount = topics.fold<int>(0, (total, topic) {
        return total + topic.needsReviewCount;
      });

      final calculatedMasteredCount = topics.fold<int>(0, (total, topic) {
        return total + topic.masteredCount;
      });

      if (calculatedNeedsReviewCount != needsReviewCount ||
          calculatedMasteredCount != masteredCount) {
        throw const MistakeBookFailure(
          'Jumlah Buku Kesilapan daripada server tidak sepadan.',
        );
      }

      topics.sort((first, second) {
        final semesterComparison = first.semester.compareTo(second.semester);

        if (semesterComparison != 0) {
          return semesterComparison;
        }

        final sortOrderComparison = first.sortOrder.compareTo(second.sortOrder);

        if (sortOrderComparison != 0) {
          return sortOrderComparison;
        }

        return first.topicCode.compareTo(second.topicCode);
      });

      return MistakeBookSnapshot(
        generatedAt: _readDateTime(responseMap, 'generatedAt'),
        needsReviewCount: needsReviewCount,
        masteredCount: masteredCount,
        topics: List<MistakeBookTopicSummary>.unmodifiable(topics),
      );
    } on MistakeBookFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw MistakeBookFailure(error.message);
    } on PostgrestException catch (error) {
      throw MistakeBookFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const MistakeBookFailure(
        'Buku Kesilapan tidak dapat dimuatkan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  MistakeBookTopicSummary _readTopicSummary(Map<String, dynamic> json) {
    final needsReviewCount = _readInteger(json, 'needsReviewCount', minimum: 0);

    final masteredCount = _readInteger(json, 'masteredCount', minimum: 0);

    if (needsReviewCount + masteredCount < 1) {
      throw const MistakeBookFailure(
        'Ringkasan topik Buku Kesilapan tidak mempunyai item.',
      );
    }

    return MistakeBookTopicSummary(
      topicId: _readRequiredString(json, 'topicId'),
      topicCode: _readRequiredString(json, 'topicCode'),
      topicTitle: _readRequiredString(json, 'topicTitle'),
      semester: _readInteger(json, 'semester', minimum: 1, maximum: 3),
      sortOrder: _readInteger(json, 'sortOrder', minimum: 0),
      needsReviewCount: needsReviewCount,
      masteredCount: masteredCount,
      lastMistakeAt: _readDateTime(json, 'lastMistakeAt'),
    );
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const MistakeBookFailure(
        'Response Buku Kesilapan daripada server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw MistakeBookFailure('Data $key daripada server tidak sah.');
    }

    return value.trim();
  }

  int _readInteger(
    Map<String, dynamic> json,
    String key, {
    required int minimum,
    int? maximum,
  }) {
    final value = json[key];

    if (value is! num || value.isNaN || value.isInfinite) {
      throw MistakeBookFailure('Data $key daripada server tidak sah.');
    }

    final result = value.toInt();

    if (value != result) {
      throw MistakeBookFailure(
        'Data $key daripada server mestilah nombor bulat.',
      );
    }

    if (result < minimum || (maximum != null && result > maximum)) {
      throw MistakeBookFailure(
        'Data $key daripada server berada di luar julat.',
      );
    }

    return result;
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final rawValue = _readRequiredString(json, key);
    final parsedValue = DateTime.tryParse(rawValue);

    if (parsedValue == null) {
      throw MistakeBookFailure('Tarikh $key daripada server tidak sah.');
    }

    return parsedValue;
  }

  String _mapPostgrestMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. Sila log masuk semula.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai kebenaran untuk membuka '
          'Buku Kesilapan.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung dengan pelayan Buku Kesilapan. '
          'Semak sambungan Internet anda.';
    }

    return 'Operasi Buku Kesilapan gagal. Sila cuba semula.';
  }
}
