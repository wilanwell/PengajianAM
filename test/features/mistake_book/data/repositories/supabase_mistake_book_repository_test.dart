import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/exceptions/network_request_timeout_failure.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/services/network_request_executor.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/data/repositories/supabase_mistake_book_repository.dart';
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
  Object? lastMistakeAt = '2026-07-26T07:00:00Z',
}) {
  return {
    'topicId': topicId,
    'topicCode': topicCode,
    'topicTitle': topicTitle,
    'semester': semester,
    'sortOrder': sortOrder,
    'needsReviewCount': needsReviewCount,
    'masteredCount': masteredCount,
    'lastMistakeAt': lastMistakeAt,
  };
}

Map<String, Object?> _response({
  Object? generatedAt = '2026-07-26T08:00:00Z',
  int needsReviewCount = 1,
  int masteredCount = 0,
  Object? topics,
}) {
  return {
    'generatedAt': generatedAt,
    'needsReviewCount': needsReviewCount,
    'masteredCount': masteredCount,
    'topics': topics ?? [_topic()],
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
    test('memetakan response sah dan menyusun topik dengan stabil', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 3,
          masteredCount: 1,
          topics: [
            _topic(
              topicId: 'topic-4',
              topicCode: 'S2-01',
              topicTitle: 'Topik Semester 2',
              semester: 2,
              sortOrder: 1,
              needsReviewCount: 1,
            ),
            _topic(
              topicId: 'topic-3',
              topicCode: 'S1-03',
              topicTitle: 'Topik Ketiga',
              sortOrder: 2,
              needsReviewCount: 0,
              masteredCount: 1,
            ),
            _topic(
              topicId: 'topic-2',
              topicCode: 'S1-02',
              topicTitle: 'Topik Kedua',
              sortOrder: 1,
              needsReviewCount: 1,
            ),
            _topic(
              topicId: 'topic-1',
              topicCode: 'S1-01',
              topicTitle: 'Topik Pertama',
              sortOrder: 1,
              needsReviewCount: 1,
            ),
          ],
        ),
      );

      final snapshot = await fixture.repository.fetchMistakeBook();

      expect(fixture.executor.callCount, 1);
      expect(snapshot.generatedAt, DateTime.utc(2026, 7, 26, 8));
      expect(snapshot.needsReviewCount, 3);
      expect(snapshot.masteredCount, 1);
      expect(snapshot.totalTrackedCount, 4);

      expect(snapshot.topics.map((topic) => topic.topicCode), [
        'S1-01',
        'S1-02',
        'S1-03',
        'S2-01',
      ]);

      expect(() => snapshot.topics.clear(), throwsUnsupportedError);
    });

    test('menerima response kosong yang sah', () async {
      final fixture = _createFixture(
        response: _response(
          needsReviewCount: 0,
          masteredCount: 0,
          topics: const [],
        ),
      );

      final snapshot = await fixture.repository.fetchMistakeBook();

      expect(snapshot.isEmpty, isTrue);
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
          'Sesi anda telah tamat. Sila log masuk semula.',
        ),
        (
          'permission denied for table mistake_book_items',
          'Anda tidak mempunyai kebenaran untuk membuka Buku Kesilapan.',
        ),
        (
          'network connection refused',
          'Tidak dapat berhubung dengan pelayan Buku Kesilapan. '
              'Semak sambungan Internet anda.',
        ),
        (
          'unexpected database error',
          'Operasi Buku Kesilapan gagal. Sila cuba semula.',
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
