import '../../domain/entities/quiz_session_source.dart';
import '../../domain/entities/quiz_submission.dart';

typedef QuizSubmissionSyncAction =
    Future<void> Function(QuizSubmission submission);

abstract final class QuizSubmissionSyncCoordinator {
  static Future<void> synchronize({
    required QuizSubmission submission,
    required QuizSessionSource source,
    required void Function() invalidateMistakeBook,
    required Future<void> Function() deleteDraft,
    required QuizSubmissionSyncAction syncProgress,
    required QuizSubmissionSyncAction syncHistory,
  }) async {
    /*
     * Submission sebenar telah berjaya pada
     * server sebelum method ini dipanggil.
     *
     * Cache Mistake Book perlu dianggap stale
     * untuk semua jenis sesi termasuk
     * mistake review.
     */
    invalidateMistakeBook();

    /*
     * Draft tidak diperlukan lagi selepas
     * server menerima submission.
     *
     * Callback controller menggunakan operasi
     * delete yang sudah bersifat safe.
     */
    await deleteDraft();

    /*
     * Mistake Review tidak memberi XP dan
     * tidak dimasukkan ke sejarah kuiz
     * standard.
     */
    if (source != QuizSessionSource.standard) {
      return;
    }

    try {
      await syncProgress(submission);
    } catch (_) {
      /*
       * Progress sebenar sudah disimpan oleh
       * transaction server.
       *
       * Kegagalan refresh local tidak boleh
       * menukar submission berjaya kepada gagal.
       */
    }

    try {
      await syncHistory(submission);
    } catch (_) {
      /*
       * Attempt sebenar sudah disimpan pada
       * server.
       *
       * Kegagalan local history synchronization
       * juga tidak membatalkan submission.
       */
    }
  }
}
