import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_question_item.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_detail.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/exceptions/mistake_book_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/repositories/mistake_book_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_topic_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_topic_state.dart';

class _FakeMistakeBookRepository implements MistakeBookRepository {
  _FakeMistakeBookRepository({required this.detail, this.failure});

  final MistakeBookTopicDetail detail;

  final MistakeBookFailure? failure;

  int detailCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() {
    throw UnimplementedError();
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) async {
    detailCallCount++;

    final currentFailure = failure;

    if (currentFailure != null) {
      throw currentFailure;
    }

    return detail;
  }
}

class _CompleterMistakeBookRepository implements MistakeBookRepository {
  final Completer<MistakeBookTopicDetail> completer =
      Completer<MistakeBookTopicDetail>();

  int detailCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() {
    throw UnimplementedError();
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    detailCallCount++;

    return completer.future;
  }
}

void main() {
  test('memuatkan, menyimpan cache dan menyegarkan detail topik', () async {
    final repository = _FakeMistakeBookRepository(detail: _sampleDetail());

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      mistakeBookTopicControllerProvider.notifier,
    );

    await controller.loadTopic('topic-1');

    var state = container.read(mistakeBookTopicControllerProvider);

    expect(state.status, MistakeBookTopicStatus.success);
    expect(state.topicId, 'topic-1');
    expect(state.detail?.topicTitle, 'Kemahiran Insaniah');
    expect(repository.detailCallCount, 1);

    await controller.loadTopic('topic-1');

    expect(repository.detailCallCount, 1);

    await controller.refreshTopic('topic-1');

    state = container.read(mistakeBookTopicControllerProvider);

    expect(state.status, MistakeBookTopicStatus.success);
    expect(repository.detailCallCount, 2);
  });

  test('menggabungkan permintaan topik serentak', () async {
    final repository = _CompleterMistakeBookRepository();

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      mistakeBookTopicControllerProvider.notifier,
    );

    final firstRequest = controller.loadTopic('topic-1');
    final secondRequest = controller.loadTopic('topic-1');

    expect(identical(firstRequest, secondRequest), isTrue);
    expect(repository.detailCallCount, 1);

    repository.completer.complete(_sampleDetail());

    await Future.wait([firstRequest, secondRequest]);

    expect(
      container.read(mistakeBookTopicControllerProvider).status,
      MistakeBookTopicStatus.success,
    );
  });

  test('memetakan kegagalan repository dan topicId kosong', () async {
    final repository = _FakeMistakeBookRepository(
      detail: _sampleDetail(),
      failure: const MistakeBookFailure('Topik Buku Kesilapan tidak ditemui.'),
    );

    final container = ProviderContainer(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      mistakeBookTopicControllerProvider.notifier,
    );

    await controller.loadTopic('topic-tiada');

    var state = container.read(mistakeBookTopicControllerProvider);

    expect(state.status, MistakeBookTopicStatus.failure);
    expect(state.errorMessage, 'Topik Buku Kesilapan tidak ditemui.');

    await controller.loadTopic('   ');

    state = container.read(mistakeBookTopicControllerProvider);

    expect(state.status, MistakeBookTopicStatus.failure);
    expect(state.topicId, '');
    expect(state.errorMessage, 'Topik Buku Kesilapan tidak sah.');
    expect(repository.detailCallCount, 1);
  });
}

MistakeBookTopicDetail _sampleDetail() {
  return MistakeBookTopicDetail(
    generatedAt: DateTime.utc(2026, 7, 27, 8),
    topicId: 'topic-1',
    topicCode: 'S1-01',
    topicTitle: 'Kemahiran Insaniah',
    semester: 1,
    sortOrder: 1,
    needsReviewCount: 1,
    masteredCount: 0,
    items: [
      MistakeBookQuestionItem(
        questionId: 'question-1',
        questionText: 'Apakah jawapan yang betul?',
        options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
        selectedOptionIndex: 0,
        correctOptionIndex: 1,
        explanation: 'Pilihan B ialah jawapan yang betul.',
        status: MistakeBookQuestionStatus.needsReview,
        incorrectCount: 2,
        reviewCount: 0,
        firstIncorrectAt: DateTime.utc(2026, 7, 26, 8),
        lastIncorrectAt: DateTime.utc(2026, 7, 27, 8),
        lastReviewedAt: null,
        masteredAt: null,
      ),
    ],
  );
}
