import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_hub_error_view.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_hub_loading_view.dart';

void main() {
  testWidgets('QuizHubLoadingView memaparkan loading indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuizHubLoadingView())),
    );

    expect(find.byKey(const Key('quiz-hub-loading-view')), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('QuizHubErrorView memaparkan mesej kegagalan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizHubErrorView(
            message: 'Senarai topik tidak dapat dimuatkan.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('quiz-hub-error-view')), findsOneWidget);

    expect(find.byKey(const Key('quiz-hub-error-message')), findsOneWidget);

    expect(find.text('Senarai topik tidak dapat dimuatkan.'), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);
  });

  testWidgets('QuizHubErrorView menjalankan callback retry', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizHubErrorView(
            message: 'Senarai topik tidak dapat dimuatkan.',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('quiz-hub-error-retry-button')));

    await tester.pump();

    expect(retryCount, 1);
  });
}
