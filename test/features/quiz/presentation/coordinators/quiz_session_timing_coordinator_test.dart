import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_draft.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_validation.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_session_timing_coordinator.dart';

void main() {
  group('resolveNewSessionTiming', () {
    test('Practice menggunakan createdAt server tanpa exam deadline', () {
      final createdAt = DateTime.utc(2026, 8, 9, 4, 0);

      final serverTime = DateTime.utc(2026, 8, 9, 4, 1);

      final expiresAt = DateTime.utc(2026, 8, 9, 5, 0);

      final session = QuizSession(
        sessionId: 'session-practice',
        topicId: 'topic-1',
        mode: QuizMode.practice,
        questionCount: 2,
        createdAt: createdAt,
        serverTime: serverTime,
        expiresAt: expiresAt,
        questions: _questions(),
      );

      final timing = QuizSessionTimingCoordinator.resolveNewSessionTiming(
        session: session,
        requestedMode: QuizMode.practice,
        localNow: DateTime.utc(2026, 8, 9, 10),
      );

      expect(timing.startedAt, createdAt);

      expect(timing.examDeadlineAt, isNull);

      expect(timing.remainingSeconds, isNull);

      expect(timing.sessionExpiresAt, expiresAt);
    });

    test('Exam mengutamakan exam deadline daripada server', () {
      final createdAt = DateTime.utc(2026, 8, 9, 4, 0);

      final serverTime = DateTime.utc(2026, 8, 9, 4, 2);

      final examDeadlineAt = DateTime.utc(2026, 8, 9, 4, 7);

      final session = QuizSession(
        sessionId: 'session-exam',
        topicId: 'topic-1',
        mode: QuizMode.exam,
        questionCount: 2,
        createdAt: createdAt,
        serverTime: serverTime,
        expiresAt: examDeadlineAt,
        examDeadlineAt: examDeadlineAt,
        questions: _questions(),
      );

      final timing = QuizSessionTimingCoordinator.resolveNewSessionTiming(
        session: session,
        requestedMode: QuizMode.exam,
        localNow: DateTime.utc(2026, 8, 9, 12),
      );

      expect(timing.startedAt, createdAt);

      expect(timing.examDeadlineAt, examDeadlineAt);

      expect(timing.remainingSeconds, 300);

      expect(timing.sessionExpiresAt, examDeadlineAt);
    });

    test('Exam fallback lama menggunakan 90 saat setiap soalan', () {
      final localNow = DateTime.utc(2026, 8, 9, 7, 0);

      final session = QuizSession(
        sessionId: 'legacy-exam',
        topicId: 'topic-1',
        mode: QuizMode.exam,
        questionCount: 2,
        expiresAt: localNow.add(const Duration(hours: 1)),
        questions: _questions(),
      );

      final timing = QuizSessionTimingCoordinator.resolveNewSessionTiming(
        session: session,
        requestedMode: QuizMode.exam,
        localNow: localNow,
      );

      expect(timing.startedAt, localNow);

      expect(timing.examDeadlineAt, localNow.add(const Duration(seconds: 180)));

      expect(timing.remainingSeconds, 180);
    });
  });

  group('remainingSecondsBetween', () {
    test('membulatkan baki milisaat ke atas', () {
      final currentTime = DateTime.utc(2026, 8, 9, 8, 0);

      final deadline = currentTime.add(const Duration(milliseconds: 1));

      final remaining = QuizSessionTimingCoordinator.remainingSecondsBetween(
        deadline: deadline,
        currentTime: currentTime,
      );

      expect(remaining, 1);
    });

    test('mengembalikan sifar apabila deadline telah tamat', () {
      final currentTime = DateTime.utc(2026, 8, 9, 8, 0);

      final remaining = QuizSessionTimingCoordinator.remainingSecondsBetween(
        deadline: currentTime.subtract(const Duration(seconds: 1)),
        currentTime: currentTime,
      );

      expect(remaining, 0);
    });
  });

  group('resolveRestoredSessionTiming', () {
    test('Exam tidak membenarkan draft memanjangkan server expiry', () {
      final serverTime = DateTime.utc(2026, 8, 9, 9, 0);

      final serverExpiresAt = DateTime.utc(2026, 8, 9, 9, 4);

      final longerDraftDeadline = DateTime.utc(2026, 8, 9, 9, 10);

      final draft = _examDraft(
        startedAt: DateTime.utc(2026, 8, 9, 8, 50),
        sessionExpiresAt: longerDraftDeadline,
        examDeadlineAt: longerDraftDeadline,
      );

      final validation = QuizSessionValidation(
        sessionId: draft.sessionId,
        status: QuizSessionServerStatus.active,
        canResume: true,
        serverTime: serverTime,
        topicId: draft.topicId,
        mode: draft.mode,
        source: draft.source,
        questionCount: draft.questionCount,
        createdAt: DateTime.utc(2026, 8, 9, 8, 52),
        expiresAt: serverExpiresAt,
      );

      final timing = QuizSessionTimingCoordinator.resolveRestoredSessionTiming(
        draft: draft,
        validation: validation,
      );

      expect(timing.startedAt, validation.createdAt);

      expect(timing.examDeadlineAt, serverExpiresAt);

      expect(timing.sessionExpiresAt, serverExpiresAt);

      expect(timing.remainingSeconds, 240);
    });

    test('Exam mengekalkan deadline draft yang lebih awal', () {
      final serverTime = DateTime.utc(2026, 8, 9, 10, 0);

      final serverExpiresAt = DateTime.utc(2026, 8, 9, 10, 10);

      final earlierDraftDeadline = DateTime.utc(2026, 8, 9, 10, 3);

      final draft = _examDraft(
        startedAt: DateTime.utc(2026, 8, 9, 9, 50),
        sessionExpiresAt: serverExpiresAt,
        examDeadlineAt: earlierDraftDeadline,
      );

      final validation = QuizSessionValidation(
        sessionId: draft.sessionId,
        status: QuizSessionServerStatus.active,
        canResume: true,
        serverTime: serverTime,
        topicId: draft.topicId,
        mode: draft.mode,
        source: draft.source,
        questionCount: draft.questionCount,
        createdAt: DateTime.utc(2026, 8, 9, 9, 52),
        expiresAt: serverExpiresAt,
      );

      final timing = QuizSessionTimingCoordinator.resolveRestoredSessionTiming(
        draft: draft,
        validation: validation,
      );

      expect(timing.examDeadlineAt, earlierDraftDeadline);

      expect(timing.sessionExpiresAt, serverExpiresAt);

      expect(timing.remainingSeconds, 180);
    });
  });
}

QuizDraft _examDraft({
  required DateTime startedAt,
  required DateTime sessionExpiresAt,
  required DateTime examDeadlineAt,
}) {
  return QuizDraft(
    sessionId: 'restored-session',
    topicId: 'topic-1',
    mode: QuizMode.exam,
    questionCount: 2,
    questions: _questions(),
    currentQuestionIndex: 0,
    selectedAnswers: const {},
    flaggedQuestionIds: const {},
    startedAt: startedAt,
    sessionExpiresAt: sessionExpiresAt,
    examDeadlineAt: examDeadlineAt,
    savedAt: startedAt.add(const Duration(minutes: 1)),
  );
}

List<QuizSessionQuestion> _questions() {
  return [
    QuizSessionQuestion(
      id: 'q1',
      topicId: 'topic-1',
      questionText: 'Soalan pertama',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 1,
    ),
    QuizSessionQuestion(
      id: 'q2',
      topicId: 'topic-1',
      questionText: 'Soalan kedua',
      options: const ['Pilihan A', 'Pilihan B'],
      questionOrder: 2,
    ),
  ];
}
