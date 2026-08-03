import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_session_validation.dart';
import '../controllers/quiz_session_state.dart';

abstract final class QuizSessionDraftCoordinator {
  static bool isValidationCompatible({
    required QuizDraft draft,
    required QuizSessionValidation validation,
  }) {
    if (!validation.isActive) {
      return false;
    }

    if (validation.topicId != draft.topicId) {
      return false;
    }

    if (validation.mode != draft.mode) {
      return false;
    }

    if (validation.source != draft.source) {
      return false;
    }

    if (validation.questionCount != draft.questionCount) {
      return false;
    }

    return true;
  }

  static QuizDraft? createSnapshot({
    required QuizSessionState state,
    required DateTime? startedAt,
    required DateTime? examDeadlineAt,
    required DateTime savedAt,
  }) {
    if (state.status != QuizSessionStatus.ready) {
      return null;
    }

    final sessionId = state.sessionId;
    final topicId = state.topicId;
    final sessionExpiresAt = state.sessionExpiresAt;

    if (sessionId == null ||
        sessionId.trim().isEmpty ||
        topicId == null ||
        topicId.trim().isEmpty ||
        startedAt == null ||
        sessionExpiresAt == null ||
        state.questions.isEmpty) {
      return null;
    }

    try {
      return QuizDraft(
        sessionId: sessionId,
        topicId: topicId,
        mode: state.mode,
        source: state.source,
        questionCount: state.questions.length,
        questions: List.unmodifiable(state.questions),
        currentQuestionIndex: state.currentQuestionIndex,
        selectedAnswers: Map<String, int>.unmodifiable(state.selectedAnswers),
        flaggedQuestionIds: Set<String>.unmodifiable(state.flaggedQuestionIds),
        startedAt: startedAt,
        sessionExpiresAt: sessionExpiresAt,
        examDeadlineAt: examDeadlineAt,
        savedAt: savedAt,
      );
    } on FormatException {
      return null;
    }
  }
}
