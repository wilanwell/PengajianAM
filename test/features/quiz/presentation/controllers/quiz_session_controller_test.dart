import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/entities/user_progress.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/progress/presentation/controllers/user_progress_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_history_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/controllers/quiz_history_controller.dart';
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

class _FakeUserProgressRepository implements UserProgressRepository {
  UserProgress? storedProgress;

  @override
  Future<UserProgress?> loadProgress() async {
    return storedProgress;
  }

  @override
  Future<void> saveProgress(UserProgress progress) async {
    storedProgress = progress;
  }

  @override
  Future<void> clearProgress() async {
    storedProgress = null;
  }
}

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
  List<QuizAttempt> attempts = [];

  @override
  Future<List<QuizAttempt>> loadAttempts() async {
    return List<QuizAttempt>.unmodifiable(attempts);
  }

  @override
  Future<void> saveAttempts(List<QuizAttempt> attempts) async {
    this.attempts = List<QuizAttempt>.from(attempts);
  }

  @override
  Future<void> clearAttempts() async {
    attempts = [];
  }
}

void main() {
  test('memulakan, menjawab, menghantar dan menyimpan kuiz', () async {
    final progressRepository = _FakeUserProgressRepository();

    final historyRepository = _FakeQuizHistoryRepository();

    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(const _FakeQuizRepository()),
        userProgressRepositoryProvider.overrideWithValue(progressRepository),
        quizHistoryRepositoryProvider.overrideWithValue(historyRepository),
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

    /*
       * Soalan dan pilihan jawapan telah dirandomkan.
       * Oleh itu, test tidak boleh menganggap jawapan betul
       * sentiasa berada pada index 0.
       */

    var currentQuestion = state.currentQuestion;

    expect(currentQuestion, isNotNull);

    // Jawab soalan pertama dengan jawapan yang betul.
    controller.selectAnswer(currentQuestion!.correctOptionIndex);

    // Tandakan soalan pertama.
    controller.toggleFlagCurrentQuestion();

    controller.nextQuestion();

    state = container.read(quizSessionControllerProvider);

    currentQuestion = state.currentQuestion;

    expect(currentQuestion, isNotNull);

    /*
       * Pilih jawapan yang salah untuk soalan kedua.
       * Formula ini memilih index selepas correctOptionIndex.
       */
    final incorrectOptionIndex =
        (currentQuestion!.correctOptionIndex + 1) %
        currentQuestion.options.length;

    controller.selectAnswer(incorrectOptionIndex);

    await controller.submitQuiz();

    state = container.read(quizSessionControllerProvider);

    expect(state.status, QuizSessionStatus.completed);

    expect(state.result, isNotNull);

    // Satu jawapan betul dan satu jawapan salah.
    expect(state.result!.correctAnswers, 1);

    expect(state.result!.answeredQuestions, 2);

    expect(state.result!.totalQuestions, 2);

    // Kedua-dua soalan dijawab.
    expect(state.result!.unansweredQuestions, 0);

    // Progress pengguna berjaya disimpan.
    expect(progressRepository.storedProgress, isNotNull);

    /*
       * XP:
       * 1 jawapan betul × 10 XP = 10 XP
       * Semua soalan dijawab = 20 XP
       * Jumlah = 30 XP
       */
    expect(progressRepository.storedProgress!.totalXp, 1850);

    // Sejarah kuiz berjaya disimpan.
    expect(historyRepository.attempts, hasLength(1));

    expect(historyRepository.attempts.first.earnedXp, 30);

    expect(historyRepository.attempts.first.result.correctAnswers, 1);

    expect(historyRepository.attempts.first.result.answeredQuestions, 2);
  });
}
