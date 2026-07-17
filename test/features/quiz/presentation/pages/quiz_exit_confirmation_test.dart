import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/repositories/quiz_draft_repository.dart';
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
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
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
  Future<QuizSessionValidation> validateQuizSession({
    required String sessionId,
  }) async {
    final now = DateTime.now();

    return QuizSessionValidation(
      sessionId: sessionId,
      status: QuizSessionServerStatus.active,
      canResume: true,
      serverTime: now,
      topicId: 'topic-1',
      mode: QuizMode.practice,
      questionCount: 1,
      createdAt: now.subtract(const Duration(minutes: 5)),
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }

  @override
  Future<QuizSubmission> submitQuiz({
    required String sessionId,
    required Map<String, int> selectedAnswers,
    required Duration elapsedTime,
    required bool autoSubmitted,
  }) {
    throw UnimplementedError(
      'Submission tidak digunakan dalam '
      'test keluar kuiz.',
    );
  }
}

class _FakeQuizDraftRepository implements QuizDraftRepository {
  QuizDraft? storedDraft;

  int saveCallCount = 0;
  int deleteCallCount = 0;
  int loadCallCount = 0;

  @override
  Future<QuizDraft?> loadDraft({required String ownerUserId}) async {
    loadCallCount++;

    return storedDraft;
  }

  @override
  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    saveCallCount++;
    storedDraft = draft;
  }

  @override
  Future<void> deleteDraft({required String ownerUserId}) async {
    deleteCallCount++;
    storedDraft = null;
  }
}

void main() {
  testWidgets('menyimpan, menyambung dan membuang sesi kuiz', (tester) async {
    final draftRepository = _FakeQuizDraftRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(const _FakeQuizRepository()),
          quizDraftRepositoryProvider.overrideWithValue(draftRepository),
          quizDraftOwnerIdProvider.overrideWithValue('test-user'),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Halaman Ujian')),
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
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
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) {
                                return const QuizQuestionPage(
                                  topicId: 'topic-1',
                                  mode: QuizMode.practice,
                                  questionCount: 1,
                                  resumeDraft: true,
                                );
                              },
                            ),
                          );
                        },
                        child: const Text('Sambung Kuiz'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Buka Kuiz'));

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

    // Kekal dalam kuiz.
    await tester.tap(find.text('Teruskan Kuiz'));

    await tester.pumpAndSettle();

    expect(find.text('Soalan ujian keluar kuiz'), findsOneWidget);

    // Keluar sambil mengekalkan draft.
    await tester.tap(find.byType(BackButton));

    await tester.pumpAndSettle();

    expect(find.text('Simpan & Keluar'), findsOneWidget);

    await tester.tap(find.text('Simpan & Keluar'));

    await tester.pumpAndSettle();

    expect(find.text('Halaman Ujian'), findsOneWidget);

    expect(draftRepository.storedDraft, isNotNull);

    expect(draftRepository.storedDraft!.selectedAnswers, {'q1': 0});

    // Pulihkan kuiz daripada draft.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sambung Kuiz'));

    await tester.pumpAndSettle();

    expect(find.text('Soalan ujian keluar kuiz'), findsOneWidget);

    expect(draftRepository.loadCallCount, greaterThanOrEqualTo(1));

    expect(draftRepository.storedDraft!.selectedAnswers, {'q1': 0});

    // Buang sesi sepenuhnya.
    await tester.tap(find.byType(BackButton));

    await tester.pumpAndSettle();

    expect(find.text('Buang Sesi'), findsOneWidget);

    await tester.tap(find.text('Buang Sesi'));

    await tester.pumpAndSettle();

    expect(find.text('Halaman Ujian'), findsOneWidget);

    expect(draftRepository.storedDraft, isNull);

    /*
       * Delete pertama berlaku sebelum kuiz
       * baharu dimulakan. Delete berikutnya
       * berlaku apabila sesi dibuang.
       */
    expect(draftRepository.deleteCallCount, greaterThanOrEqualTo(2));
  });
}
