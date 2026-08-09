import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/quiz_session_validation.dart';

final class QuizSessionTimingResolution {
  const QuizSessionTimingResolution({
    required this.startedAt,
    required this.examDeadlineAt,
    required this.remainingSeconds,
    required this.sessionExpiresAt,
  });

  final DateTime startedAt;
  final DateTime? examDeadlineAt;
  final int? remainingSeconds;
  final DateTime sessionExpiresAt;
}

abstract final class QuizSessionTimingCoordinator {
  static QuizSessionTimingResolution resolveNewSessionTiming({
    required QuizSession session,
    required QuizMode requestedMode,
    required DateTime localNow,
  }) {
    /*
     * Dalam production v2, serverTime dan
     * createdAt datang daripada server.
     *
     * localNow dikekalkan sebagai fallback
     * untuk fake repository lama dalam test.
     */
    final serverTime = session.serverTime ?? localNow;

    final startedAt = session.createdAt ?? serverTime;

    final hasServerTiming =
        session.serverTime != null && session.createdAt != null;

    /*
     * Exam Mode mesti mengutamakan deadline
     * daripada server.
     *
     * expiresAt bagi response v2 juga ialah
     * effective Exam Mode deadline.
     *
     * Pengiraan 90 saat setiap soalan hanya
     * fallback untuk fake repository lama.
     */
    final examDeadlineAt = requestedMode == QuizMode.exam
        ? (session.examDeadlineAt ??
              (hasServerTiming
                  ? session.expiresAt
                  : startedAt.add(
                      Duration(seconds: session.questions.length * 90),
                    )))
        : null;

    final remainingSeconds = examDeadlineAt == null
        ? null
        : remainingSecondsBetween(
            deadline: examDeadlineAt,
            currentTime: serverTime,
          );

    return QuizSessionTimingResolution(
      startedAt: startedAt,
      examDeadlineAt: examDeadlineAt,
      remainingSeconds: remainingSeconds,
      sessionExpiresAt: session.expiresAt,
    );
  }

  static QuizSessionTimingResolution resolveRestoredSessionTiming({
    required QuizDraft draft,
    required QuizSessionValidation validation,
  }) {
    /*
     * createdAt dan expiresAt daripada server
     * menjadi autoriti apabila tersedia.
     */
    final startedAt = validation.createdAt ?? draft.startedAt;

    final serverExpiresAt = validation.expiresAt ?? draft.sessionExpiresAt;

    DateTime? examDeadlineAt;

    if (draft.mode == QuizMode.exam) {
      final draftDeadline = draft.examDeadlineAt;

      /*
       * Data draft tidak dibenarkan
       * memanjangkan deadline server.
       *
       * Deadline draft yang lebih awal masih
       * dikekalkan.
       */
      if (draftDeadline != null && draftDeadline.isBefore(serverExpiresAt)) {
        examDeadlineAt = draftDeadline;
      } else {
        examDeadlineAt = serverExpiresAt;
      }
    }

    final remainingSeconds = examDeadlineAt == null
        ? null
        : remainingSecondsBetween(
            deadline: examDeadlineAt,
            currentTime: validation.serverTime,
          );

    return QuizSessionTimingResolution(
      startedAt: startedAt,
      examDeadlineAt: examDeadlineAt,
      remainingSeconds: remainingSeconds,
      sessionExpiresAt: serverExpiresAt,
    );
  }

  static int remainingSecondsBetween({
    required DateTime deadline,
    required DateTime currentTime,
  }) {
    final remainingMilliseconds = deadline
        .difference(currentTime)
        .inMilliseconds;

    if (remainingMilliseconds <= 0) {
      return 0;
    }

    /*
     * Ceiling digunakan supaya baki
     * 1–999 ms masih dikira sebagai 1 saat.
     */
    return (remainingMilliseconds + 999) ~/ 1000;
  }
}
