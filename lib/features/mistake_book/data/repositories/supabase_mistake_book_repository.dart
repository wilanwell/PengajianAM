import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/mistake_book_question_item.dart';
import '../../domain/entities/mistake_book_snapshot.dart';
import '../../domain/entities/mistake_book_topic_detail.dart';
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

      final reviewableCount = responseMap.containsKey('reviewableCount')
          ? _readInteger(
              responseMap,
              'reviewableCount',
              minimum: 0,
              maximum: needsReviewCount,
            )
          : needsReviewCount;

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

      final calculatedReviewableCount = topics.fold<int>(0, (total, topic) {
        return total + topic.reviewableCount;
      });

      if (calculatedNeedsReviewCount != needsReviewCount ||
          calculatedMasteredCount != masteredCount ||
          calculatedReviewableCount != reviewableCount) {
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
        reviewableCount: reviewableCount,
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

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) async {
    final normalizedTopicId = topicId.trim();

    if (normalizedTopicId.isEmpty) {
      throw const MistakeBookFailure('Topik Buku Kesilapan tidak sah.');
    }

    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc(
            'get_my_mistake_book_topic',
            params: {'p_topic_id': normalizedTopicId},
          );
        },
      );

      final responseMap = _readResponseMap(response);

      final rawTopic = responseMap['topic'];
      final rawItems = responseMap['items'];

      if (rawTopic is! Map) {
        throw const MistakeBookFailure(
          'Data topik Buku Kesilapan daripada server tidak sah.',
        );
      }

      if (rawItems is! List) {
        throw const MistakeBookFailure(
          'Senarai soalan Buku Kesilapan daripada server tidak sah.',
        );
      }

      final topicMap = Map<String, dynamic>.from(rawTopic);

      final needsReviewCount = _readInteger(
        topicMap,
        'needsReviewCount',
        minimum: 0,
      );

      final masteredCount = _readInteger(topicMap, 'masteredCount', minimum: 0);

      final reviewableCount = topicMap.containsKey('reviewableCount')
          ? _readInteger(
              topicMap,
              'reviewableCount',
              minimum: 0,
              maximum: needsReviewCount,
            )
          : needsReviewCount;

      final items = <MistakeBookQuestionItem>[];

      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          throw const MistakeBookFailure(
            'Data soalan Buku Kesilapan tidak sah.',
          );
        }

        items.add(_readQuestionItem(Map<String, dynamic>.from(rawItem)));
      }

      final questionIds = items.map((item) {
        return item.questionId;
      }).toSet();

      if (questionIds.length != items.length) {
        throw const MistakeBookFailure(
          'Butiran topik mengandungi soalan berulang.',
        );
      }

      final calculatedNeedsReviewCount = items.where((item) {
        return item.needsReview;
      }).length;

      final calculatedMasteredCount = items.where((item) {
        return item.isMastered;
      }).length;

      final calculatedReviewableCount = items.where((item) {
        return item.isReviewable;
      }).length;

      if (calculatedNeedsReviewCount != needsReviewCount ||
          calculatedMasteredCount != masteredCount ||
          calculatedReviewableCount != reviewableCount ||
          items.length != needsReviewCount + masteredCount) {
        throw const MistakeBookFailure(
          'Jumlah soalan Buku Kesilapan daripada server tidak sepadan.',
        );
      }

      final responseTopicId = _readRequiredString(topicMap, 'topicId');

      if (responseTopicId != normalizedTopicId) {
        throw const MistakeBookFailure(
          'Topik Buku Kesilapan daripada server tidak sepadan.',
        );
      }

      return MistakeBookTopicDetail(
        generatedAt: _readDateTime(responseMap, 'generatedAt'),
        topicId: responseTopicId,
        topicCode: _readRequiredString(topicMap, 'topicCode'),
        topicTitle: _readRequiredString(topicMap, 'topicTitle'),
        semester: _readInteger(topicMap, 'semester', minimum: 1, maximum: 3),
        sortOrder: _readInteger(topicMap, 'sortOrder', minimum: 0),
        needsReviewCount: needsReviewCount,
        reviewableCount: reviewableCount,
        masteredCount: masteredCount,
        items: List<MistakeBookQuestionItem>.unmodifiable(items),
      );
    } on MistakeBookFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw MistakeBookFailure(error.message);
    } on PostgrestException catch (error) {
      throw MistakeBookFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const MistakeBookFailure(
        'Butiran topik Buku Kesilapan tidak dapat dimuatkan. '
        'Semak sambungan Internet anda.',
      );
    }
  }

  MistakeBookTopicSummary _readTopicSummary(Map<String, dynamic> json) {
    final needsReviewCount = _readInteger(json, 'needsReviewCount', minimum: 0);

    final masteredCount = _readInteger(json, 'masteredCount', minimum: 0);

    final reviewableCount = json.containsKey('reviewableCount')
        ? _readInteger(
            json,
            'reviewableCount',
            minimum: 0,
            maximum: needsReviewCount,
          )
        : needsReviewCount;

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
      reviewableCount: reviewableCount,
      masteredCount: masteredCount,
      lastMistakeAt: _readDateTime(json, 'lastMistakeAt'),
    );
  }

  MistakeBookQuestionItem _readQuestionItem(Map<String, dynamic> json) {
    final options = _readOptions(json);

    final selectedOptionIndex = _readInteger(
      json,
      'selectedOptionIndex',
      minimum: 0,
      maximum: options.length - 1,
    );

    final correctOptionIndex = _readInteger(
      json,
      'correctOptionIndex',
      minimum: 0,
      maximum: options.length - 1,
    );

    if (selectedOptionIndex == correctOptionIndex) {
      throw const MistakeBookFailure(
        'Jawapan salah dan jawapan betul daripada server tidak sah.',
      );
    }

    final status = switch (_readRequiredString(json, 'status')) {
      'needs_review' => MistakeBookQuestionStatus.needsReview,
      'mastered' => MistakeBookQuestionStatus.mastered,
      _ => throw const MistakeBookFailure(
        'Status soalan Buku Kesilapan tidak sah.',
      ),
    };

    final rawIsReviewable = json['isReviewable'];

    final isReviewable = rawIsReviewable == null
        ? status == MistakeBookQuestionStatus.needsReview
        : rawIsReviewable is bool
        ? rawIsReviewable
        : throw const MistakeBookFailure(
            'Status ketersediaan latihan semula tidak sah.',
          );

    if (isReviewable && status != MistakeBookQuestionStatus.needsReview) {
      throw const MistakeBookFailure(
        'Soalan yang dikuasai tidak boleh ditandakan untuk latihan semula.',
      );
    }

    final incorrectCount = _readInteger(json, 'incorrectCount', minimum: 1);

    final reviewCount = _readInteger(json, 'reviewCount', minimum: 0);

    final firstIncorrectAt = _readDateTime(json, 'firstIncorrectAt');

    final lastIncorrectAt = _readDateTime(json, 'lastIncorrectAt');

    final lastReviewedAt = _readNullableDateTime(json, 'lastReviewedAt');

    final masteredAt = _readNullableDateTime(json, 'masteredAt');

    if (lastIncorrectAt.isBefore(firstIncorrectAt)) {
      throw const MistakeBookFailure(
        'Garis masa kesilapan daripada server tidak sah.',
      );
    }

    if ((reviewCount == 0 && lastReviewedAt != null) ||
        (reviewCount > 0 && lastReviewedAt == null)) {
      throw const MistakeBookFailure(
        'Garis masa semakan daripada server tidak sah.',
      );
    }

    if (lastReviewedAt != null && lastReviewedAt.isBefore(firstIncorrectAt)) {
      throw const MistakeBookFailure(
        'Tarikh semakan daripada server tidak sah.',
      );
    }

    if ((status == MistakeBookQuestionStatus.needsReview &&
            masteredAt != null) ||
        (status == MistakeBookQuestionStatus.mastered &&
            (masteredAt == null || reviewCount == 0))) {
      throw const MistakeBookFailure(
        'Status penguasaan daripada server tidak sah.',
      );
    }

    return MistakeBookQuestionItem(
      questionId: _readRequiredString(json, 'questionId'),
      questionText: _readRequiredString(json, 'questionText'),
      options: options,
      selectedOptionIndex: selectedOptionIndex,
      correctOptionIndex: correctOptionIndex,
      explanation: _readRequiredString(json, 'explanation'),
      status: status,
      isReviewable: isReviewable,
      incorrectCount: incorrectCount,
      reviewCount: reviewCount,
      firstIncorrectAt: firstIncorrectAt,
      lastIncorrectAt: lastIncorrectAt,
      lastReviewedAt: lastReviewedAt,
      masteredAt: masteredAt,
    );
  }

  List<String> _readOptions(Map<String, dynamic> json) {
    final rawOptions = json['options'];

    if (rawOptions is! List || rawOptions.length < 2) {
      throw const MistakeBookFailure(
        'Pilihan jawapan Buku Kesilapan tidak sah.',
      );
    }

    final options = <String>[];

    for (final rawOption in rawOptions) {
      if (rawOption is! String || rawOption.trim().isEmpty) {
        throw const MistakeBookFailure(
          'Pilihan jawapan Buku Kesilapan tidak sah.',
        );
      }

      options.add(rawOption.trim());
    }

    return List<String>.unmodifiable(options);
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

  DateTime? _readNullableDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String || value.trim().isEmpty) {
      throw MistakeBookFailure('Tarikh $key daripada server tidak sah.');
    }

    final parsedValue = DateTime.tryParse(value);

    if (parsedValue == null) {
      throw MistakeBookFailure('Tarikh $key daripada server tidak sah.');
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
      return 'Anda tidak mempunyai kebenaran untuk membuka '
          'Buku Kesilapan.';
    }

    if (message.contains('topic_id is required')) {
      return 'Topik Buku Kesilapan tidak sah.';
    }

    if (message.contains('mistake book topic was not found')) {
      return 'Topik Buku Kesilapan tidak ditemui.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung dengan pelayan Buku Kesilapan. '
          'Semak sambungan Internet anda.';
    }

    return 'Operasi Buku Kesilapan gagal. '
        'Sila cuba semula.';
  }
}
