import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/app/app.dart';

void main() {
  testWidgets('memaparkan borang log masuk', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);

    expect(find.text('E-mel'), findsOneWidget);

    expect(find.text('Kata laluan'), findsOneWidget);

    expect(find.text('Log Masuk'), findsOneWidget);
  });

  testWidgets('membuka halaman pendaftaran', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    await tester.pumpAndSettle();

    final registerButton = find.widgetWithText(OutlinedButton, 'Daftar Akaun');

    await tester.ensureVisible(registerButton);
    await tester.pumpAndSettle();

    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Cipta Akaun'), findsOneWidget);

    expect(find.text('Sahkan kata laluan'), findsOneWidget);
  });

  testWidgets('log masuk dan menukar destination navigasi utama', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);

    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'student@email.com');

    await tester.enterText(textFields.at(1), '123456');

    final loginButton = find.widgetWithText(FilledButton, 'Log Masuk');

    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();

    await tester.tap(loginButton);
    await tester.pump();

    // Mock login uses a 600-millisecond delay.
    await tester.pump(const Duration(milliseconds: 700));

    await tester.pumpAndSettle();

    expect(find.text('Utama'), findsOneWidget);

    expect(find.text('Topik'), findsOneWidget);

    expect(find.text('Kuiz'), findsOneWidget);

    expect(find.text('Ranking'), findsOneWidget);

    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Topik'));

    await tester.pumpAndSettle();

    expect(find.text('Topik Pembelajaran'), findsOneWidget);
  });
}
