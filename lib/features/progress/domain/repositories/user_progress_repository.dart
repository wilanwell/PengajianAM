import '../entities/user_progress.dart';

abstract interface class UserProgressRepository {
  Future<UserProgress?> loadProgress();

  Future<void> saveProgress(UserProgress progress);

  Future<void> clearProgress();
}
