import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';

class _FakeUserProgressRepository implements UserProgressRepository {
  UserProgress? storedProgress;
  int saveCallCount = 0;

  @override
  Future<UserProgress?> loadProgress() async {
    return storedProgress;
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    storedProgress = progress;
    saveCallCount++;
  }

  @override
  Future<void> clearProgress() async {
    storedProgress = null;
  }
}

void main() {
  test('merekod keputusan kuiz dan menyimpan progress', () async {
    final repository = _FakeUserProgressRepository();

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    await controller.initialize();

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

    await controller.recordQuizResult(result);

    final updatedState = container.read(userProgressControllerProvider);

    final updatedWeeklyActivityTotal = updatedState.weeklyAnsweredQuestions
        .fold<int>(0, (total, value) => total + value);

    expect(updatedState.totalXp, initialState.totalXp + 30);

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

    expect(repository.storedProgress?.totalXp, updatedState.totalXp);

    expect(repository.saveCallCount, 1);
  });

  test('menyimpan dan memuatkan semula nama paparan', () async {
    final repository = _FakeUserProgressRepository();

    final firstContainer = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    final firstController = firstContainer.read(
      userProgressControllerProvider.notifier,
    );

    await firstController.initialize();

    final errorMessage = await firstController.updateDisplayName(
      'Welljoel Walter',
    );

    expect(errorMessage, isNull);
    expect(repository.storedProgress?.displayName, 'Welljoel Walter');

    firstContainer.dispose();

    final secondContainer = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(secondContainer.dispose);

    final secondController = secondContainer.read(
      userProgressControllerProvider.notifier,
    );

    await secondController.initialize();

    final restoredState = secondContainer.read(userProgressControllerProvider);

    expect(restoredState.displayName, 'Welljoel Walter');
  });
}
