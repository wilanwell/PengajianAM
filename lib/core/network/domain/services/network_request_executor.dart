import 'dart:async';

import '../exceptions/network_request_timeout_failure.dart';

class NetworkRequestExecutor {
  const NetworkRequestExecutor({
    this.defaultTimeout = const Duration(seconds: 20),
  });

  final Duration defaultTimeout;

  Future<T> run<T>({
    required Future<T> Function() request,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? defaultTimeout;

    if (effectiveTimeout <= Duration.zero) {
      throw ArgumentError.value(
        effectiveTimeout,
        'timeout',
        'Timeout mestilah lebih besar '
            'daripada sifar.',
      );
    }

    try {
      return await request().timeout(effectiveTimeout);
    } on TimeoutException {
      throw NetworkRequestTimeoutFailure(timeout: effectiveTimeout);
    }
  }
}
