import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/sections/data_management_section.dart';

void main() {
  testWidgets('memaparkan bahagian pengurusan data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataManagementSection(isResetting: false, onReset: () async {}),
        ),
      ),
    );

    expect(
      find.byKey(const Key('settings-data-management-section')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('settings-reset-data-card')), findsOneWidget);

    expect(find.text('Pengurusan Data'), findsOneWidget);

    expect(find.text('Reset Data Pembelajaran'), findsOneWidget);

    expect(find.text('Reset Semua Data'), findsOneWidget);
  });

  testWidgets('menjalankan callback reset data', (tester) async {
    var resetCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataManagementSection(
            isResetting: false,
            onReset: () async {
              resetCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-reset-data-button')));

    await tester.pump();

    expect(resetCount, 1);
  });

  testWidgets('melumpuhkan butang semasa proses reset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataManagementSection(isResetting: true, onReset: () async {}),
        ),
      ),
    );

    expect(find.text('Sedang Reset...'), findsOneWidget);

    expect(
      find.byKey(const Key('settings-reset-data-progress')),
      findsOneWidget,
    );

    final resetButton = tester.widget<FilledButton>(
      find.byKey(const Key('settings-reset-data-button')),
    );

    expect(resetButton.onPressed, isNull);
  });
}
