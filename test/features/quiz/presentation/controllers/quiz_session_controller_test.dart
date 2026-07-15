import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_session_state.dart';

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
        questionText: 'Soalan satu',
        options: const ['Betul', 'Salah'],
        correctOptionIndex: 0,
        explanation: 'Penerangan satu',
      ),
      QuizQuestion(
        id: 'q2',
        topicId: topicId,
        questionText: 'Soalan dua',
        options: const ['Salah', 'Betul'],
        correctOptionIndex: 1,
        explanation: 'Penerangan dua',
      ),
    ];
  }
}

void main() {
  test('memulakan, menjawab dan menghantar kuiz', () async {
    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(const _FakeQuizRepository()),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(quizSessionControllerProvider.notifier);

    await controller.startQuiz(
      topicId: 'topic-s1-02',
      mode: QuizMode.practice,
      questionCount: 2,
    );

    var state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.ready);

    expect(state.questions, hasLength(2));

    controller.selectAnswer(0);
    controller.toggleFlagCurrentQuestion();
    controller.nextQuestion();
    controller.selectAnswer(0);

    await controller.submitQuiz();

    state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.completed);

    expect(state.result, isNotNull);

    expect(state.result!.correctAnswers, 1);

    expect(state.result!.answeredQuestions, 2);
  });
}
