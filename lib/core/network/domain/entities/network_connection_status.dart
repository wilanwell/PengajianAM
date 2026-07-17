enum NetworkConnectionStatus { connected, disconnected }

extension NetworkConnectionStatusX on NetworkConnectionStatus {
  bool get hasNetworkConnection {
    return this == NetworkConnectionStatus.connected;
  }

  bool get isDisconnected {
    return this == NetworkConnectionStatus.disconnected;
  }

  String get message {
    return switch (this) {
      NetworkConnectionStatus.connected => 'Sambungan rangkaian tersedia.',
      NetworkConnectionStatus.disconnected => 'Tiada sambungan rangkaian.',
    };
  }
}
