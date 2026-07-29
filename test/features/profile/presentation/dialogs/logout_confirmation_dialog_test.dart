import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/dialogs/logout_confirmation_dialog.dart';

void main() {
  testWidgets('memaparkan maklumat pengesahan Log Keluar', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-logout-dialog'),
                onPressed: () async {
                  result = await showLogoutConfirmationDialog(context);
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-logout-dialog')));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile-logout-confirmation-dialog')),
      findsOneWidget,
    );

    expect(find.text('Log Keluar?'), findsOneWidget);

    expect(
      find.text(
        'Anda perlu log masuk semula '
        'untuk menggunakan aplikasi.',
      ),
      findsOneWidget,
    );

    expect(result, isNull);
  });

  testWidgets('memulangkan false apabila Log Keluar dibatalkan', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-logout-dialog'),
                onPressed: () async {
                  result = await showLogoutConfirmationDialog(context);
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-logout-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-logout-cancel-button')));

    await tester.pumpAndSettle();

    expect(result, isFalse);

    expect(
      find.byKey(const Key('profile-logout-confirmation-dialog')),
      findsNothing,
    );
  });

  testWidgets('memulangkan true apabila Log Keluar disahkan', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-logout-dialog'),
                onPressed: () async {
                  result = await showLogoutConfirmationDialog(context);
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-logout-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-logout-confirm-button')));

    await tester.pumpAndSettle();

    expect(result, isTrue);

    expect(
      find.byKey(const Key('profile-logout-confirmation-dialog')),
      findsNothing,
    );
  });
}
