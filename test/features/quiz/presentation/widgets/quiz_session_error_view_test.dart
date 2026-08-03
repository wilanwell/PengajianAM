import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/widgets/quiz_session_error_view.dart';

void main() {
  testWidgets('memaparkan mesej kegagalan dan butang cuba semula', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizSessionErrorView(
            message: 'Kuiz tidak dapat dimulakan.',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('quiz-session-error-view')), findsOneWidget);

    expect(find.text('Kuiz tidak dapat dimulakan.'), findsOneWidget);

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    expect(find.text('Cuba Semula'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-session-retry-button')));

    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('memaparkan mesej kegagalan panjang tanpa overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizSessionErrorView(
            message:
                'Sesi kuiz tidak dapat disambung. '
                'Semak sambungan Internet dan '
                'cuba semula.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    expect(
      find.textContaining('Sesi kuiz tidak dapat disambung'),
      findsOneWidget,
    );
  });
}
