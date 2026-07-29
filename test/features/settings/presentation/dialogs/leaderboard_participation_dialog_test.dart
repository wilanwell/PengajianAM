import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/dialogs/leaderboard_participation_dialog.dart';

void main() {
  testWidgets(
    'memaparkan dialog opt-in dan memulangkan true apabila dipersetujui',
    (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: FilledButton(
                  key: const Key('open-leaderboard-dialog'),
                  onPressed: () async {
                    result = await showLeaderboardParticipationDialog(
                      context,
                      optIn: true,
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-leaderboard-dialog')));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings-leaderboard-opt-in-dialog')),
        findsOneWidget,
      );

      expect(find.text('Sertai Leaderboard?'), findsOneWidget);

      expect(
        find.textContaining(
          'Pengguna lain hanya akan '
          'melihat nama samaran',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('settings-leaderboard-opt-in-confirm')),
      );

      await tester.pumpAndSettle();

      expect(result, isTrue);
    },
  );

  testWidgets('memulangkan false apabila dialog opt-in dibatalkan', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-leaderboard-dialog'),
                onPressed: () async {
                  result = await showLeaderboardParticipationDialog(
                    context,
                    optIn: true,
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-leaderboard-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('settings-leaderboard-opt-in-cancel')),
    );

    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets(
    'memaparkan dialog opt-out dan memulangkan true apabila disahkan',
    (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: FilledButton(
                  key: const Key('open-leaderboard-dialog'),
                  onPressed: () async {
                    result = await showLeaderboardParticipationDialog(
                      context,
                      optIn: false,
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-leaderboard-dialog')));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings-leaderboard-opt-out-dialog')),
        findsOneWidget,
      );

      expect(find.text('Berhenti Menyertai?'), findsOneWidget);

      expect(find.textContaining('XP, progress, sejarah kuiz'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('settings-leaderboard-opt-out-confirm')),
      );

      await tester.pumpAndSettle();

      expect(result, isTrue);
    },
  );
}
