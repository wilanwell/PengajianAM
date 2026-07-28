import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_detail.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_summary.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/exceptions/mistake_book_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/repositories/mistake_book_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_state.dart';

class _FakeMistakeBookRepository implements MistakeBookRepository {
  _FakeMistakeBookRepository({required this.snapshot, this.failure});

  final MistakeBookSnapshot snapshot;

  final MistakeBookFailure? failure;

  int fetchCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() async {
    fetchCallCount++;

    final currentFailure = failure;

    if (currentFailure != null) {
      throw currentFailure;
    }

    return snapshot;
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    throw UnimplementedError();
  }
}

class _CompleterMistakeBookRepository implements MistakeBookRepository {
  final Completer<MistakeBookSnapshot> completer =
      Completer<MistakeBookSnapshot>();

  int fetchCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() {
    fetchCallCount++;

    return completer.future;
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    throw UnimplementedError();
  }
}

class _SequenceMistakeBookRepository implements MistakeBookRepository {
  _SequenceMistakeBookRepository({required List<Object> responses})
    : _responses = List<Object>.from(responses);

  final List<Object> _responses;

  int fetchCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() async {
    fetchCallCount++;

    if (_responses.isEmpty) {
      throw StateError('Tiada response ujian tersedia.');
    }

    final response = _responses.removeAt(0);

    if (response is MistakeBookSnapshot) {
      return response;
    }

    if (response is MistakeBookFailure) {
      throw response;
    }

    throw StateError('Jenis response ujian tidak sah.');
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    throw UnimplementedError();
  }
}

void main() {
  test('memuatkan menyimpan cache dan menyegarkan Buku Kesilapan', () async {
    final repository = _FakeMistakeBookRepository(snapshot: _sampleSnapshot());

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(mistakeBookControllerProvider.notifier);

    await controller.loadMistakeBook();

    var state = container.read(mistakeBookControllerProvider);

    expect(state.status, MistakeBookStatus.success);

    expect(state.snapshot?.needsReviewCount, 39);

    expect(state.snapshot?.reviewableCount, 39);

    expect(state.snapshot?.masteredCount, 0);

    expect(state.snapshot?.topics, hasLength(3));

    expect(repository.fetchCallCount, 1);

    await controller.loadMistakeBook();

    expect(repository.fetchCallCount, 1);

    await controller.refreshMistakeBook();

    state = container.read(mistakeBookControllerProvider);

    expect(state.status, MistakeBookStatus.success);

    expect(repository.fetchCallCount, 2);
  });

  test(
    'menggabungkan permintaan serentak kepada satu repository call',
    () async {
      final repository = _CompleterMistakeBookRepository();

      final container = ProviderContainer(
        overrides: [
          mistakeBookRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final controller = container.read(mistakeBookControllerProvider.notifier);

      final firstRequest = controller.loadMistakeBook();

      final secondRequest = controller.loadMistakeBook();

      expect(identical(firstRequest, secondRequest), isTrue);

      expect(repository.fetchCallCount, 1);

      repository.completer.complete(_sampleSnapshot());

      await Future.wait([firstRequest, secondRequest]);

      expect(
        container.read(mistakeBookControllerProvider).status,
        MistakeBookStatus.success,
      );
    },
  );

  test('memetakan MistakeBookFailure kepada failure state', () async {
    final repository = _FakeMistakeBookRepository(
      snapshot: _sampleSnapshot(),
      failure: const MistakeBookFailure('Buku Kesilapan tidak dapat dicapai.'),
    );

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    await container
        .read(mistakeBookControllerProvider.notifier)
        .loadMistakeBook();

    final state = container.read(mistakeBookControllerProvider);

    expect(state.status, MistakeBookStatus.failure);

    expect(state.snapshot, isNull);

    expect(state.errorMessage, 'Buku Kesilapan tidak dapat dicapai.');
  });

  test('mengekalkan snapshot lama apabila refresh gagal', () async {
    final snapshot = _sampleSnapshot();

    final repository = _SequenceMistakeBookRepository(
      responses: [
        snapshot,
        const MistakeBookFailure('Sambungan Internet terputus.'),
      ],
    );

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(mistakeBookControllerProvider.notifier);

    await controller.loadMistakeBook();

    var state = container.read(mistakeBookControllerProvider);

    expect(state.status, MistakeBookStatus.success);

    expect(state.snapshot, same(snapshot));

    await controller.refreshMistakeBook();

    state = container.read(mistakeBookControllerProvider);

    expect(state.status, MistakeBookStatus.failure);

    expect(state.snapshot, same(snapshot));

    expect(state.errorMessage, 'Sambungan Internet terputus.');

    expect(repository.fetchCallCount, 2);
  });

  test('reset membuang snapshot dan state sedia ada', () async {
    final repository = _FakeMistakeBookRepository(snapshot: _sampleSnapshot());

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(mistakeBookControllerProvider.notifier);

    await controller.loadMistakeBook();

    controller.reset();

    final state = container.read(mistakeBookControllerProvider);

    expect(state.status, MistakeBookStatus.initial);

    expect(state.snapshot, isNull);

    expect(state.errorMessage, isNull);
  });
}

MistakeBookSnapshot _sampleSnapshot() {
  return MistakeBookSnapshot(
    generatedAt: DateTime.utc(2026, 7, 26, 14),
    needsReviewCount: 39,
    reviewableCount: 39,
    masteredCount: 0,
    topics: [
      MistakeBookTopicSummary(
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Kemahiran Insaniah',
        semester: 1,
        sortOrder: 1,
        needsReviewCount: 15,
        reviewableCount: 15,
        masteredCount: 0,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 13),
      ),
      MistakeBookTopicSummary(
        topicId: 'topic-2',
        topicCode: 'S1-03',
        topicTitle: 'Perlembagaan Persekutuan',
        semester: 1,
        sortOrder: 3,
        needsReviewCount: 14,
        reviewableCount: 14,
        masteredCount: 0,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 12),
      ),
      MistakeBookTopicSummary(
        topicId: 'topic-3',
        topicCode: 'S1-04',
        topicTitle: 'Sistem dan Struktur Pemerintahan',
        semester: 1,
        sortOrder: 4,
        needsReviewCount: 10,
        reviewableCount: 10,
        masteredCount: 0,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 11),
      ),
    ],
  );
}
