import '../entities/network_connection_status.dart';

abstract interface class NetworkStatusRepository {
  Future<NetworkConnectionStatus> checkStatus();

  Stream<NetworkConnectionStatus> watchStatus();
}
