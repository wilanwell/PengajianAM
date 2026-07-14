import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/app/app.dart';

void main() {
  testWidgets('memaparkan halaman log masuk ketika aplikasi dibuka', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    await tester.pumpAndSettle();

    expect(find.text('Pengajian AM STPM Objektif'), findsOneWidget);

    expect(find.text('Masuk Sementara'), findsOneWidget);
  });
}
