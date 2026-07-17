class NetworkRequestTimeoutFailure implements Exception {
  const NetworkRequestTimeoutFailure({required this.timeout});

  final Duration timeout;

  String get message {
    return 'Permintaan mengambil masa terlalu lama. '
        'Semak sambungan Internet dan cuba semula.';
  }

  @override
  String toString() {
    return message;
  }
}
