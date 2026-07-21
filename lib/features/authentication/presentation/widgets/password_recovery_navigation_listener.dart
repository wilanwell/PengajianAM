import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/services/supabase_client_provider.dart';

/// Stream authentication yang digunakan oleh
/// password-recovery navigation listener.
///
/// Dalam aplikasi sebenar, stream datang daripada
/// Supabase Auth.
///
/// Dalam widget test, Supabase mungkin belum
/// di-initialize kerana test tidak menjalankan
/// fungsi main(). Dalam keadaan itu, stream kosong
/// digunakan supaya aplikasi masih boleh dibina.
final passwordRecoveryAuthStateStreamProvider = Provider<Stream<AuthState>>((
  ref,
) {
  try {
    final client = ref.read(supabaseClientProvider);

    return client.auth.onAuthStateChange;
  } catch (error, stackTrace) {
    /*
       * Widget test biasanya tidak menjalankan
       * Supabase.initialize().
       *
       * Listener password recovery dinyahaktifkan
       * sementara melalui stream kosong, tetapi
       * bahagian aplikasi lain masih boleh diuji.
       */
    if (kDebugMode && !_isSupabaseNotInitializedError(error)) {
      debugPrint(
        'Password recovery auth stream '
        'tidak tersedia: $error',
      );

      debugPrintStack(stackTrace: stackTrace);
    }

    return Stream<AuthState>.empty();
  }
});

bool _isSupabaseNotInitializedError(Object error) {
  final message = error.toString().toLowerCase();

  return message.contains('you must initialize the supabase instance') ||
      message.contains('_instance._isinitialized') ||
      message.contains('supabase instance before calling');
}

/// Mendengar event authentication Supabase pada
/// peringkat global aplikasi.
///
/// Apabila pautan reset kata laluan dibuka,
/// Supabase menghasilkan event passwordRecovery.
/// Listener kemudian membuka halaman untuk
/// menetapkan kata laluan baharu.
class PasswordRecoveryNavigationListener extends ConsumerStatefulWidget {
  const PasswordRecoveryNavigationListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PasswordRecoveryNavigationListener> createState() {
    return _PasswordRecoveryNavigationListenerState();
  }
}

class _PasswordRecoveryNavigationListenerState
    extends ConsumerState<PasswordRecoveryNavigationListener> {
  StreamSubscription<AuthState>? _authSubscription;

  bool _hasHandledRecoveryEvent = false;

  @override
  void initState() {
    super.initState();

    final authStateStream = ref.read(passwordRecoveryAuthStateStreamProvider);

    _authSubscription = authStateStream.listen(
      _handleAuthStateChange,
      onError: _handleAuthStreamError,
    );
  }

  void _handleAuthStateChange(AuthState authState) {
    switch (authState.event) {
      case AuthChangeEvent.passwordRecovery:
        _openResetPasswordPage();
        break;

      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.signedOut:
        /*
         * Membenarkan pautan recovery baharu
         * diproses dalam sesi aplikasi sama.
         */
        _hasHandledRecoveryEvent = false;
        break;

      default:
        break;
    }
  }

  void _openResetPasswordPage() {
    if (_hasHandledRecoveryEvent) {
      return;
    }

    _hasHandledRecoveryEvent = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final router = ref.read(appRouterProvider);

      router.goNamed(RouteNames.resetPassword);
    });
  }

  void _handleAuthStreamError(Object error, StackTrace stackTrace) {
    /*
     * Ralat auth stream boleh berlaku ketika
     * token refresh dijalankan semasa offline.
     *
     * Ralat dikendalikan di sini supaya tidak
     * menjadi unhandled exception.
     */
    if (kDebugMode) {
      debugPrint(
        'Password recovery auth stream '
        'error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    final subscription = _authSubscription;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    _authSubscription = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
