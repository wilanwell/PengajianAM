import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/sections/account_management_section.dart';

void main() {
  testWidgets('memaparkan bahagian pengurusan akaun', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountManagementSection(onDeleteAccountTap: () {}),
        ),
      ),
    );

    expect(
      find.byKey(const Key('settings-account-management-section')),
      findsOneWidget,
    );

    expect(
      find.byKey(const Key('settings-delete-account-tile')),
      findsOneWidget,
    );

    expect(find.text('Pengurusan Akaun'), findsOneWidget);

    expect(find.text('Padam Akaun'), findsOneWidget);

    expect(
      find.text('Padam akaun dan semua data secara kekal'),
      findsOneWidget,
    );
  });

  testWidgets('menjalankan callback padam akaun', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountManagementSection(
            onDeleteAccountTap: () {
              tapCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-delete-account-tile')));

    await tester.pump();

    expect(tapCount, 1);
  });
}
