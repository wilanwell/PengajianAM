import '../../domain/entities/quiz_draft.dart';
import '../../domain/repositories/quiz_draft_repository.dart';

class QuizDraftPersistenceCoordinator {
  QuizDraftPersistenceCoordinator(this._repository);

  final QuizDraftRepository _repository;

  Future<void> _operationQueue = Future<void>.value();

  Future<void> waitForPendingOperations() {
    return _operationQueue;
  }

  Future<void> saveSafely({
    required String? ownerUserId,
    required QuizDraft? draft,
  }) async {
    if (ownerUserId == null || draft == null) {
      return;
    }

    try {
      await _repository.saveDraft(ownerUserId: ownerUserId, draft: draft);
    } catch (_) {
      /*
       * Kegagalan autosave tidak menghentikan
       * sesi kuiz atau proses keluar.
       */
    }
  }

  void queueSave({required String? ownerUserId, required QuizDraft? draft}) {
    if (ownerUserId == null || draft == null) {
      return;
    }

    /*
     * Owner ID dan snapshot sudah ditentukan
     * sebelum operasi dimasukkan ke queue.
     *
     * Ini mengelakkan pertukaran akaun
     * menukar pemilik save yang telah beratur.
     */
    _operationQueue = _operationQueue.then((_) async {
      try {
        await _repository.saveDraft(ownerUserId: ownerUserId, draft: draft);
      } catch (_) {
        /*
         * Queue diteruskan walaupun satu
         * operasi autosave gagal.
         */
      }
    });
  }

  Future<void> deleteSafely({required String? ownerUserId}) async {
    if (ownerUserId == null) {
      return;
    }

    try {
      await _operationQueue;

      await _repository.deleteDraft(ownerUserId: ownerUserId);
    } catch (_) {
      /*
       * Kegagalan operasi draft tidak
       * membatalkan submission atau keluar.
       */
    }
  }
}
