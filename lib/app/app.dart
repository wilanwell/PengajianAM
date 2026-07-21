import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/presentation/widgets/network_status_banner_listener.dart';
import '../features/authentication/presentation/widgets/password_recovery_navigation_listener.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget of the application.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pengajian AM STPM Objektif',
      theme: AppTheme.light,

      /*
       * Satu ScaffoldMessenger digunakan untuk
       * seluruh aplikasi.
       *
       * Ini membolehkan banner offline kekal
       * dipaparkan walaupun pengguna bertukar
       * halaman atau tab.
       */
      scaffoldMessengerKey: rootScaffoldMessengerKey,

      routerConfig: router,

      /*
       * Builder membalut keseluruhan kandungan
       * router dengan dua global listener:
       *
       * 1. Password recovery navigation
       * 2. Network status banner
       */
      builder: (context, child) {
        return PasswordRecoveryNavigationListener(
          child: NetworkStatusBannerListener(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
