import '../entities/quiz_draft.dart';

abstract interface class QuizDraftRepository {
  Future<QuizDraft?> loadDraft({required String ownerUserId});

  Future<void> saveDraft({
    required String ownerUserId,
    required QuizDraft draft,
  });

  Future<void> deleteDraft({required String ownerUserId});
}
