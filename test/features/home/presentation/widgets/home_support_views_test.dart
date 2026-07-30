import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/widgets/home_error_view.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/widgets/home_loading_view.dart';

void main() {
  testWidgets('HomeLoadingView memaparkan loading indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeLoadingView())),
    );

    expect(find.byKey(const Key('home-loading-view')), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeErrorView memaparkan mesej kegagalan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeErrorView(
            message: 'Dashboard tidak dapat dimuatkan.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('home-error-view')), findsOneWidget);

    expect(find.byKey(const Key('home-error-message')), findsOneWidget);

    expect(find.text('Dashboard tidak dapat dimuatkan.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);
  });

  testWidgets('HomeErrorView menjalankan callback retry', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeErrorView(
            message: 'Dashboard tidak dapat dimuatkan.',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-error-retry-button')));

    await tester.pump();

    expect(retryCount, 1);
  });
}
