import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/widgets/settings_error_view.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/widgets/settings_header.dart';

void main() {
  testWidgets('SettingsHeader memaparkan maklumat tetapan pembelajaran', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SettingsHeader())),
    );

    expect(find.byKey(const Key('settings-header')), findsOneWidget);

    expect(find.text('Tetapan Pembelajaran'), findsOneWidget);

    expect(
      find.text('Sesuaikan tetapan kuiz mengikut cara pembelajaran anda.'),
      findsOneWidget,
    );

    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('SettingsErrorView memaparkan mesej kegagalan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsErrorView(
            message: 'Tetapan tidak dapat dimuatkan.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('settings-error-view')), findsOneWidget);

    expect(find.text('Tetapan tidak dapat dimuatkan.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);
  });

  testWidgets('SettingsErrorView menjalankan callback cuba semula', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsErrorView(
            message: 'Tetapan tidak dapat dimuatkan.',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-error-retry-button')));

    await tester.pump();

    expect(retryCount, 1);
  });
}
