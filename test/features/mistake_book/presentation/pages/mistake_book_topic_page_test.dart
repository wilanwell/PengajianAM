import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_question_item.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_detail.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/exceptions/mistake_book_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/repositories/mistake_book_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/pages/mistake_book_topic_page.dart';

class _FakeMistakeBookRepository implements MistakeBookRepository {
  _FakeMistakeBookRepository({
    required this.detail,
    this.failFirstRequest = false,
  });

  final MistakeBookTopicDetail detail;

  final bool failFirstRequest;

  int detailCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() {
    throw UnimplementedError();
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) async {
    detailCallCount++;

    if (failFirstRequest && detailCallCount == 1) {
      throw const MistakeBookFailure(
        'Topik Buku Kesilapan tidak dapat dicapai.',
      );
    }

    return detail;
  }
}

void main() {
  testWidgets('memaparkan soalan jawapan dan penerangan topik', (tester) async {
    final repository = _FakeMistakeBookRepository(detail: _sampleDetail());

    await _pumpPage(tester, repository: repository);

    expect(find.text('Soalan Kesilapan'), findsOneWidget);

    expect(find.text('Kemahiran Insaniah'), findsOneWidget);

    expect(
      find.text('2 soalan direkodkan dalam Buku Kesilapan.'),
      findsOneWidget,
    );

    expect(find.text('Latih Semula Semua (1)'), findsOneWidget);

    expect(find.text('Perlu Dijawab Semula'), findsWidgets);

    final firstQuestion = find.byKey(
      const Key('mistake-book-question-question-1'),
    );

    final pageScrollable = _verticalPageScrollable();

    expect(pageScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      firstQuestion,
      300,
      scrollable: pageScrollable,
    );

    await tester.pumpAndSettle();

    expect(firstQuestion, findsOneWidget);

    expect(find.text('Jawapan Anda (ketika salah)'), findsWidgets);

    expect(find.text('Jawapan Betul'), findsWidgets);

    expect(find.text('Pilihan A'), findsWidgets);

    expect(find.text('Pilihan B'), findsWidgets);

    expect(find.text('Pilihan B ialah jawapan yang betul.'), findsWidgets);

    expect(find.text('Muncul dalam latihan 0 kali'), findsOneWidget);

    expect(repository.detailCallCount, 1);
  });

  testWidgets('memaparkan mesej apabila semua kesilapan dikuasai', (
    tester,
  ) async {
    final repository = _FakeMistakeBookRepository(detail: _allMasteredDetail());

    await _pumpPage(tester, repository: repository);

    expect(find.byKey(const Key('mistake-book-all-mastered')), findsOneWidget);

    expect(find.text('Semua kesilapan telah dikuasai.'), findsOneWidget);

    expect(find.byKey(const Key('mistake-book-start-review')), findsNothing);
  });

  testWidgets('penapis memaparkan status soalan yang dipilih', (tester) async {
    final repository = _FakeMistakeBookRepository(detail: _sampleDetail());

    await _pumpPage(tester, repository: repository);

    final pageScrollable = _verticalPageScrollable();

    final masteredFilter = find.byKey(
      const Key('mistake-book-topic-filter-mastered'),
    );

    expect(pageScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      masteredFilter,
      300,
      scrollable: pageScrollable,
    );

    await tester.pumpAndSettle();

    await tester.tap(masteredFilter);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mistake-book-question-question-1')),
      findsNothing,
    );

    expect(find.text('1 soalan'), findsOneWidget);

    final masteredQuestion = find.byKey(
      const Key('mistake-book-question-question-2'),
    );

    await tester.scrollUntilVisible(
      masteredQuestion,
      300,
      scrollable: pageScrollable,
    );

    await tester.pumpAndSettle();

    expect(masteredQuestion, findsOneWidget);
  });

  testWidgets('memaparkan soalan diarkibkan dalam penapis berasingan', (
    tester,
  ) async {
    final repository = _FakeMistakeBookRepository(
      detail: _detailWithArchivedItem(),
    );

    await _pumpPage(tester, repository: repository);

    expect(find.text('Latih Semula Semua (1)'), findsOneWidget);

    expect(find.text('Diarkibkan'), findsWidgets);

    final archivedFilter = find.byKey(
      const Key('mistake-book-topic-filter-archived'),
    );

    final pageScrollable = _verticalPageScrollable();

    await tester.scrollUntilVisible(
      archivedFilter,
      300,
      scrollable: pageScrollable,
    );

    await tester.pumpAndSettle();

    await tester.tap(archivedFilter);

    await tester.pumpAndSettle();

    expect(find.text('1 soalan'), findsOneWidget);

    final archivedQuestion = find.byKey(
      const Key('mistake-book-question-question-archived'),
    );

    await tester.scrollUntilVisible(
      archivedQuestion,
      300,
      scrollable: pageScrollable,
    );

    await tester.pumpAndSettle();

    expect(archivedQuestion, findsOneWidget);

    expect(
      find.text(
        'Soalan ini disimpan sebagai rekod '
        'pembelajaran tetapi tidak lagi aktif '
        'dan tidak boleh dimasukkan ke dalam '
        'latihan semula.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('memaparkan error dan membenarkan cuba semula', (tester) async {
    final repository = _FakeMistakeBookRepository(
      detail: _sampleDetail(),
      failFirstRequest: true,
    );

    await _pumpPage(tester, repository: repository);

    expect(
      find.text('Topik Buku Kesilapan tidak dapat dicapai.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cuba Semula'));

    await tester.pumpAndSettle();

    expect(find.text('Kemahiran Insaniah'), findsOneWidget);

    expect(repository.detailCallCount, 2);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required MistakeBookRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: MistakeBookTopicPage(topicId: 'topic-1')),
    ),
  );

  await tester.pumpAndSettle();
}

Finder _verticalPageScrollable() {
  return find.byWidgetPredicate((widget) {
    return widget is Scrollable && widget.axisDirection == AxisDirection.down;
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
    reviewableCount: 1,
    masteredCount: 1,
    items: [
      MistakeBookQuestionItem(
        questionId: 'question-1',
        questionText: 'Apakah jawapan yang betul?',
        options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
        selectedOptionIndex: 0,
        correctOptionIndex: 1,
        explanation: 'Pilihan B ialah jawapan yang betul.',
        status: MistakeBookQuestionStatus.needsReview,
        isReviewable: true,
        incorrectCount: 2,
        reviewCount: 0,
        firstIncorrectAt: DateTime.utc(2026, 7, 26, 8),
        lastIncorrectAt: DateTime.utc(2026, 7, 27, 8),
        lastReviewedAt: null,
        masteredAt: null,
      ),
      MistakeBookQuestionItem(
        questionId: 'question-2',
        questionText: 'Apakah maksud integriti?',
        options: const ['Pilihan W', 'Pilihan X', 'Pilihan Y', 'Pilihan Z'],
        selectedOptionIndex: 2,
        correctOptionIndex: 3,
        explanation: 'Pilihan Z ialah jawapan yang betul.',
        status: MistakeBookQuestionStatus.mastered,
        isReviewable: false,
        incorrectCount: 1,
        reviewCount: 1,
        firstIncorrectAt: DateTime.utc(2026, 7, 26, 9),
        lastIncorrectAt: DateTime.utc(2026, 7, 26, 9),
        lastReviewedAt: DateTime.utc(2026, 7, 27, 9),
        masteredAt: DateTime.utc(2026, 7, 27, 9),
      ),
    ],
  );
}

MistakeBookTopicDetail _allMasteredDetail() {
  final sample = _sampleDetail();

  return MistakeBookTopicDetail(
    generatedAt: sample.generatedAt,
    topicId: sample.topicId,
    topicCode: sample.topicCode,
    topicTitle: sample.topicTitle,
    semester: sample.semester,
    sortOrder: sample.sortOrder,
    needsReviewCount: 0,
    reviewableCount: 0,
    masteredCount: 1,
    items: [sample.items.last],
  );
}

MistakeBookTopicDetail _detailWithArchivedItem() {
  final sample = _sampleDetail();

  final activeItem = sample.items.first;

  return MistakeBookTopicDetail(
    generatedAt: sample.generatedAt,
    topicId: sample.topicId,
    topicCode: sample.topicCode,
    topicTitle: sample.topicTitle,
    semester: sample.semester,
    sortOrder: sample.sortOrder,
    needsReviewCount: 2,
    reviewableCount: 1,
    masteredCount: 0,
    items: [
      activeItem,
      MistakeBookQuestionItem(
        questionId: 'question-archived',
        questionText: 'Soalan lama yang telah dinyahaktifkan.',
        options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
        selectedOptionIndex: 0,
        correctOptionIndex: 1,
        explanation: 'Pilihan B ialah jawapan yang betul.',
        status: MistakeBookQuestionStatus.needsReview,
        isReviewable: false,
        incorrectCount: 1,
        reviewCount: 0,
        firstIncorrectAt: DateTime.utc(2026, 7, 25, 8),
        lastIncorrectAt: DateTime.utc(2026, 7, 25, 8),
        lastReviewedAt: null,
        masteredAt: null,
      ),
    ],
  );
}
