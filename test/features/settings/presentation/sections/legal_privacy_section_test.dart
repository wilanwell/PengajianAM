import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/sections/legal_privacy_section.dart';

void main() {
  testWidgets('memaparkan pautan undang-undang dan privasi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LegalPrivacySection(
            onTermsOfUseTap: () {},
            onPrivacyPolicyTap: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('settings-legal-privacy-section')),
      findsOneWidget,
    );

    expect(find.text('Undang-undang dan Privasi'), findsOneWidget);

    expect(find.text('Terma Penggunaan'), findsOneWidget);

    expect(find.text('Dasar Privasi'), findsOneWidget);

    expect(find.byKey(const Key('settings-terms-of-use-tile')), findsOneWidget);

    expect(
      find.byKey(const Key('settings-privacy-policy-tile')),
      findsOneWidget,
    );
  });

  testWidgets('menjalankan callback Terma Penggunaan', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LegalPrivacySection(
            onTermsOfUseTap: () {
              tapCount++;
            },
            onPrivacyPolicyTap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-terms-of-use-tile')));

    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('menjalankan callback Dasar Privasi', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LegalPrivacySection(
            onTermsOfUseTap: () {},
            onPrivacyPolicyTap: () {
              tapCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-privacy-policy-tile')));

    await tester.pump();

    expect(tapCount, 1);
  });
}
