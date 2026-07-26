import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_summary.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/exceptions/mistake_book_failure.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/repositories/mistake_book_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/controllers/mistake_book_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/presentation/pages/mistake_book_page.dart';

class _FakeMistakeBookRepository implements MistakeBookRepository {
  _FakeMistakeBookRepository({required this.snapshot});

  final MistakeBookSnapshot snapshot;

  int fetchCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() async {
    fetchCallCount++;

    return snapshot;
  }
}

class _RetryMistakeBookRepository implements MistakeBookRepository {
  int fetchCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() async {
    fetchCallCount++;

    if (fetchCallCount == 1) {
      throw const MistakeBookFailure('Buku Kesilapan tidak dapat dicapai.');
    }

    return _sampleSnapshot();
  }
}

void main() {
  testWidgets('memaparkan ringkasan hosted dan tiga topik', (tester) async {
    final repository = _FakeMistakeBookRepository(snapshot: _sampleSnapshot());

    await _pumpPage(tester, repository: repository);

    expect(find.text('Buku Kesilapan'), findsOneWidget);
    expect(find.text('39 soalan sedang dijejaki.'), findsOneWidget);

    final needsReviewCard = find.byKey(const Key('mistake-book-needs-review'));

    final masteredCard = find.byKey(const Key('mistake-book-mastered'));

    expect(
      find.descendant(of: needsReviewCard, matching: find.text('39')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: masteredCard, matching: find.text('0')),
      findsOneWidget,
    );

    final firstTopicCard = find.byKey(const Key('mistake-book-topic-topic-1'));

    final secondTopicCard = find.byKey(const Key('mistake-book-topic-topic-2'));

    expect(firstTopicCard, findsOneWidget);

    expect(
      find.descendant(
        of: firstTopicCard,
        matching: find.text('Kemahiran Insaniah'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(secondTopicCard, 300);
    await tester.pumpAndSettle();

    expect(secondTopicCard, findsOneWidget);

    expect(
      find.descendant(
        of: secondTopicCard,
        matching: find.text('Perlembagaan Persekutuan'),
      ),
      findsOneWidget,
    );

    final thirdTopicCard = find.byKey(const Key('mistake-book-topic-topic-3'));

    await tester.scrollUntilVisible(thirdTopicCard, 300);
    await tester.pumpAndSettle();

    expect(thirdTopicCard, findsOneWidget);

    expect(repository.fetchCallCount, 1);
  });

  testWidgets('memaparkan empty state yang sah', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeMistakeBookRepository(
        snapshot: MistakeBookSnapshot(
          generatedAt: DateTime.utc(2026, 7, 26, 14),
          needsReviewCount: 0,
          masteredCount: 0,
          topics: const [],
        ),
      ),
    );

    expect(find.text('Belum Ada Kesilapan Direkodkan'), findsOneWidget);
  });

  testWidgets('memaparkan error dan tindakan cuba semula', (tester) async {
    final repository = _RetryMistakeBookRepository();

    await _pumpPage(tester, repository: repository);

    expect(find.text('Buku Kesilapan tidak dapat dicapai.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);

    await tester.tap(find.text('Cuba Semula'));
    await tester.pumpAndSettle();

    expect(find.text('39 soalan sedang dijejaki.'), findsOneWidget);
    expect(repository.fetchCallCount, 2);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required MistakeBookRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [mistakeBookRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: MistakeBookPage()),
    ),
  );

  await tester.pumpAndSettle();
}

MistakeBookSnapshot _sampleSnapshot() {
  return MistakeBookSnapshot(
    generatedAt: DateTime.utc(2026, 7, 26, 14),
    needsReviewCount: 39,
    masteredCount: 0,
    topics: [
      MistakeBookTopicSummary(
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Kemahiran Insaniah',
        semester: 1,
        sortOrder: 1,
        needsReviewCount: 15,
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
        masteredCount: 0,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 11),
      ),
    ],
  );
}
