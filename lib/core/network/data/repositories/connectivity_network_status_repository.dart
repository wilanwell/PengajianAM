import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/entities/network_connection_status.dart';
import '../../domain/repositories/network_status_repository.dart';

class ConnectivityNetworkStatusRepository implements NetworkStatusRepository {
  ConnectivityNetworkStatusRepository(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<NetworkConnectionStatus> checkStatus() async {
    final results = await _connectivity.checkConnectivity();

    return _mapResults(results);
  }

  @override
  Stream<NetworkConnectionStatus> watchStatus() {
    return _connectivity.onConnectivityChanged.map(_mapResults).distinct();
  }

  NetworkConnectionStatus _mapResults(List<ConnectivityResult> results) {
    final hasAvailableConnection = results.any((result) {
      return result != ConnectivityResult.none;
    });

    return hasAvailableConnection
        ? NetworkConnectionStatus.connected
        : NetworkConnectionStatus.disconnected;
  }
}
