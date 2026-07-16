import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/pages/quiz_question_page.dart';

class _FakeQuizRepository implements QuizRepository {
  const _FakeQuizRepository();

  @override
  Future<QuizSession> startQuiz({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
  }) async {
    return QuizSession(
      sessionId: '00000000-0000-0000-0000-000000000010',
      topicId: topicId,
      mode: mode,
      questionCount: 1,
      expiresAt: DateTime(2026, 7, 16, 12),
      questions: [
        QuizSessionQuestion(
          id: 'q1',
          topicId: topicId,
          questionText: 'Soalan ujian keluar kuiz',
          options: const ['Jawapan A', 'Jawapan B'],
          questionOrder: 1,
        ),
      ],
    );
  }

  @override
  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) async {
    throw UnimplementedError(
      'Submission tidak digunakan dalam test keluar kuiz.',
    );
  }
}

void main() {
  testWidgets('meminta pengesahan sebelum keluar daripada kuiz', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(const _FakeQuizRepository()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Halaman Ujian')),
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) {
                            return const QuizQuestionPage(
                              topicId: 'topic-1',
                              mode: QuizMode.practice,
                              questionCount: 1,
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('Buka Kuiz'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final openQuizButton = find.widgetWithText(FilledButton, 'Buka Kuiz');

    expect(openQuizButton, findsOneWidget);

    await tester.tap(openQuizButton);

    await tester.pumpAndSettle();

    expect(find.text('Soalan ujian keluar kuiz'), findsOneWidget);

    expect(find.text('Jawapan A'), findsOneWidget);

    await tester.tap(find.text('Jawapan A'));

    await tester.pump();

    final backButton = find.byType(BackButton);

    expect(backButton, findsOneWidget);

    await tester.tap(backButton);

    await tester.pumpAndSettle();

    expect(find.text('Keluar Kuiz?'), findsOneWidget);

    expect(
      find.textContaining('1 daripada 1 soalan telah dijawab'),
      findsOneWidget,
    );

    expect(find.textContaining('0 soalan belum dijawab'), findsOneWidget);

    // Batalkan cubaan keluar.
    await tester.tap(find.text('Teruskan Kuiz'));

    await tester.pumpAndSettle();

    expect(find.text('Soalan ujian keluar kuiz'), findsOneWidget);

    expect(find.text('Jawapan A'), findsOneWidget);

    // Cuba keluar sekali lagi.
    await tester.tap(find.byType(BackButton));

    await tester.pumpAndSettle();

    expect(find.text('Keluar Kuiz?'), findsOneWidget);

    final exitButton = find.widgetWithText(FilledButton, 'Keluar');

    expect(exitButton, findsOneWidget);

    await tester.tap(exitButton);

    await tester.pumpAndSettle();

    expect(find.text('Halaman Ujian'), findsOneWidget);

    expect(find.text('Buka Kuiz'), findsOneWidget);

    expect(find.text('Soalan ujian keluar kuiz'), findsNothing);
  });
}
