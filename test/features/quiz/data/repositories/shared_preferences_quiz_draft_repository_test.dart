import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/data/repositories/shared_preferences_quiz_draft_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:shared_preferences/shared_preferences.dart';

QuizDraft _createDraft({QuizMode mode = QuizMode.exam}) {
  final startedAt = DateTime.utc(2026, 7, 17, 10);

  return QuizDraft(
    sessionId: '00000000-0000-0000-0000-000000000001',
    topicId: 'topic-s1-03',
    mode: mode,
    questionCount: 2,
    questions: [
      QuizSessionQuestion(
        id: 'q1',
        topicId: 'topic-s1-03',
        questionText: 'Soalan pertama',
        options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
        questionOrder: 1,
      ),
      QuizSessionQuestion(
        id: 'q2',
        topicId: 'topic-s1-03',
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B', 'Pilihan C', 'Pilihan D'],
        questionOrder: 2,
      ),
    ],
    currentQuestionIndex: 1,
    selectedAnswers: const {'q1': 2},
    flaggedQuestionIds: const {'q2'},
    startedAt: startedAt,
    sessionExpiresAt: startedAt.add(const Duration(hours: 2)),
    examDeadlineAt: mode == QuizMode.exam
        ? startedAt.add(const Duration(minutes: 3))
        : null,
    savedAt: startedAt.add(const Duration(seconds: 45)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('menyimpan dan memuatkan draft kuiz', () async {
    const repository = SharedPreferencesQuizDraftRepository();

    final originalDraft = _createDraft();

    await repository.saveDraft(ownerUserId: 'user-1', draft: originalDraft);

    final loadedDraft = await repository.loadDraft(ownerUserId: 'user-1');

    expect(loadedDraft, isNotNull);

    expect(loadedDraft!.sessionId, originalDraft.sessionId);

    expect(loadedDraft.topicId, 'topic-s1-03');

    expect(loadedDraft.mode, QuizMode.exam);

    expect(loadedDraft.questions, hasLength(2));

    expect(loadedDraft.currentQuestionIndex, 1);

    expect(loadedDraft.selectedAnswers, {'q1': 2});

    expect(loadedDraft.flaggedQuestionIds, {'q2'});

    expect(loadedDraft.examDeadlineAt, originalDraft.examDeadlineAt);

    expect(
      loadedDraft.remainingSecondsAt(
        originalDraft.startedAt.add(const Duration(minutes: 1)),
      ),
      120,
    );
  });

  test('mengasingkan draft mengikut pengguna', () async {
    const repository = SharedPreferencesQuizDraftRepository();

    await repository.saveDraft(ownerUserId: 'user-1', draft: _createDraft());

    final firstUserDraft = await repository.loadDraft(ownerUserId: 'user-1');

    final secondUserDraft = await repository.loadDraft(ownerUserId: 'user-2');

    expect(firstUserDraft, isNotNull);

    expect(secondUserDraft, isNull);
  });

  test('memadam draft pengguna', () async {
    const repository = SharedPreferencesQuizDraftRepository();

    await repository.saveDraft(
      ownerUserId: 'user-1',
      draft: _createDraft(mode: QuizMode.practice),
    );

    await repository.deleteDraft(ownerUserId: 'user-1');

    final loadedDraft = await repository.loadDraft(ownerUserId: 'user-1');

    expect(loadedDraft, isNull);
  });

  test('menghapuskan data draft yang rosak', () async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('quiz_draft_v1_user-1', '{invalid-json');

    const repository = SharedPreferencesQuizDraftRepository();

    final loadedDraft = await repository.loadDraft(ownerUserId: 'user-1');

    expect(loadedDraft, isNull);

    expect(preferences.containsKey('quiz_draft_v1_user-1'), isFalse);
  });
}
