import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/entities/network_connection_status.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/repositories/network_status_repository.dart';
import 'package:pengajian_am_stpm_objektif/core/network/presentation/controllers/network_status_controller.dart';

class _FakeNetworkStatusRepository implements NetworkStatusRepository {
  _FakeNetworkStatusRepository({required this.currentStatus});

  NetworkConnectionStatus currentStatus;

  final StreamController<NetworkConnectionStatus> _controller =
      StreamController<NetworkConnectionStatus>.broadcast();

  int checkCallCount = 0;

  @override
  Future<NetworkConnectionStatus> checkStatus() async {
    checkCallCount++;

    return currentStatus;
  }

  @override
  Stream<NetworkConnectionStatus> watchStatus() {
    return _controller.stream;
  }

  void emit(NetworkConnectionStatus status) {
    currentStatus = status;

    _controller.add(status);
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

void main() {
  test('memuatkan status awal dan mengikuti perubahan rangkaian', () async {
    final repository = _FakeNetworkStatusRepository(
      currentStatus: NetworkConnectionStatus.connected,
    );

    final container = ProviderContainer(
      overrides: [
        networkStatusRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(() async {
      container.dispose();

      await repository.dispose();
    });

    final initialStatus = await container.read(
      networkStatusControllerProvider.future,
    );

    expect(initialStatus, NetworkConnectionStatus.connected);

    expect(repository.checkCallCount, 1);

    repository.emit(NetworkConnectionStatus.disconnected);

    await pumpEventQueue();

    final disconnectedState = container.read(networkStatusControllerProvider);

    expect(
      disconnectedState.requireValue,
      NetworkConnectionStatus.disconnected,
    );

    repository.emit(NetworkConnectionStatus.connected);

    await pumpEventQueue();

    final connectedState = container.read(networkStatusControllerProvider);

    expect(connectedState.requireValue, NetworkConnectionStatus.connected);
  });

  test('refresh membaca status rangkaian terkini', () async {
    final repository = _FakeNetworkStatusRepository(
      currentStatus: NetworkConnectionStatus.connected,
    );

    final container = ProviderContainer(
      overrides: [
        networkStatusRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(() async {
      container.dispose();

      await repository.dispose();
    });

    await container.read(networkStatusControllerProvider.future);

    repository.currentStatus = NetworkConnectionStatus.disconnected;

    await container.read(networkStatusControllerProvider.notifier).refresh();

    final state = container.read(networkStatusControllerProvider);

    expect(state.requireValue, NetworkConnectionStatus.disconnected);

    expect(repository.checkCallCount, 2);
  });
}
