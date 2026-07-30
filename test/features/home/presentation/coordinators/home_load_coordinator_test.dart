import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/controllers/home_state.dart';
import 'package:pengajian_am_stpm_objektif/features/home/presentation/coordinators/home_load_coordinator.dart';

void main() {
  group('HomeLoadCoordinator', () {
    test('loadInitial memuatkan dashboard dengan force refresh', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.loadInitial();

      expect(calls, ['loadDashboard:true']);
    });

    test('refreshDashboard menggunakan force refresh', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.refreshDashboard();

      expect(calls, ['loadDashboard:true']);
    });

    test('retryDashboard menggunakan force refresh', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.retryDashboard();

      expect(calls, ['loadDashboard:true']);
    });

    test('synchronization diabaikan ketika sedang log keluar', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(calls: calls);

      await coordinator.synchronizeAfterProgressChange(isLoggingOut: true);

      expect(calls, isEmpty);
    });

    test('synchronization diabaikan ketika dashboard sedang loading', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(
        calls: calls,
        homeStatus: HomeStatus.loading,
      );

      await coordinator.synchronizeAfterProgressChange(isLoggingOut: false);

      expect(calls, ['readHomeStatus']);
    });

    test('synchronization reset dan memuatkan semula dashboard', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(
        calls: calls,
        homeStatus: HomeStatus.success,
      );

      await coordinator.synchronizeAfterProgressChange(isLoggingOut: false);

      expect(calls, ['readHomeStatus', 'resetHome', 'loadDashboard:false']);
    });

    test('reload selepas invalidation diabaikan ketika log keluar', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(
        calls: calls,
        homeStatus: HomeStatus.initial,
      );

      await coordinator.ensureLoadedAfterInvalidation(isLoggingOut: true);

      expect(calls, isEmpty);
    });

    test(
      'reload selepas invalidation diabaikan apabila state bukan initial',
      () async {
        final calls = <String>[];

        final coordinator = _createCoordinator(
          calls: calls,
          homeStatus: HomeStatus.success,
        );

        await coordinator.ensureLoadedAfterInvalidation(isLoggingOut: false);

        expect(calls, ['readHomeStatus']);
      },
    );

    test('reload selepas invalidation memuatkan dashboard initial', () async {
      final calls = <String>[];

      final coordinator = _createCoordinator(
        calls: calls,
        homeStatus: HomeStatus.initial,
      );

      await coordinator.ensureLoadedAfterInvalidation(isLoggingOut: false);

      expect(calls, ['readHomeStatus', 'loadDashboard:true']);
    });
  });
}

HomeLoadCoordinator _createCoordinator({
  required List<String> calls,
  HomeStatus homeStatus = HomeStatus.success,
}) {
  return HomeLoadCoordinator(
    loadDashboardAction: (forceRefresh) async {
      calls.add('loadDashboard:$forceRefresh');
    },
    readHomeStatus: () {
      calls.add('readHomeStatus');

      return homeStatus;
    },
    resetHome: () {
      calls.add('resetHome');
    },
  );
}
