import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/mistake_book/domain/entities/mistake_book_snapshot.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/widgets/profile_mistake_book_card.dart';

void main() {
  testWidgets('memaparkan ringkasan Mistake Book dan membuka halaman', (
    tester,
  ) async {
    var openCount = 0;

    await _pumpCard(
      tester,
      card: ProfileMistakeBookCard(
        snapshot: _sampleSnapshot(),
        onOpen: () {
          openCount++;
        },
        onRetry: () {},
      ),
    );

    expect(find.text('Buku Kesilapan'), findsOneWidget);

    expect(find.text('Boleh Dilatih'), findsOneWidget);

    expect(find.text('Dikuasai'), findsOneWidget);

    expect(find.text('Diarkibkan'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-mistake-book-reviewable')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-mistake-book-mastered')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('profile-mistake-book-archived')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    expect(find.text('38%'), findsOneWidget);

    expect(find.text('3 daripada 8 soalan telah dikuasai.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-mistake-book-open')));

    await tester.pump();

    expect(openCount, 1);
  });

  testWidgets('memaparkan loading apabila snapshot belum tersedia', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      card: ProfileMistakeBookCard(
        isLoading: true,
        onOpen: () {},
        onRetry: () {},
      ),
    );

    expect(find.text('Memuatkan ringkasan Buku Kesilapan...'), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('memaparkan error dan membenarkan retry', (tester) async {
    var retryCount = 0;

    await _pumpCard(
      tester,
      card: ProfileMistakeBookCard(
        errorMessage: 'Buku Kesilapan tidak dapat dimuatkan.',
        onOpen: () {},
        onRetry: () {
          retryCount++;
        },
      ),
    );

    expect(find.byKey(const Key('profile-mistake-book-error')), findsOneWidget);

    expect(find.text('Buku Kesilapan tidak dapat dimuatkan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-mistake-book-retry')));

    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('memaparkan amaran stale data bersama snapshot lama', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      card: ProfileMistakeBookCard(
        snapshot: _sampleSnapshot(),
        errorMessage: 'Sambungan Internet terputus.',
        onOpen: () {},
        onRetry: () {},
      ),
    );

    expect(
      find.byKey(const Key('profile-mistake-book-stale-warning')),
      findsOneWidget,
    );

    expect(
      find.text(
        'Sambungan Internet terputus. '
        'Data terakhir masih dipaparkan.',
      ),
      findsOneWidget,
    );

    expect(find.text('38%'), findsOneWidget);
  });

  testWidgets('memaparkan keadaan kosong tanpa kesilapan', (tester) async {
    await _pumpCard(
      tester,
      card: ProfileMistakeBookCard(
        snapshot: MistakeBookSnapshot(
          generatedAt: DateTime.utc(2026, 7, 28),
          needsReviewCount: 0,
          reviewableCount: 0,
          masteredCount: 0,
          topics: const [],
        ),
        onOpen: () {},
        onRetry: () {},
      ),
    );

    expect(find.byKey(const Key('profile-mistake-book-empty')), findsOneWidget);

    expect(
      find.text(
        'Belum ada kesilapan direkodkan. '
        'Teruskan menjawab kuiz.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpCard(WidgetTester tester, {required Widget card}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: card,
        ),
      ),
    ),
  );
}

MistakeBookSnapshot _sampleSnapshot() {
  return MistakeBookSnapshot(
    generatedAt: DateTime.utc(2026, 7, 28),
    needsReviewCount: 5,
    reviewableCount: 4,
    masteredCount: 3,
    topics: const [],
  );
}
