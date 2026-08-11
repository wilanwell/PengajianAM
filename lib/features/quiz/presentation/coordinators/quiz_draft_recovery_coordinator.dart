import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_session_validation.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../../domain/exceptions/quiz_failure.dart';
import '../../domain/repositories/quiz_draft_repository.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_session_draft_coordinator.dart';

class QuizDraftRecoveryCoordinator {
  QuizDraftRecoveryCoordinator(this._quizRepository, this._draftRepository);

  final QuizRepository _quizRepository;
  final QuizDraftRepository _draftRepository;

  Future<QuizDraft?> loadAvailableDraft({required String ownerUserId}) async {
    final QuizDraft? draft;

    try {
      draft = await _draftRepository.loadDraft(ownerUserId: ownerUserId);
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure(
        'Draft kuiz tidak dapat dibaca '
        'daripada peranti.',
      );
    }

    /*
     * Null bermaksud pengguna memang tidak
     * mempunyai draft pada peranti.
     */
    if (draft == null) {
      return null;
    }

    final validation = await validateResumableDraft(
      ownerUserId: ownerUserId,
      draft: draft,
    );

    if (validation == null) {
      return null;
    }

    return draft;
  }

  Future<QuizSessionValidation?> validateResumableDraft({
    required String ownerUserId,
    required QuizDraft draft,
  }) async {
    try {
      final validation = await _quizRepository.validateQuizSession(
        sessionId: draft.sessionId,
      );

      final isCompatible = QuizSessionDraftCoordinator.isValidationCompatible(
        draft: draft,
        validation: validation,
      );

      if (!isCompatible) {
        /*
         * Sesi server sudah tidak boleh
         * disambung atau metadata session
         * tidak lagi sepadan dengan draft.
         */
        await _draftRepository.deleteDraft(ownerUserId: ownerUserId);

        return null;
      }

      return validation;
    } on QuizFailure catch (error) {
      /*
       * Kegagalan server/rangkaian tidak
       * memadamkan draft pengguna.
       */
      throw QuizDraftFailure(
        '${error.message} '
        'Sesi tersimpan anda masih selamat '
        'pada peranti.',
      );
    } on QuizDraftFailure {
      rethrow;
    } catch (_) {
      throw const QuizDraftFailure(
        'Sesi kuiz tersimpan tidak dapat '
        'disahkan sekarang. Draft anda masih '
        'selamat pada peranti.',
      );
    }
  }
}
