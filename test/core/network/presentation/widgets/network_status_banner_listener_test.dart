import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/entities/network_connection_status.dart';
import 'package:pengajian_am_stpm_objektif/core/network/domain/repositories/network_status_repository.dart';
import 'package:pengajian_am_stpm_objektif/core/network/presentation/controllers/network_status_controller.dart';
import 'package:pengajian_am_stpm_objektif/core/network/presentation/widgets/network_status_banner_listener.dart';

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

Widget _buildTestApp({required _FakeNetworkStatusRepository repository}) {
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  return ProviderScope(
    overrides: [networkStatusRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: NetworkStatusBannerListener(
        scaffoldMessengerKey: scaffoldMessengerKey,
        child: const Scaffold(body: Center(child: Text('Kandungan Aplikasi'))),
      ),
    ),
  );
}

void main() {
  testWidgets('memaparkan dan menutup banner mengikut status rangkaian', (
    tester,
  ) async {
    final repository = _FakeNetworkStatusRepository(
      currentStatus: NetworkConnectionStatus.connected,
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository: repository));

    await tester.pumpAndSettle();

    expect(find.text('Kandungan Aplikasi'), findsOneWidget);

    expect(find.byKey(const ValueKey('network-offline-banner')), findsNothing);

    /*
       * Simulasikan peranti kehilangan
       * sambungan rangkaian.
       */
    repository.emit(NetworkConnectionStatus.disconnected);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('network-offline-banner')),
      findsOneWidget,
    );

    expect(find.textContaining('Tiada sambungan rangkaian'), findsOneWidget);

    expect(
      find.textContaining('Kemajuan kuiz yang telah disimpan'),
      findsOneWidget,
    );

    expect(find.text('Semak Semula'), findsOneWidget);

    /*
       * Simulasikan rangkaian tersedia
       * semula.
       */
    repository.emit(NetworkConnectionStatus.connected);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('network-offline-banner')), findsNothing);

    expect(
      find.text(
        'Sambungan rangkaian '
        'kembali tersedia.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('butang semak semula membaca status terkini', (tester) async {
    final repository = _FakeNetworkStatusRepository(
      currentStatus: NetworkConnectionStatus.disconnected,
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository: repository));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('network-offline-banner')),
      findsOneWidget,
    );

    expect(repository.checkCallCount, 1);

    /*
       * Status fake repository berubah,
       * tetapi stream tidak dihantar.
       *
       * Perubahan hanya akan diketahui apabila
       * butang Semak Semula ditekan.
       */
    repository.currentStatus = NetworkConnectionStatus.connected;

    await tester.tap(find.byKey(const ValueKey('network-refresh-button')));

    await tester.pumpAndSettle();

    expect(repository.checkCallCount, 2);

    expect(find.byKey(const ValueKey('network-offline-banner')), findsNothing);

    expect(
      find.text(
        'Sambungan rangkaian '
        'kembali tersedia.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('memeriksa semula rangkaian apabila aplikasi kembali aktif', (
    tester,
  ) async {
    final repository = _FakeNetworkStatusRepository(
      currentStatus: NetworkConnectionStatus.connected,
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository: repository));

    await tester.pumpAndSettle();

    expect(repository.checkCallCount, 1);

    repository.currentStatus = NetworkConnectionStatus.disconnected;

    /*
       * Simulasikan aplikasi kembali daripada
       * background ke foreground.
       */
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pumpAndSettle();

    expect(repository.checkCallCount, 2);

    expect(
      find.byKey(const ValueKey('network-offline-banner')),
      findsOneWidget,
    );

    expect(find.textContaining('Tiada sambungan rangkaian'), findsOneWidget);
  });
}
