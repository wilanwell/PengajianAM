import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/exceptions/network_request_timeout_failure.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/services/network_request_executor.dart';

void main() {
  test('memulangkan hasil apabila request selesai '
      'sebelum timeout', () async {
    const executor = NetworkRequestExecutor(
      defaultTimeout: Duration(seconds: 1),
    );

    final result = await executor.run<String>(
      request: () async {
        return 'berjaya';
      },
    );

    expect(result, 'berjaya');
  });

  test('menukar TimeoutException kepada '
      'NetworkRequestTimeoutFailure', () async {
    const timeout = Duration(milliseconds: 20);

    const executor = NetworkRequestExecutor(defaultTimeout: timeout);

    final requestCompleter = Completer<String>();

    final requestFuture = executor.run<String>(
      request: () {
        return requestCompleter.future;
      },
    );

    await expectLater(
      requestFuture,
      throwsA(
        isA<NetworkRequestTimeoutFailure>()
            .having((error) => error.timeout, 'timeout', timeout)
            .having(
              (error) => error.message,
              'message',
              contains(
                'Permintaan mengambil masa '
                'terlalu lama',
              ),
            ),
      ),
    );
  });

  test('menggunakan timeout khusus untuk '
      'satu request', () async {
    const customTimeout = Duration(milliseconds: 10);

    const executor = NetworkRequestExecutor(
      defaultTimeout: Duration(seconds: 1),
    );

    final requestCompleter = Completer<int>();

    final requestFuture = executor.run<int>(
      timeout: customTimeout,
      request: () {
        return requestCompleter.future;
      },
    );

    await expectLater(
      requestFuture,
      throwsA(
        isA<NetworkRequestTimeoutFailure>().having(
          (error) => error.timeout,
          'timeout',
          customTimeout,
        ),
      ),
    );
  });

  test('tidak mengubah error selain timeout', () async {
    const executor = NetworkRequestExecutor();

    final requestFuture = executor.run<void>(
      request: () async {
        throw StateError('server-error');
      },
    );

    await expectLater(
      requestFuture,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'server-error',
        ),
      ),
    );
  });

  test('menolak nilai timeout yang tidak sah', () async {
    const executor = NetworkRequestExecutor();

    final requestFuture = executor.run<String>(
      timeout: Duration.zero,
      request: () async {
        return 'tidak digunakan';
      },
    );

    await expectLater(requestFuture, throwsA(isA<ArgumentError>()));
  });
}
