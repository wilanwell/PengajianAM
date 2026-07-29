import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mistake_book/presentation/controllers/mistake_book_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';

typedef ProfileLoadAction = Future<void> Function(bool forceRefresh);

typedef ProfileStatusReader = ProfileStatus Function();

typedef ProfileResetAction = void Function();

final profileLoadCoordinatorProvider = Provider<ProfileLoadCoordinator>((ref) {
  return ProfileLoadCoordinator(
    loadProfile: (forceRefresh) {
      final controller = ref.read(profileControllerProvider.notifier);

      if (forceRefresh) {
        return controller.refreshProfile();
      }

      return controller.loadProfile();
    },
    loadMistakeBook: (forceRefresh) {
      final controller = ref.read(mistakeBookControllerProvider.notifier);

      if (forceRefresh) {
        return controller.refreshMistakeBook();
      }

      return controller.loadMistakeBook();
    },
    readProfileStatus: () {
      return ref.read(profileControllerProvider).status;
    },
    resetProfile: () {
      ref.read(profileControllerProvider.notifier).reset();
    },
  );
});

class ProfileLoadCoordinator {
  const ProfileLoadCoordinator({
    required this.loadProfile,
    required this.loadMistakeBook,
    required this.readProfileStatus,
    required this.resetProfile,
  });

  final ProfileLoadAction loadProfile;

  final ProfileLoadAction loadMistakeBook;

  final ProfileStatusReader readProfileStatus;

  final ProfileResetAction resetProfile;

  Future<void> loadInitial() {
    return _loadAll(forceRefresh: false);
  }

  Future<void> refreshAll() {
    return _loadAll(forceRefresh: true);
  }

  Future<void> retryProfile() {
    return loadProfile(true);
  }

  Future<void> retryMistakeBook() {
    return loadMistakeBook(true);
  }

  Future<void> synchronizeAfterProgressChange({
    required bool isLoggingOut,
  }) async {
    if (isLoggingOut) {
      return;
    }

    if (readProfileStatus() == ProfileStatus.loading) {
      return;
    }

    resetProfile();

    await loadProfile(false);
  }

  Future<void> _loadAll({required bool forceRefresh}) async {
    await Future.wait<void>([
      loadProfile(forceRefresh),
      loadMistakeBook(forceRefresh),
    ]);
  }
}
