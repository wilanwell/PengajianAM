import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session.dart';
import '../../domain/entities/quiz_session_source.dart';
import 'quiz_session_timing_coordinator.dart';

enum QuizSessionStartRejectionReason { emptyQuestions, sourceMismatch }

final class QuizSessionStartResolution {
  const QuizSessionStartResolution.accepted(this.timing)
    : rejectionReason = null;

  const QuizSessionStartResolution.rejected(this.rejectionReason)
    : timing = null;

  final QuizSessionTimingResolution? timing;
  final QuizSessionStartRejectionReason? rejectionReason;

  bool get isAccepted {
    return rejectionReason == null;
  }
}

abstract final class QuizSessionStartCoordinator {
  static QuizSessionStartResolution resolve({
    required QuizSession session,
    required QuizMode requestedMode,
    required QuizSessionSource expectedSource,
    required DateTime localNow,
  }) {
    /*
     * Response tanpa soalan tidak boleh
     * digunakan sebagai sesi kuiz aktif.
     *
     * UI message kekal menjadi tanggungjawab
     * controller kerana Standard Quiz dan
     * Mistake Review menggunakan mesej
     * kosong yang berbeza.
     */
    if (session.questions.isEmpty) {
      return const QuizSessionStartResolution.rejected(
        QuizSessionStartRejectionReason.emptyQuestions,
      );
    }

    /*
     * Source daripada server mesti sama
     * dengan flow yang diminta oleh client.
     *
     * Contohnya startQuiz() tidak boleh
     * menerima mistakeReview session.
     */
    if (session.source != expectedSource) {
      return const QuizSessionStartResolution.rejected(
        QuizSessionStartRejectionReason.sourceMismatch,
      );
    }

    final timing = QuizSessionTimingCoordinator.resolveNewSessionTiming(
      session: session,
      requestedMode: requestedMode,
      localNow: localNow,
    );

    return QuizSessionStartResolution.accepted(timing);
  }
}
