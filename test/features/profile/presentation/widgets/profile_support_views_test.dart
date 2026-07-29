import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/widgets/profile_error_view.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/widgets/profile_loading_view.dart';

void main() {
  testWidgets('ProfileLoadingView memaparkan loading indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileLoadingView())),
    );

    expect(find.byKey(const Key('profile-loading-view')), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ProfileErrorView memaparkan mesej kegagalan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileErrorView(
            message: 'Profil tidak dapat dimuatkan.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('profile-error-view')), findsOneWidget);

    expect(find.text('Profil tidak dapat dimuatkan.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);
  });

  testWidgets('ProfileErrorView menjalankan callback retry', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileErrorView(
            message: 'Profil tidak dapat dimuatkan.',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-error-retry-button')));

    await tester.pump();

    expect(retryCount, 1);
  });
}
