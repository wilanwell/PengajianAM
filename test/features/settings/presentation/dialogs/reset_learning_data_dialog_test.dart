import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/dialogs/reset_learning_data_dialog.dart';

void main() {
  testWidgets(
    'memaparkan maklumat reset dan memulangkan false apabila dibatalkan',
    (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: FilledButton(
                  key: const Key('open-reset-dialog'),
                  onPressed: () async {
                    result = await showResetLearningDataDialog(context);
                  },
                  child: const Text('Buka Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-reset-dialog')));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings-reset-confirmation-dialog')),
        findsOneWidget,
      );

      expect(find.text('Reset Semua Data?'), findsOneWidget);

      expect(
        find.textContaining(
          'Akaun log masuk anda tidak akan '
          'dipadamkan.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('settings-reset-cancel-button')));

      await tester.pumpAndSettle();

      expect(result, isFalse);
    },
  );

  testWidgets('memulangkan true apabila reset disahkan', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-reset-dialog'),
                onPressed: () async {
                  result = await showResetLearningDataDialog(context);
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-reset-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-reset-confirm-button')));

    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
