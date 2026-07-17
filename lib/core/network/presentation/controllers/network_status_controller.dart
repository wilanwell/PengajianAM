import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/connectivity_network_status_repository.dart';
import '../../domain/entities/network_connection_status.dart';
import '../../domain/repositories/network_status_repository.dart';

final networkStatusRepositoryProvider = Provider<NetworkStatusRepository>((
  ref,
) {
  return ConnectivityNetworkStatusRepository(Connectivity());
});

final networkStatusControllerProvider =
    AsyncNotifierProvider<NetworkStatusController, NetworkConnectionStatus>(
      NetworkStatusController.new,
    );

class NetworkStatusController extends AsyncNotifier<NetworkConnectionStatus> {
  StreamSubscription<NetworkConnectionStatus>? _subscription;

  NetworkStatusRepository get _repository {
    return ref.read(networkStatusRepositoryProvider);
  }

  @override
  Future<NetworkConnectionStatus> build() async {
    ref.onDispose(() {
      final subscription = _subscription;

      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    });

    final initialStatus = await _repository.checkStatus();

    _subscription = _repository.watchStatus().listen(
      (nextStatus) {
        state = AsyncData(nextStatus);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );

    return initialStatus;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_repository.checkStatus);
  }
}
