import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/pages/quiz_question_page.dart';

class _FakeQuizRepository implements QuizRepository {
  const _FakeQuizRepository();

  @override
  Future<List<QuizQuestion>> getQuestions({
    required String topicId,
    required int limit,
  }) async {
    return [
      QuizQuestion(
        id: 'q1',
        topicId: topicId,
        questionText: 'Soalan ujian keluar kuiz',
        options: const ['Jawapan A', 'Jawapan B'],
        correctOptionIndex: 0,
        explanation: 'Penerangan soalan ujian.',
      ),
    ];
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

    await tester.tap(find.text('Buka Kuiz'));

    await tester.pumpAndSettle();

    expect(find.text('Soalan ujian keluar kuiz'), findsOneWidget);

    await tester.tap(find.text('Jawapan A'));

    await tester.pump();

    await tester.tap(find.byType(BackButton));

    await tester.pumpAndSettle();

    expect(find.text('Keluar Kuiz?'), findsOneWidget);

    expect(
      find.textContaining('1 daripada 1 soalan telah dijawab'),
      findsOneWidget,
    );

    // Batalkan cubaan keluar.
    await tester.tap(find.text('Teruskan Kuiz'));

    await tester.pumpAndSettle();

    expect(find.text('Soalan ujian keluar kuiz'), findsOneWidget);

    // Cuba keluar sekali lagi.
    await tester.tap(find.byType(BackButton));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Keluar'));

    await tester.pumpAndSettle();

    expect(find.text('Halaman Ujian'), findsOneWidget);

    expect(find.text('Buka Kuiz'), findsOneWidget);

    expect(find.text('Soalan ujian keluar kuiz'), findsNothing);
  });
}
