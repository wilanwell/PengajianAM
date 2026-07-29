import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/dialogs/about_application_dialog.dart';

void main() {
  testWidgets('memaparkan maklumat Tentang Aplikasi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-about-dialog'),
                onPressed: () {
                  showAboutApplicationDialog(
                    context,
                    onTermsOfUseTap: () {},
                    onPrivacyPolicyTap: () {},
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-about-dialog')));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile-about-application-dialog')),
      findsOneWidget,
    );

    expect(find.text('Developer/Penerbit'), findsOneWidget);

    expect(find.text('E-mel Sokongan'), findsOneWidget);

    expect(find.text('Terma Penggunaan'), findsOneWidget);

    expect(find.text('Dasar Privasi'), findsOneWidget);
  });

  testWidgets('menutup dialog dan menjalankan callback Terma Penggunaan', (
    tester,
  ) async {
    var termsTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-about-dialog'),
                onPressed: () {
                  showAboutApplicationDialog(
                    context,
                    onTermsOfUseTap: () {
                      termsTapCount++;
                    },
                    onPrivacyPolicyTap: () {},
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-about-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-about-terms-button')));

    await tester.pumpAndSettle();

    expect(termsTapCount, 1);

    expect(
      find.byKey(const Key('profile-about-application-dialog')),
      findsNothing,
    );
  });

  testWidgets('menutup dialog dan menjalankan callback Dasar Privasi', (
    tester,
  ) async {
    var privacyTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-about-dialog'),
                onPressed: () {
                  showAboutApplicationDialog(
                    context,
                    onTermsOfUseTap: () {},
                    onPrivacyPolicyTap: () {
                      privacyTapCount++;
                    },
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-about-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-about-privacy-button')));

    await tester.pumpAndSettle();

    expect(privacyTapCount, 1);

    expect(
      find.byKey(const Key('profile-about-application-dialog')),
      findsNothing,
    );
  });

  testWidgets('butang Tutup menutup dialog tanpa callback navigation', (
    tester,
  ) async {
    var termsTapCount = 0;
    var privacyTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                key: const Key('open-about-dialog'),
                onPressed: () {
                  showAboutApplicationDialog(
                    context,
                    onTermsOfUseTap: () {
                      termsTapCount++;
                    },
                    onPrivacyPolicyTap: () {
                      privacyTapCount++;
                    },
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-about-dialog')));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-about-close-button')));

    await tester.pumpAndSettle();

    expect(termsTapCount, 0);

    expect(privacyTapCount, 0);

    expect(
      find.byKey(const Key('profile-about-application-dialog')),
      findsNothing,
    );
  });
}
