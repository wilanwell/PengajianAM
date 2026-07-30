import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/widgets/topics_error_view.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/widgets/topics_loading_view.dart';

void main() {
  testWidgets('TopicsLoadingView memaparkan loading indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TopicsLoadingView())),
    );

    expect(find.byKey(const Key('topics-loading-view')), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TopicsErrorView memaparkan mesej kegagalan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicsErrorView(
            message: 'Senarai topik tidak dapat dimuatkan.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('topics-error-view')), findsOneWidget);

    expect(find.byKey(const Key('topics-error-message')), findsOneWidget);

    expect(find.text('Senarai topik tidak dapat dimuatkan.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);
  });

  testWidgets('TopicsErrorView menjalankan callback retry', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicsErrorView(
            message: 'Senarai topik tidak dapat dimuatkan.',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('topics-error-retry-button')));

    await tester.pump();

    expect(retryCount, 1);
  });
}
