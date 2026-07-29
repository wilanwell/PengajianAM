import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/dialogs/edit_display_name_dialog.dart';

void main() {
  testWidgets('memaparkan nama asal dan memulangkan nama baharu', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-edit-name-dialog'),
                onPressed: () async {
                  result = await showEditDisplayNameDialog(
                    context,
                    initialName: 'Pelajar Lama',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-edit-name-dialog')));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-edit-name-dialog')), findsOneWidget);

    expect(find.text('Edit Nama Paparan'), findsOneWidget);

    expect(find.text('Pelajar Lama'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('profile-edit-name-field')),
      'Pelajar Baharu',
    );

    await tester.tap(find.byKey(const Key('profile-edit-name-save')));

    await tester.pumpAndSettle();

    expect(result, 'Pelajar Baharu');
  });

  testWidgets('memulangkan null apabila dialog dibatalkan', (tester) async {
    String? result = 'belum berubah';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-edit-name-dialog'),
                onPressed: () async {
                  result = await showEditDisplayNameDialog(
                    context,
                    initialName: 'Pelajar Ujian',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-edit-name-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-edit-name-cancel')));

    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('memulangkan nama apabila keyboard action selesai digunakan', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-edit-name-dialog'),
                onPressed: () async {
                  result = await showEditDisplayNameDialog(
                    context,
                    initialName: 'Pelajar Asal',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-edit-name-dialog')));

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-edit-name-field')),
      'Pelajar Keyboard',
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);

    await tester.pumpAndSettle();

    expect(result, 'Pelajar Keyboard');
  });
}
