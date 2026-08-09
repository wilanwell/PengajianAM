import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_mode.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_question.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/domain/entities/quiz_session_source.dart';
import 'package:pengajian_am_stpm_objektif/features/quiz/presentation/coordinators/quiz_session_start_coordinator.dart';

void main() {
  group('QuizSessionStartCoordinator.resolve', () {
    test('menolak sesi tanpa soalan', () {
      final localNow = DateTime.utc(2026, 8, 9, 10);

      final session = QuizSession(
        sessionId: '00000000-0000-0000-0000-000000002001',
        topicId: 'topic-empty',
        mode: QuizMode.practice,
        source: QuizSessionSource.standard,
        questionCount: 10,
        expiresAt: localNow.add(const Duration(hours: 2)),
        questions: const [],
      );

      final resolution = QuizSessionStartCoordinator.resolve(
        session: session,
        requestedMode: QuizMode.practice,
        expectedSource: QuizSessionSource.standard,
        localNow: localNow,
      );

      expect(resolution.isAccepted, isFalse);

      expect(
        resolution.rejectionReason,
        QuizSessionStartRejectionReason.emptyQuestions,
      );

      expect(resolution.timing, isNull);
    });

    test('menolak sesi apabila source server tidak sepadan', () {
      final localNow = DateTime.utc(2026, 8, 9, 10);

      final session = _createSession(
        mode: QuizMode.practice,
        source: QuizSessionSource.mistakeReview,
        serverTime: localNow,
        createdAt: localNow,
        expiresAt: localNow.add(const Duration(hours: 2)),
      );

      final resolution = QuizSessionStartCoordinator.resolve(
        session: session,
        requestedMode: QuizMode.practice,
        expectedSource: QuizSessionSource.standard,
        localNow: localNow,
      );

      expect(resolution.isAccepted, isFalse);

      expect(
        resolution.rejectionReason,
        QuizSessionStartRejectionReason.sourceMismatch,
      );

      expect(resolution.timing, isNull);
    });

    test('menerima Practice session tanpa countdown', () {
      final serverTime = DateTime.utc(2026, 8, 9, 10);

      final createdAt = DateTime.utc(2026, 8, 9, 9, 55);

      final expiresAt = DateTime.utc(2026, 8, 9, 12);

      final session = _createSession(
        mode: QuizMode.practice,
        source: QuizSessionSource.standard,
        serverTime: serverTime,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

      final resolution = QuizSessionStartCoordinator.resolve(
        session: session,
        requestedMode: QuizMode.practice,
        expectedSource: QuizSessionSource.standard,
        localNow: DateTime.utc(2030, 1, 1),
      );

      expect(resolution.isAccepted, isTrue);

      expect(resolution.rejectionReason, isNull);

      final timing = resolution.timing;

      expect(timing, isNotNull);

      expect(timing?.startedAt, createdAt);

      expect(timing?.examDeadlineAt, isNull);

      expect(timing?.remainingSeconds, isNull);

      expect(timing?.sessionExpiresAt, expiresAt);
    });

    test('menerima Exam session dan menggunakan deadline server', () {
      final serverTime = DateTime.utc(2026, 8, 9, 10);

      final createdAt = DateTime.utc(2026, 8, 9, 9, 55);

      final examDeadlineAt = DateTime.utc(2026, 8, 9, 10, 5);

      final session = _createSession(
        mode: QuizMode.exam,
        source: QuizSessionSource.standard,
        serverTime: serverTime,
        createdAt: createdAt,
        expiresAt: examDeadlineAt,
        examDeadlineAt: examDeadlineAt,
      );

      final resolution = QuizSessionStartCoordinator.resolve(
        session: session,
        requestedMode: QuizMode.exam,
        expectedSource: QuizSessionSource.standard,
        localNow: DateTime.utc(2030, 1, 1),
      );

      expect(resolution.isAccepted, isTrue);

      expect(resolution.rejectionReason, isNull);

      final timing = resolution.timing;

      expect(timing, isNotNull);

      expect(timing?.startedAt, createdAt);

      expect(timing?.examDeadlineAt, examDeadlineAt);

      expect(timing?.remainingSeconds, 300);

      expect(timing?.sessionExpiresAt, examDeadlineAt);
    });
  });
}

QuizSession _createSession({
  required QuizMode mode,
  required QuizSessionSource source,
  required DateTime serverTime,
  required DateTime createdAt,
  required DateTime expiresAt,
  DateTime? examDeadlineAt,
}) {
  return QuizSession(
    sessionId: '00000000-0000-0000-0000-000000002002',
    topicId: 'topic-start',
    mode: mode,
    source: source,
    questionCount: 2,
    createdAt: createdAt,
    serverTime: serverTime,
    expiresAt: expiresAt,
    examDeadlineAt: examDeadlineAt,
    questions: [
      QuizSessionQuestion(
        id: 'coordinator-q1',
        topicId: 'topic-start',
        questionText: 'Soalan pertama',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 1,
      ),
      QuizSessionQuestion(
        id: 'coordinator-q2',
        topicId: 'topic-start',
        questionText: 'Soalan kedua',
        options: const ['Pilihan A', 'Pilihan B'],
        questionOrder: 2,
      ),
    ],
  );
}
