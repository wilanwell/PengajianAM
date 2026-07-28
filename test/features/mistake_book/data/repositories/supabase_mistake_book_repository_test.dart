import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/exceptions/network_request_timeout_failure.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/services/network_request_executor.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/data/repositories/supabase_mistake_book_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_question_item.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/exceptions/mistake_book_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubNetworkRequestExecutor extends NetworkRequestExecutor {
  _StubNetworkRequestExecutor({this.response, this.failure});

  final Object? response;
  final Object? failure;

  int callCount = 0;

  @override
  Future<T> run<T>({
    required Future<T> Function() request,
    Duration? timeout,
  }) async {
    callCount += 1;

    final currentFailure = failure;

    if (currentFailure != null) {
      throw currentFailure;
    }

    return response as T;
  }
}

({
  SupabaseMistakeBookRepository repository,
  _StubNetworkRequestExecutor executor,
})
_createFixture({Object? response, Object? failure}) {
  final executor = _StubNetworkRequestExecutor(
    response: response,
    failure: failure,
  );

  final client = SupabaseClient('https://example.supabase.co', 'test-anon-key');

  return (
    repository: SupabaseMistakeBookRepository(client, executor),
    executor: executor,
  );
}

Map<String, Object?> _topic({
  String topicId = 'topic-1',
  String topicCode = 'S1-01',
  String topicTitle = 'Kemahiran Insaniah',
  int semester = 1,
  int sortOrder = 1,
  int needsReviewCount = 1,
  int masteredCount = 0,
  bool includeReviewableCount = false,
  Object? reviewableCount,
  Object? lastMistakeAt = '2026-07-26T07:00:00Z',
}) {
  final result = <String, Object?>{
    'topicId': topicId,
    'topicCode': topicCode,
    'topicTitle': topicTitle,
    'semester': semester,
    'sortOrder': sortOrder,
    'needsReviewCount': needsReviewCount,
    'masteredCount': masteredCount,
    'lastMistakeAt': lastMistakeAt,
  };

  if (includeReviewableCount) {
    result['reviewableCount'] = reviewableCount ?? needsReviewCount;
  }

  return result;
}

Map<String, Object?> _response({
  Object? generatedAt = '2026-07-26T08:00:00Z',
  int needsReviewCount = 1,
  int masteredCount = 0,
  bool includeReviewableCount = false,
  Object? reviewableCount,
  Object? topics,
}) {
  final result = <String, Object?>{
    'generatedAt': generatedAt,
    'needsReviewCount': needsReviewCount,
    'masteredCount': masteredCount,
    'topics': topics ?? [_topic()],
  };

  if (includeReviewableCount) {
    result['reviewableCount'] = reviewableCount ?? needsReviewCount;
  }

  return result;
}

Map<String, Object?> _detailItem({
  String questionId = 'question-1',
  Object? options = const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
  int selectedOptionIndex = 0,
  int correctOptionIndex = 1,
  String status = 'needs_review',
  bool includeIsReviewable = false,
  Object? isReviewable,
  int incorrectCount = 2,
  int reviewCount = 0,
  Object? firstIncorrectAt = '2026-07-26T07:00:00Z',
  Object? lastIncorrectAt = '2026-07-27T07:00:00Z',
  Object? lastReviewedAt,
  Object? masteredAt,
}) {
  final result = <String, Object?>{
    'questionId': questionId,
    'questionText': 'Apakah jawapan yang betul?',
    'options': options,
    'selectedOptionIndex': selectedOptionIndex,
    'correctOptionIndex': correctOptionIndex,
    'explanation': 'Pilihan B ialah jawapan yang betul.',
    'status': status,
    'incorrectCount': incorrectCount,
    'reviewCount': reviewCount,
    'firstIncorrectAt': firstIncorrectAt,
    'lastIncorrectAt': lastIncorrectAt,
    'lastReviewedAt': lastReviewedAt,
    'masteredAt': masteredAt,
  };

  if (includeIsReviewable) {
    result['isReviewable'] = isReviewable ?? (status == 'needs_review');
  }

  return result;
}

Map<String, Object?> _detailResponse({
  String topicId = 'topic-1',
  int needsReviewCount = 1,
  int masteredCount = 0,
  bool includeReviewableCount = false,
  Object? reviewableCount,
  Object? items,
}) {
  final topic = <String, Object?>{
    'topicId': topicId,
    'topicCode': 'S1-01',
    'topicTitle': 'Kemahiran Insaniah',
    'semester': 1,
    'sortOrder': 1,
    'needsReviewCount': needsReviewCount,
    'masteredCount': masteredCount,
  };

  if (includeReviewableCount) {
    topic['reviewableCount'] = reviewableCount ?? needsReviewCount;
  }

  return {
    'generatedAt': '2026-07-27T08:00:00Z',
    'topic': topic,
    'items': items ?? [_detailItem()],
  };
}

Matcher _isFailureWithMessage(String message) {
  return throwsA(
    isA<MistakeBookFailure>().having(
      (failure) => failure.message,
      'message',
      message,
    ),
  );
}

void main() {
  group('SupabaseMistakeBookRepository', () {
    test(
      'memetakan response baharu dan menyusun topik dengan stabil',
      () async {
        final fixture = _createFixture(
          response: _response(
            needsReviewCount: 3,
            masteredCount: 1,
            includeReviewableCount: true,
            reviewableCount: 2,
            topics: [
              _topic(
                topicId: 'topic-4',
                topicCode: 'S2-01',
                topicTitle: 'Topik Semester 2',
                semester: 2,
                sortOrder: 1,
                needsReviewCount: 1,
                includeReviewableCount: true,
                reviewableCount: 1,
              ),
              _topic(
                topicId: 'topic-3',
                topicCode: 'S1-03',
                topicTitle: 'Topik Ketiga',
                sortOrder: 2,
                needsReviewCount: 0,
                masteredCount: 1,
                includeReviewableCount: true,
                reviewableCount: 0,
              ),
              _topic(
                topicId: 'topic-2',
                topicCode: 'S1-02',
                topicTitle: 'Topik Kedua',
                sortOrder: 1,
                needsReviewCount: 1,
                includeReviewableCount: true,
                reviewableCount: 0,
              ),
              _topic(
                topicId: 'topic-1',
                topicCode: 'S1-01',
                topicTitle: 'Topik Pertama',
                sortOrder: 1,
                needsReviewCount: 1,
                includeReviewableCount: true,
                reviewableCount: 1,
              ),
            ],
          ),
        );

        final snapshot = await fixture.repository.fetchMistakeBook();

        expect(fixture.executor.callCount, 1);

        expect(snapshot.generatedAt, DateTime.utc(2026, 7, 26, 8));

        expect(snapshot.needsReviewCount, 3);

        expect(snapshot.reviewableCount, 2);

        expect(snapshot.archivedNeedsReviewCount, 1);

        expect(snapshot.masteredCount, 1);

        expect(snapshot.totalTrackedCount, 4);

        expect(snapshot.hasItemsToReview, isTrue);

        expect(snapshot.topics.map((topic) => topic.topicCode), [
          'S1-01',
          'S1-02',
          'S1-03',
          'S2-01',
        ]);

        final archivedTopic = snapshot.topics.firstWhere(
          (topic) => topic.topicId == 'topic-2',
        );

        expect(archivedTopic.needsReviewCount, 1);

        expect(archivedTopic.reviewableCount, 0);

        expect(archivedTopic.archivedNeedsReviewCount, 1);

        expect(archivedTopic.hasItemsToReview, isFalse);

        expect(() => snapshot.topics.clear(), throwsUnsupportedError);
      },
    );

    test('menyokong response lama tanpa reviewableCount', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 2,
          masteredCount: 0,
          topics: [
            _topic(topicId: 'topic-1', needsReviewCount: 1),
            _topic(topicId: 'topic-2', topicCode: 'S1-02', needsReviewCount: 1),
          ],
        ),
      );

      final snapshot = await fixture.repository.fetchMistakeBook();

      expect(snapshot.needsReviewCount, 2);

      expect(snapshot.reviewableCount, 2);

      expect(snapshot.archivedNeedsReviewCount, 0);

      expect(snapshot.topics.first.reviewableCount, 1);
    });

    test('menerima response kosong yang sah', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 0,
          masteredCount: 0,
          includeReviewableCount: true,
          reviewableCount: 0,
          topics: const [],
        ),
      );

      final snapshot = await fixture.repository.fetchMistakeBook();

      expect(snapshot.isEmpty, isTrue);

      expect(snapshot.hasItemsToReview, isFalse);

      expect(snapshot.topics, isEmpty);
    });

    test('menolak response utama yang bukan object JSON', () async {
      final fixture = _createFixture(response: const []);

      await expectLater(
        fixture.repository.fetchMistakeBook(),
        _isFailureWithMessage(
          'Response Buku Kesilapan daripada server tidak sah.',
        ),
      );
    });

    test('menolak senarai atau item topik yang tidak sah', () async {
      final invalidResponses = <Map<String, Object?>>[
        _response(topics: 'bukan-senarai'),
        _response(topics: const ['bukan-object']),
      ];

      for (final invalidResponse in invalidResponses) {
        final fixture = _createFixture(response: invalidResponse);

        await expectLater(
          fixture.repository.fetchMistakeBook(),
          throwsA(isA<MistakeBookFailure>()),
        );
      }
    });

    test('menolak topicId yang berulang', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 2,
          topics: [
            _topic(topicCode: 'S1-01'),
            _topic(topicCode: 'S1-02'),
          ],
        ),
      );

      await expectLater(
        fixture.repository.fetchMistakeBook(),
        _isFailureWithMessage('Buku Kesilapan mengandungi topik berulang.'),
      );
    });

    test(
      'menolak jumlah keseluruhan yang tidak sepadan dengan topik',
      () async {
        final fixture = _createFixture(
          response: _response(
            needsReviewCount: 5,
            topics: [_topic(needsReviewCount: 1)],
          ),
        );

        await expectLater(
          fixture.repository.fetchMistakeBook(),
          _isFailureWithMessage(
            'Jumlah Buku Kesilapan daripada server tidak sepadan.',
          ),
        );
      },
    );

    test('menolak reviewableCount keseluruhan yang tidak sepadan', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 2,
          masteredCount: 0,
          includeReviewableCount: true,
          reviewableCount: 2,
          topics: [
            _topic(
              topicId: 'topic-1',
              needsReviewCount: 1,
              includeReviewableCount: true,
              reviewableCount: 1,
            ),
            _topic(
              topicId: 'topic-2',
              topicCode: 'S1-02',
              needsReviewCount: 1,
              includeReviewableCount: true,
              reviewableCount: 0,
            ),
          ],
        ),
      );

      await expectLater(
        fixture.repository.fetchMistakeBook(),
        _isFailureWithMessage(
          'Jumlah Buku Kesilapan daripada server tidak sepadan.',
        ),
      );
    });

    test(
      'menolak reviewableCount topik yang melebihi needsReviewCount',
      () async {
        final fixture = _createFixture(
          response: _response(
            needsReviewCount: 1,
            includeReviewableCount: true,
            reviewableCount: 1,
            topics: [
              _topic(
                needsReviewCount: 1,
                includeReviewableCount: true,
                reviewableCount: 2,
              ),
            ],
          ),
        );

        await expectLater(
          fixture.repository.fetchMistakeBook(),
          throwsA(isA<MistakeBookFailure>()),
        );
      },
    );

    test('menolak ringkasan topik tanpa sebarang item', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 0,
          topics: [_topic(needsReviewCount: 0, masteredCount: 0)],
        ),
      );

      await expectLater(
        fixture.repository.fetchMistakeBook(),
        _isFailureWithMessage(
          'Ringkasan topik Buku Kesilapan tidak mempunyai item.',
        ),
      );
    });

    test('menolak nilai medan topik dan tarikh yang tidak sah', () async {
      final invalidResponses = <Map<String, Object?>>[
        _response(topics: [_topic(topicId: '   ')]),
        _response(topics: [_topic(semester: 4)]),
        _response(topics: [_topic(lastMistakeAt: 'tarikh-tidak-sah')]),
        _response(generatedAt: 'tarikh-tidak-sah'),
      ];

      for (final invalidResponse in invalidResponses) {
        final fixture = _createFixture(response: invalidResponse);

        await expectLater(
          fixture.repository.fetchMistakeBook(),
          throwsA(isA<MistakeBookFailure>()),
        );
      }
    });

    test(
      'memetakan butiran aktif diarkibkan dan dikuasai dengan tepat',
      () async {
        final fixture = _createFixture(
          response: _detailResponse(
            needsReviewCount: 2,
            masteredCount: 1,
            includeReviewableCount: true,
            reviewableCount: 1,
            items: [
              _detailItem(
                questionId: 'question-active',
                includeIsReviewable: true,
                isReviewable: true,
              ),
              _detailItem(
                questionId: 'question-archived',
                selectedOptionIndex: 2,
                correctOptionIndex: 3,
                includeIsReviewable: true,
                isReviewable: false,
              ),
              _detailItem(
                questionId: 'question-mastered',
                selectedOptionIndex: 2,
                correctOptionIndex: 3,
                status: 'mastered',
                includeIsReviewable: true,
                isReviewable: false,
                incorrectCount: 1,
                reviewCount: 1,
                lastReviewedAt: '2026-07-27T07:30:00Z',
                masteredAt: '2026-07-27T07:30:00Z',
              ),
            ],
          ),
        );

        final detail = await fixture.repository.fetchMistakeBookTopic(
          ' topic-1 ',
        );

        expect(fixture.executor.callCount, 1);

        expect(detail.topicId, 'topic-1');

        expect(detail.topicCode, 'S1-01');

        expect(detail.totalTrackedCount, 3);

        expect(detail.needsReviewCount, 2);

        expect(detail.reviewableCount, 1);

        expect(detail.archivedNeedsReviewCount, 1);

        expect(detail.masteredCount, 1);

        expect(detail.masteryProgress, closeTo(1 / 3, 0.0001));

        expect(detail.hasReviewableItems, isTrue);

        expect(detail.items, hasLength(3));

        final activeItem = detail.items.firstWhere(
          (item) => item.questionId == 'question-active',
        );

        expect(activeItem.status, MistakeBookQuestionStatus.needsReview);

        expect(activeItem.isReviewable, isTrue);

        expect(activeItem.isArchived, isFalse);

        expect(activeItem.selectedAnswerText, 'Pilihan A');

        expect(activeItem.correctAnswerText, 'Pilihan B');

        final archivedItem = detail.items.firstWhere(
          (item) => item.questionId == 'question-archived',
        );

        expect(archivedItem.needsReview, isTrue);

        expect(archivedItem.isReviewable, isFalse);

        expect(archivedItem.isArchived, isTrue);

        final masteredItem = detail.items.firstWhere(
          (item) => item.questionId == 'question-mastered',
        );

        expect(masteredItem.isMastered, isTrue);

        expect(masteredItem.isReviewable, isFalse);

        expect(masteredItem.isArchived, isFalse);

        expect(() => detail.items.clear(), throwsUnsupportedError);
      },
    );

    test('menyokong response detail lama tanpa isReviewable', () async {
      final fixture = _createFixture(
        response: _detailResponse(
          needsReviewCount: 1,
          masteredCount: 1,
          items: [
            _detailItem(questionId: 'question-needs-review'),
            _detailItem(
              questionId: 'question-mastered',
              selectedOptionIndex: 2,
              correctOptionIndex: 3,
              status: 'mastered',
              incorrectCount: 1,
              reviewCount: 1,
              lastReviewedAt: '2026-07-27T07:30:00Z',
              masteredAt: '2026-07-27T07:30:00Z',
            ),
          ],
        ),
      );

      final detail = await fixture.repository.fetchMistakeBookTopic('topic-1');

      expect(detail.reviewableCount, 1);

      expect(detail.items.first.isReviewable, isTrue);

      expect(detail.items.last.isReviewable, isFalse);
    });

    test('menolak topicId kosong sebelum membuat request', () async {
      final fixture = _createFixture(response: _detailResponse());

      await expectLater(
        fixture.repository.fetchMistakeBookTopic('   '),
        _isFailureWithMessage('Topik Buku Kesilapan tidak sah.'),
      );

      expect(fixture.executor.callCount, 0);
    });

    test('menolak jumlah reviewable detail yang tidak sepadan', () async {
      final fixture = _createFixture(
        response: _detailResponse(
          needsReviewCount: 2,
          masteredCount: 0,
          includeReviewableCount: true,
          reviewableCount: 2,
          items: [
            _detailItem(
              questionId: 'question-active',
              includeIsReviewable: true,
              isReviewable: true,
            ),
            _detailItem(
              questionId: 'question-archived',
              selectedOptionIndex: 2,
              correctOptionIndex: 3,
              includeIsReviewable: true,
              isReviewable: false,
            ),
          ],
        ),
      );

      await expectLater(
        fixture.repository.fetchMistakeBookTopic('topic-1'),
        _isFailureWithMessage(
          'Jumlah soalan Buku Kesilapan daripada server tidak sepadan.',
        ),
      );
    });

    test('menolak isReviewable yang bukan boolean', () async {
      final fixture = _createFixture(
        response: _detailResponse(
          includeReviewableCount: true,
          reviewableCount: 1,
          items: [_detailItem(includeIsReviewable: true, isReviewable: 'ya')],
        ),
      );

      await expectLater(
        fixture.repository.fetchMistakeBookTopic('topic-1'),
        _isFailureWithMessage('Status ketersediaan latihan semula tidak sah.'),
      );
    });

    test('menolak soalan mastered yang ditandakan boleh dilatih', () async {
      final fixture = _createFixture(
        response: _detailResponse(
          needsReviewCount: 0,
          masteredCount: 1,
          includeReviewableCount: true,
          reviewableCount: 0,
          items: [
            _detailItem(
              status: 'mastered',
              includeIsReviewable: true,
              isReviewable: true,
              incorrectCount: 1,
              reviewCount: 1,
              lastReviewedAt: '2026-07-27T07:30:00Z',
              masteredAt: '2026-07-27T07:30:00Z',
            ),
          ],
        ),
      );

      await expectLater(
        fixture.repository.fetchMistakeBookTopic('topic-1'),
        _isFailureWithMessage(
          'Soalan yang dikuasai tidak boleh ditandakan untuk latihan semula.',
        ),
      );
    });

    test('menolak response detail yang tidak konsisten', () async {
      final invalidResponses = <Map<String, Object?>>[
        _detailResponse(topicId: 'topic-lain'),
        _detailResponse(needsReviewCount: 2),
        _detailResponse(
          items: [_detailItem(), _detailItem()],
          needsReviewCount: 2,
        ),
        _detailResponse(
          items: [
            _detailItem(options: const ['Satu']),
          ],
        ),
        _detailResponse(
          items: [_detailItem(selectedOptionIndex: 1, correctOptionIndex: 1)],
        ),
        _detailResponse(items: [_detailItem(status: 'status-tidak-sah')]),
        _detailResponse(
          items: [_detailItem(lastIncorrectAt: '2026-07-25T07:00:00Z')],
        ),
      ];

      for (final invalidResponse in invalidResponses) {
        final fixture = _createFixture(response: invalidResponse);

        await expectLater(
          fixture.repository.fetchMistakeBookTopic('topic-1'),
          throwsA(isA<MistakeBookFailure>()),
        );
      }
    });

    test('memetakan ralat topik detail kepada mesej yang sesuai', () async {
      final cases = <(String, String)>[
        ('topic_id is required.', 'Topik Buku Kesilapan tidak sah.'),
        (
          'Mistake Book topic was not found.',
          'Topik Buku Kesilapan tidak ditemui.',
        ),
      ];

      for (final testCase in cases) {
        final fixture = _createFixture(
          failure: PostgrestException(message: testCase.$1),
        );

        await expectLater(
          fixture.repository.fetchMistakeBookTopic('topic-1'),
          _isFailureWithMessage(testCase.$2),
        );
      }
    });

    test('menukar timeout rangkaian kepada MistakeBookFailure', () async {
      const timeout = Duration(seconds: 1);

      final fixture = _createFixture(
        failure: const NetworkRequestTimeoutFailure(timeout: timeout),
      );

      await expectLater(
        fixture.repository.fetchMistakeBook(),
        _isFailureWithMessage(
          'Permintaan mengambil masa terlalu lama. '
          'Semak sambungan Internet dan cuba semula.',
        ),
      );
    });

    test('memetakan PostgrestException kepada mesej yang sesuai', () async {
      final cases = <(String, String)>[
        (
          'Authentication required',
          'Sesi anda telah tamat. '
              'Sila log masuk semula.',
        ),
        (
          'permission denied for table mistake_book_items',
          'Anda tidak mempunyai kebenaran untuk membuka '
              'Buku Kesilapan.',
        ),
        (
          'network connection refused',
          'Tidak dapat berhubung dengan pelayan Buku Kesilapan. '
              'Semak sambungan Internet anda.',
        ),
        (
          'unexpected database error',
          'Operasi Buku Kesilapan gagal. '
              'Sila cuba semula.',
        ),
      ];

      for (final testCase in cases) {
        final fixture = _createFixture(
          failure: PostgrestException(message: testCase.$1),
        );

        await expectLater(
          fixture.repository.fetchMistakeBook(),
          _isFailureWithMessage(testCase.$2),
        );
      }
    });

    test('menukar ralat tidak dijangka kepada mesej sambungan umum', () async {
      final fixture = _createFixture(failure: StateError('ralat ujian'));

      await expectLater(
        fixture.repository.fetchMistakeBook(),
        _isFailureWithMessage(
          'Buku Kesilapan tidak dapat dimuatkan. '
          'Semak sambungan Internet anda.',
        ),
      );
    });
  });
}
