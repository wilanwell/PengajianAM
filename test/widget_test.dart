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

    expect(registerButton, findsOneWidget);

    // Scroll sehingga butang benar-benar berada dalam kawasan skrin ujian.
    await tester.ensureVisible(registerButton);
    await tester.pumpAndSettle();

    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Cipta Akaun'), findsOneWidget);

    expect(find.text('Sahkan kata laluan'), findsOneWidget);
  });
}
