import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/controllers/profile_state.dart';
import 'package:pengajian_am_stpm_objektif/features/profile/presentation/coordinators/profile_load_coordinator.dart';

void main() {
  group('ProfileLoadCoordinator', () {
    test('loadInitial memuatkan kedua-dua data tanpa force refresh', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.loadInitial();

      expect(
        calls,
        containsAll(['loadProfile:false', 'loadMistakeBook:false']),
      );

      expect(calls, hasLength(2));
    });

    test('refreshAll menyegarkan kedua-dua data', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.refreshAll();

      expect(calls, containsAll(['loadProfile:true', 'loadMistakeBook:true']));

      expect(calls, hasLength(2));
    });

    test('retryProfile hanya menyegarkan Profile', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.retryProfile();

      expect(calls, ['loadProfile:true']);
    });

    test('retryMistakeBook hanya menyegarkan Mistake Book', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.retryMistakeBook();

      expect(calls, ['loadMistakeBook:true']);
    });

    test(
      'synchronization diabaikan ketika pengguna sedang log keluar',
      () async {
        final calls = <String>[];

        final coordinator = _createCoordinator(calls: calls);

        await coordinator.synchronizeAfterProgressChange(isLoggingOut: true);

        expect(calls, isEmpty);
      },
    );

    test('synchronization diabaikan ketika Profile sedang loading', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(
        calls: calls,
        profileStatus: ProfileStatus.loading,
      );

      await coordinator.synchronizeAfterProgressChange(isLoggingOut: false);

      expect(calls, ['readProfileStatus']);
    });

    test('synchronization reset dan memuatkan semula Profile', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(
        calls: calls,
        profileStatus: ProfileStatus.success,
      );

      await coordinator.synchronizeAfterProgressChange(isLoggingOut: false);

      expect(calls, ['readProfileStatus', 'resetProfile', 'loadProfile:false']);
    });
  });
}

ProfileLoadCoordinator _createCoordinator({
  required List<String> calls,
  ProfileStatus profileStatus = ProfileStatus.success,
}) {
  return ProfileLoadCoordinator(
    loadProfile: (forceRefresh) async {
      calls.add('loadProfile:$forceRefresh');
    },
    loadMistakeBook: (forceRefresh) async {
      calls.add('loadMistakeBook:$forceRefresh');
    },
    readProfileStatus: () {
      calls.add('readProfileStatus');

      return profileStatus;
    },
    resetProfile: () {
      calls.add('resetProfile');
    },
  );
}
