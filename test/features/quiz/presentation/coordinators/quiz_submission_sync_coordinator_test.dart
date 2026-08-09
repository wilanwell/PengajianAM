import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_result.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_submission.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_submission_sync_coordinator.dart';

void main() {
  test(
    'standard submission menjalankan semua synchronization mengikut urutan',
    () async {
      final submission = _createSubmission(source: QuizSessionSource.standard);

      final operations = <String>[];

      await QuizSubmissionSyncCoordinator.synchronize(
        submission: submission,
        source: QuizSessionSource.standard,
        invalidateMistakeBook: () {
          operations.add('invalidate');
        },
        deleteDraft: () async {
          operations.add('delete-draft');
        },
        syncProgress: (receivedSubmission) async {
          expect(receivedSubmission, same(submission));

          operations.add('progress');
        },
        syncHistory: (receivedSubmission) async {
          expect(receivedSubmission, same(submission));

          operations.add('history');
        },
      );

      expect(operations, ['invalidate', 'delete-draft', 'progress', 'history']);
    },
  );

  test('kegagalan progress tidak menghalang history synchronization', () async {
    final submission = _createSubmission(source: QuizSessionSource.standard);

    var invalidateCount = 0;
    var deleteCount = 0;
    var progressCount = 0;
    var historyCount = 0;

    await QuizSubmissionSyncCoordinator.synchronize(
      submission: submission,
      source: QuizSessionSource.standard,
      invalidateMistakeBook: () {
        invalidateCount++;
      },
      deleteDraft: () async {
        deleteCount++;
      },
      syncProgress: (_) async {
        progressCount++;

        throw StateError('Progress synchronization sengaja digagalkan.');
      },
      syncHistory: (_) async {
        historyCount++;
      },
    );

    expect(invalidateCount, 1);

    expect(deleteCount, 1);

    expect(progressCount, 1);

    /*
       * Walaupun Progress gagal, History
       * masih perlu diteruskan.
       */
    expect(historyCount, 1);
  });

  test('kegagalan history tidak membatalkan server success', () async {
    final submission = _createSubmission(source: QuizSessionSource.standard);

    var progressCount = 0;
    var historyCount = 0;

    await expectLater(
      QuizSubmissionSyncCoordinator.synchronize(
        submission: submission,
        source: QuizSessionSource.standard,
        invalidateMistakeBook: () {},
        deleteDraft: () async {},
        syncProgress: (_) async {
          progressCount++;
        },
        syncHistory: (_) async {
          historyCount++;

          throw StateError('History synchronization sengaja digagalkan.');
        },
      ),
      completes,
    );

    expect(progressCount, 1);

    expect(historyCount, 1);
  });

  test('mistake review skip progress dan history synchronization', () async {
    final submission = _createSubmission(
      source: QuizSessionSource.mistakeReview,
    );

    var invalidateCount = 0;
    var deleteCount = 0;
    var progressCount = 0;
    var historyCount = 0;

    await QuizSubmissionSyncCoordinator.synchronize(
      submission: submission,
      source: QuizSessionSource.mistakeReview,
      invalidateMistakeBook: () {
        invalidateCount++;
      },
      deleteDraft: () async {
        deleteCount++;
      },
      syncProgress: (_) async {
        progressCount++;
      },
      syncHistory: (_) async {
        historyCount++;
      },
    );

    expect(invalidateCount, 1);

    expect(deleteCount, 1);

    expect(progressCount, 0);

    expect(historyCount, 0);
  });
}

QuizSubmission _createSubmission({required QuizSessionSource source}) {
  final result = QuizResult(
    topicId: 'topic-sync',
    topicCode: 'S1-SYNC',
    topicTitle: 'Topik Sync Test',
    mode: QuizMode.practice,
    sessionSource: source,
    questions: [
      QuizQuestion(
        id: 'sync-q1',
        topicId: 'topic-sync',
        questionText: 'Soalan pertama',
        options: const ['Pilihan A', 'Pilihan B'],
        correctOptionIndex: 0,
        explanation: 'Pilihan A tepat.',
        shuffleOptions: false,
      ),
      QuizQuestion(
        id: 'sync-q2',
        topicId: 'topic-sync',
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B'],
        correctOptionIndex: 1,
        explanation: 'Pilihan B tepat.',
        shuffleOptions: false,
      ),
    ],
    selectedAnswers: const {'sync-q1': 0},
    correctAnswers: 1,
    answeredQuestions: 1,
    earnedXp: source == QuizSessionSource.standard ? 30 : 0,
    elapsedTime: const Duration(minutes: 2),
    autoSubmitted: false,
  );

  return QuizSubmission(
    attemptId: '00000000-0000-0000-0000-000000000901',
    earnedXp: source == QuizSessionSource.standard ? 30 : 0,
    completedAt: DateTime.utc(2026, 8, 9, 7),
    result: result,
  );
}
