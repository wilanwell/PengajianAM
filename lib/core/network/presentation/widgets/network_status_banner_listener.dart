import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/network_connection_status.dart';
import '../controllers/network_status_controller.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class NetworkStatusBannerListener extends ConsumerStatefulWidget {
  const NetworkStatusBannerListener({
    required this.scaffoldMessengerKey,
    required this.child,
    super.key,
  });

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  final Widget child;

  @override
  ConsumerState<NetworkStatusBannerListener> createState() {
    return _NetworkStatusBannerListenerState();
  }
}

class _NetworkStatusBannerListenerState
    extends ConsumerState<NetworkStatusBannerListener>
    with WidgetsBindingObserver {
  NetworkConnectionStatus? _lastStatus;

  bool _isBannerVisible = false;
  bool _statusUpdateScheduled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    /*
     * Perubahan rangkaian mungkin tidak diterima
     * ketika aplikasi berada di background.
     */
    unawaited(ref.read(networkStatusControllerProvider.notifier).refresh());
  }

  void _scheduleStatusUpdate(NetworkConnectionStatus status) {
    if (_lastStatus == status || _statusUpdateScheduled) {
      return;
    }

    _statusUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _statusUpdateScheduled = false;

      if (!mounted) {
        return;
      }

      _applyStatus(status);
    });
  }

  void _applyStatus(NetworkConnectionStatus status) {
    final previousStatus = _lastStatus;

    _lastStatus = status;

    final messenger = widget.scaffoldMessengerKey.currentState;

    if (messenger == null) {
      return;
    }

    if (status.isDisconnected) {
      messenger.hideCurrentMaterialBanner();

      messenger.showMaterialBanner(_buildOfflineBanner());

      _isBannerVisible = true;

      return;
    }

    if (_isBannerVisible) {
      messenger.hideCurrentMaterialBanner();

      _isBannerVisible = false;
    }

    if (previousStatus == NetworkConnectionStatus.disconnected) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Sambungan rangkaian kembali tersedia.'),
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  MaterialBanner _buildOfflineBanner() {
    final colorScheme = Theme.of(context).colorScheme;

    return MaterialBanner(
      key: const ValueKey('network-offline-banner'),
      backgroundColor: colorScheme.errorContainer,
      leading: Icon(
        Icons.wifi_off_rounded,
        color: colorScheme.onErrorContainer,
      ),
      content: Text(
        'Tiada sambungan rangkaian.\n'
        'Kemajuan kuiz yang telah disimpan '
        'kekal pada peranti.',
        style: TextStyle(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton.icon(
          key: const ValueKey('network-refresh-button'),
          onPressed: () {
            unawaited(
              ref.read(networkStatusControllerProvider.notifier).refresh(),
            );
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Semak Semula'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkStatus = ref.watch(networkStatusControllerProvider);

    networkStatus.whenData(_scheduleStatusUpdate);

    return widget.child;
  }
}
