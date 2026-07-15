import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';

void main() {
  test('merekod keputusan kuiz dan mengemas kini progress', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    final initialState = container.read(userProgressControllerProvider);

    final initialWeeklyActivityTotal = initialState.weeklyAnsweredQuestions
        .fold<int>(0, (total, value) => total + value);

    final firstQuestion = QuizQuestion(
      id: 'q1',
      topicId: 'topic-s1-02',
      questionText: 'Soalan pertama',
      options: const ['Betul', 'Salah'],
      correctOptionIndex: 0,
      explanation: 'Penerangan pertama',
    );

    final secondQuestion = QuizQuestion(
      id: 'q2',
      topicId: 'topic-s1-02',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      correctOptionIndex: 1,
      explanation: 'Penerangan kedua',
    );

    final result = QuizResult(
      topicId: 'topic-s1-02',
      mode: QuizMode.practice,
      questions: [firstQuestion, secondQuestion],
      selectedAnswers: const {'q1': 0, 'q2': 0},
      correctAnswers: 1,
      answeredQuestions: 2,
      elapsedTime: const Duration(minutes: 1),
      autoSubmitted: false,
    );

    controller.recordQuizResult(result);

    final updatedState = container.read(userProgressControllerProvider);

    final updatedWeeklyActivityTotal = updatedState.weeklyAnsweredQuestions
        .fold<int>(0, (total, value) => total + value);

    expect(updatedState.totalXp, initialState.totalXp + 30);

    expect(updatedState.weeklyXp, initialState.weeklyXp + 30);

    expect(updatedState.monthlyXp, initialState.monthlyXp + 30);

    expect(updatedState.completedQuizzes, initialState.completedQuizzes + 1);

    expect(
      updatedState.totalCorrectAnswers,
      initialState.totalCorrectAnswers + 1,
    );

    expect(
      updatedState.totalQuizQuestions,
      initialState.totalQuizQuestions + 2,
    );

    expect(updatedWeeklyActivityTotal, initialWeeklyActivityTotal + 2);
  });

  test('mengemas kini nama paparan shared progress', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    final errorMessage = controller.updateDisplayName('Welljoel Walter');

    final state = container.read(userProgressControllerProvider);

    expect(errorMessage, isNull);
    expect(state.displayName, 'Welljoel Walter');
  });
}
