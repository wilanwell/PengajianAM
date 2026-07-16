import '../entities/user_progress.dart';

abstract interface class UserProgressRepository {
  Future<UserProgress?> loadProgress();

  /// Dalam Supabase implementation, method ini hanya
  /// mengemas kini data profil yang dibenarkan pengguna,
  /// terutamanya display name.
  Future<void> saveProgress(UserProgress progress);

  /// Reset progress melalui secure database RPC.
  Future<void> clearProgress();
}
