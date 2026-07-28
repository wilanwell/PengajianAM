import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pengajian_am_stpm_objektif/app/router/route_names.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_topic_detail.dart';
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

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    throw UnimplementedError();
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

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    throw UnimplementedError();
  }
}

class _RefreshFailureRepository implements MistakeBookRepository {
  int fetchCallCount = 0;

  @override
  Future<MistakeBookSnapshot> fetchMistakeBook() async {
    fetchCallCount++;

    if (fetchCallCount == 1) {
      return _sampleSnapshot();
    }

    throw const MistakeBookFailure('Sambungan Internet terputus.');
  }

  @override
  Future<MistakeBookTopicDetail> fetchMistakeBookTopic(String topicId) {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('memaparkan ringkasan dan topik Mistake Book', (tester) async {
    final repository = _FakeMistakeBookRepository(snapshot: _sampleSnapshot());

    await _pumpPage(tester, repository: repository);

    expect(find.text('Buku Kesilapan'), findsOneWidget);

    expect(find.text('42 soalan sedang dijejaki.'), findsOneWidget);

    final reviewableCard = find.byKey(const Key('mistake-book-reviewable'));

    final masteredCard = find.byKey(const Key('mistake-book-mastered'));

    final archivedCard = find.byKey(const Key('mistake-book-archived'));

    final needsReviewCard = find.byKey(const Key('mistake-book-needs-review'));

    expect(
      find.descendant(of: reviewableCard, matching: find.text('34')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: masteredCard, matching: find.text('3')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: archivedCard, matching: find.text('5')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: needsReviewCard, matching: find.text('39')),
      findsOneWidget,
    );

    final firstTopicCard = find.byKey(const Key('mistake-book-topic-topic-1'));

    expect(firstTopicCard, findsOneWidget);

    expect(
      find.descendant(
        of: firstTopicCard,
        matching: find.text('Kemahiran Insaniah'),
      ),
      findsOneWidget,
    );

    expect(
      find.text(
        '3 soalan diarkibkan dan tidak '
        'dimasukkan ke dalam latihan.',
      ),
      findsOneWidget,
    );

    final thirdTopicCard = find.byKey(const Key('mistake-book-topic-topic-3'));

    await tester.scrollUntilVisible(
      thirdTopicCard,
      300,
      scrollable: _verticalPageScrollable(),
    );

    await tester.pumpAndSettle();

    expect(thirdTopicCard, findsOneWidget);

    expect(repository.fetchCallCount, 1);
  });

  testWidgets('kad topik membuka route detail yang dipilih', (tester) async {
    final repository = _FakeMistakeBookRepository(snapshot: _sampleSnapshot());

    final router = GoRouter(
      initialLocation: RoutePaths.mistakeBook,
      routes: [
        GoRoute(
          path: RoutePaths.mistakeBook,
          name: RouteNames.mistakeBook,
          builder: (context, state) {
            return const MistakeBookPage();
          },
        ),
        GoRoute(
          path: RoutePaths.mistakeBookTopic,
          name: RouteNames.mistakeBookTopic,
          builder: (context, state) {
            return Scaffold(
              body: Text(
                'Detail '
                '${state.pathParameters['topicId']}',
              ),
            );
          },
        ),
      ],
    );

    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mistakeBookRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final topicCard = find.byKey(const Key('mistake-book-topic-topic-1'));

    await tester.scrollUntilVisible(
      topicCard,
      300,
      scrollable: _verticalPageScrollable(),
    );

    await tester.pumpAndSettle();

    expect(topicCard, findsOneWidget);

    await tester.tap(topicCard);

    await tester.pumpAndSettle();

    expect(find.text('Detail topic-1'), findsOneWidget);
  });

  testWidgets('memuat semula secara automatik apabila halaman dibuka semula', (
    tester,
  ) async {
    final repository = _FakeMistakeBookRepository(snapshot: _sampleSnapshot());

    final isPageVisible = ValueNotifier<bool>(true);

    addTearDown(isPageVisible.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mistakeBookRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: isPageVisible,
            builder: (context, isVisible, child) {
              return isVisible
                  ? const MistakeBookPage()
                  : const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.fetchCallCount, 1);

    isPageVisible.value = false;
    await tester.pumpAndSettle();

    isPageVisible.value = true;
    await tester.pumpAndSettle();

    expect(repository.fetchCallCount, 2);
  });

  testWidgets('memaparkan empty state yang sah', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeMistakeBookRepository(
        snapshot: MistakeBookSnapshot(
          generatedAt: DateTime.utc(2026, 7, 26, 14),
          needsReviewCount: 0,
          reviewableCount: 0,
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

    await tester.tap(find.text('Cuba Semula'));

    await tester.pumpAndSettle();

    expect(find.text('42 soalan sedang dijejaki.'), findsOneWidget);

    expect(repository.fetchCallCount, 2);
  });

  testWidgets('mengekalkan data lama apabila refresh gagal', (tester) async {
    final repository = _RefreshFailureRepository();

    await _pumpPage(tester, repository: repository);

    expect(find.text('42 soalan sedang dijejaki.'), findsOneWidget);

    final listView = find.byKey(
      const PageStorageKey<String>('mistake-book-main-list'),
    );

    await tester.drag(listView, const Offset(0, 400));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mistake-book-stale-data-warning')),
      findsOneWidget,
    );

    expect(find.text('Sambungan Internet terputus.'), findsOneWidget);

    expect(find.text('42 soalan sedang dijejaki.'), findsOneWidget);

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

Finder _verticalPageScrollable() {
  return find.byWidgetPredicate((widget) {
    return widget is Scrollable && widget.axisDirection == AxisDirection.down;
  });
}

MistakeBookSnapshot _sampleSnapshot() {
  return MistakeBookSnapshot(
    generatedAt: DateTime.utc(2026, 7, 26, 14),
    needsReviewCount: 39,
    reviewableCount: 34,
    masteredCount: 3,
    topics: [
      MistakeBookTopicSummary(
        topicId: 'topic-1',
        topicCode: 'S1-01',
        topicTitle: 'Kemahiran Insaniah',
        semester: 1,
        sortOrder: 1,
        needsReviewCount: 15,
        reviewableCount: 12,
        masteredCount: 2,
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
        masteredCount: 1,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 12),
      ),
      MistakeBookTopicSummary(
        topicId: 'topic-3',
        topicCode: 'S1-04',
        topicTitle: 'Sistem dan Struktur Pemerintahan',
        semester: 1,
        sortOrder: 4,
        needsReviewCount: 10,
        reviewableCount: 8,
        masteredCount: 0,
        lastMistakeAt: DateTime.utc(2026, 7, 26, 11),
      ),
    ],
  );
}
