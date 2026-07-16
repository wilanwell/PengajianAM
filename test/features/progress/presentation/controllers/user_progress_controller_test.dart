import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';

class _FakeUserProgressRepository implements UserProgressRepository {
  _FakeUserProgressRepository({required this.progress});

  UserProgress progress;
  int loadCallCount = 0;
  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<UserProgress?> loadProgress() async {
    loadCallCount++;
    return progress;
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    this.progress = progress;
    saveCallCount++;
  }

  @override
  Future<void> clearProgress() async {
    clearCallCount++;

    progress = progress.copyWith(
      displayName: 'Pelajar Ujian',
      totalXp: 0,
      weeklyXp: 0,
      monthlyXp: 0,
      completedQuizzes: 0,
      totalCorrectAnswers: 0,
      totalQuizQuestions: 0,
      highestScore: 0,
      completedTopics: 0,
      currentStreakDays: 0,
      bestStreakDays: 0,
      weeklyAnsweredQuestions: List<int>.unmodifiable([0, 0, 0, 0, 0, 0, 0]),
    );
  }
}

UserProgress _createProgress({int totalXp = 1820, int completedQuizzes = 8}) {
  return UserProgress(
    userId: 'user-1',
    displayName: 'PelajarPA',
    email: 'student@example.com',
    semesterLabel: 'Semester 1',
    joinedAt: DateTime(2026, 1, 10),
    totalXp: totalXp,
    weeklyXp: totalXp,
    monthlyXp: 6540,
    completedQuizzes: completedQuizzes,
    totalCorrectAnswers: 122,
    totalQuizQuestions: 160,
    highestScore: 82,
    completedTopics: 3,
    totalTopics: 7,
    currentStreakDays: 4,
    bestStreakDays: 9,
    weeklyAnsweredQuestions: List<int>.unmodifiable([
      12,
      18,
      8,
      24,
      20,
      30,
      16,
    ]),
  );
}

QuizResult _createResult() {
  final question = QuizQuestion(
    id: 'q1',
    topicId: 'topic-s1-02',
    questionText: 'Apakah maksud negara berdaulat?',
    options: const ['Bebas mentadbir', 'Dikawal kuasa luar'],
    correctOptionIndex: 0,
    explanation: 'Negara berdaulat bebas mentadbir.',
  );

  return QuizResult(
    topicId: 'topic-s1-02',
    topicCode: 'S1-02',
    topicTitle: 'Negara Berdaulat',
    mode: QuizMode.practice,
    questions: [question],
    selectedAnswers: const {'q1': 0},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: 80,
    elapsedTime: const Duration(seconds: 30),
    autoSubmitted: false,
  );
}

void main() {
  test('memuatkan progress daripada repository', () async {
    final repository = _FakeUserProgressRepository(progress: _createProgress());

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    await controller.initialize();

    final state = container.read(userProgressControllerProvider);

    expect(state.userId, 'user-1');

    expect(state.totalXp, 1820);

    expect(state.completedQuizzes, 8);

    expect(repository.loadCallCount, 1);
  });

  test('mengemas kini nama paparan', () async {
    final repository = _FakeUserProgressRepository(progress: _createProgress());

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    await controller.initialize();

    final errorMessage = await controller.updateDisplayName('Welljoel Walter');

    expect(errorMessage, isNull);

    expect(
      container.read(userProgressControllerProvider).displayName,
      'Welljoel Walter',
    );

    expect(repository.progress.displayName, 'Welljoel Walter');

    expect(repository.saveCallCount, 1);
  });

  test('server result mengambil semula nilai server tanpa double XP', () async {
    final repository = _FakeUserProgressRepository(progress: _createProgress());

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    await controller.initialize();

    repository.progress = repository.progress.copyWith(
      totalXp: 1900,
      weeklyXp: 1900,
      completedQuizzes: 9,
    );

    await controller.recordServerQuizResult(
      result: _createResult(),
      earnedXp: 80,
    );

    final state = container.read(userProgressControllerProvider);

    expect(state.totalXp, 1900);

    expect(state.completedQuizzes, 9);

    expect(repository.loadCallCount, 2);
  });

  test('reset progress melalui repository server', () async {
    final repository = _FakeUserProgressRepository(progress: _createProgress());

    final container = ProviderContainer(
      overrides: [userProgressRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(userProgressControllerProvider.notifier);

    await controller.initialize();

    await controller.clearLocalProgress();

    final state = container.read(userProgressControllerProvider);

    expect(repository.clearCallCount, 1);

    expect(state.totalXp, 0);

    expect(state.completedQuizzes, 0);
  });
}
