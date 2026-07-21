import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/presentation/providers/network_request_executor_provider.dart';
import '../../../../core/services/supabase_client_provider.dart';
import '../../data/repositories/supabase_account_deletion_repository.dart';
import '../../domain/exceptions/account_deletion_failure.dart';
import '../../domain/repositories/account_deletion_repository.dart';
import 'account_deletion_state.dart';

final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository>((
  ref,
) {
  return SupabaseAccountDeletionRepository(
    ref.read(supabaseClientProvider),
    ref.read(networkRequestExecutorProvider),
  );
});

final accountDeletionControllerProvider =
    NotifierProvider<AccountDeletionController, AccountDeletionState>(
      AccountDeletionController.new,
    );

class AccountDeletionController extends Notifier<AccountDeletionState> {
  AccountDeletionRepository get _repository {
    return ref.read(accountDeletionRepositoryProvider);
  }

  @override
  AccountDeletionState build() {
    return const AccountDeletionState();
  }

  Future<bool> deleteAccount({required String currentPassword}) async {
    if (state.isDeleting) {
      return false;
    }

    if (currentPassword.trim().isEmpty) {
      state = const AccountDeletionState(
        status: AccountDeletionStatus.failure,
        errorMessage: 'Masukkan kata laluan semasa anda.',
      );

      return false;
    }

    state = const AccountDeletionState(status: AccountDeletionStatus.deleting);

    try {
      await _repository.deleteAccount(currentPassword: currentPassword);

      state = const AccountDeletionState(status: AccountDeletionStatus.success);

      return true;
    } on AccountDeletionFailure catch (error) {
      state = AccountDeletionState(
        status: AccountDeletionStatus.failure,
        errorMessage: error.message,
      );

      return false;
    } catch (_) {
      state = const AccountDeletionState(
        status: AccountDeletionStatus.failure,
        errorMessage:
            'Akaun tidak dapat dipadamkan. '
            'Sila cuba semula.',
      );

      return false;
    }
  }

  /// Bersihkan sesi pada peranti selepas:
  ///
  /// 1. akaun berjaya dipadam pada server;
  /// 2. draft dan tetapan tempatan dibersihkan.
  Future<void> clearLocalSessionAfterDeletion() async {
    try {
      await ref
          .read(supabaseClientProvider)
          .auth
          .signOut(scope: SignOutScope.local);
    } catch (_) {
      /*
       * Akaun sudah dipadam pada server.
       * Kegagalan membersihkan sesi tidak
       * menukar keputusan penghapusan.
       */
    }
  }

  void clearError() {
    if (!state.hasFailure) {
      return;
    }

    state = const AccountDeletionState();
  }

  void reset() {
    state = const AccountDeletionState();
  }
}
