import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/exceptions/account_deletion_failure.dart';
import '../../domain/repositories/account_deletion_repository.dart';

class SupabaseAccountDeletionRepository implements AccountDeletionRepository {
  const SupabaseAccountDeletionRepository(this._client, this._requestExecutor);

  static const String _functionName = 'delete-account';

  final SupabaseClient _client;
  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<void> deleteAccount({required String currentPassword}) async {
    final currentUser = _client.auth.currentUser;

    final email = currentUser?.email?.trim();

    if (currentUser == null || email == null || email.isEmpty) {
      throw const AccountDeletionFailure(
        'Sesi pengguna tidak tersedia. '
        'Sila log masuk semula.',
      );
    }

    if (currentPassword.trim().isEmpty) {
      throw const AccountDeletionFailure('Masukkan kata laluan semasa anda.');
    }

    try {
      /*
       * Sahkan kata laluan semasa sebelum
       * melakukan tindakan kekal.
       */
      final authenticationResponse = await _requestExecutor.run<AuthResponse>(
        request: () {
          return _client.auth.signInWithPassword(
            email: email,
            password: currentPassword,
          );
        },
      );

      final authenticatedUser = authenticationResponse.user;

      final authenticatedSession = authenticationResponse.session;

      if (authenticatedUser == null ||
          authenticatedSession == null ||
          authenticatedUser.id != currentUser.id) {
        throw const AccountDeletionFailure(
          'Pengesahan identiti gagal. '
          'Sila log masuk semula.',
        );
      }

      /*
       * Edge Function mendapatkan user ID
       * daripada JWT pengguna semasa.
       *
       * Aplikasi tidak menghantar user ID
       * sebagai parameter.
       */
      final response = await _requestExecutor.run<FunctionResponse>(
        timeout: const Duration(seconds: 30),
        request: () {
          return _client.functions.invoke(_functionName);
        },
      );

      _validateResponse(response);

      /*
       * Jangan sign out di sini.
       *
       * Sesi tempatan masih diperlukan untuk
       * mengenal pasti pemilik draft ketika
       * aplikasi membersihkan data tempatan.
       */
    } on AccountDeletionFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw AccountDeletionFailure(error.message);
    } on AuthException catch (error) {
      throw AccountDeletionFailure(_mapAuthenticationError(error.message));
    } on FunctionException catch (error) {
      throw AccountDeletionFailure(_mapFunctionError(error));
    } catch (_) {
      throw const AccountDeletionFailure(
        'Akaun tidak dapat dipadamkan. '
        'Semak sambungan Internet dan '
        'cuba semula.',
      );
    }
  }

  void _validateResponse(FunctionResponse response) {
    if (response.status < 200 || response.status >= 300) {
      throw const AccountDeletionFailure(
        'Server tidak dapat menyelesaikan '
        'penghapusan akaun.',
      );
    }

    final responseData = _readResponseMap(response.data);

    final success = responseData['success'];

    if (success != true) {
      final message = _readMessage(responseData);

      throw AccountDeletionFailure(message ?? 'Akaun tidak dapat dipadamkan.');
    }
  }

  Map<String, dynamic> _readResponseMap(Object? value) {
    if (value is! Map) {
      throw const AccountDeletionFailure(
        'Pengesahan penghapusan daripada '
        'server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(value);
  }

  String? _readMessage(Map<dynamic, dynamic> data) {
    final value = data['message'];

    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  String _mapAuthenticationError(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Kata laluan semasa tidak betul.';
    }

    if (message.contains('email not confirmed')) {
      return 'E-mel akaun belum disahkan.';
    }

    if (message.contains('network request failed') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused')) {
      return 'Tidak dapat berhubung dengan '
          'pelayan. Semak sambungan '
          'Internet anda.';
    }

    if (message.contains('session') ||
        message.contains('token') ||
        message.contains('not logged in')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    return 'Kata laluan semasa tidak dapat '
        'disahkan.';
  }

  String _mapFunctionError(FunctionException error) {
    final serverMessage = _readFunctionMessage(error.details);

    if (error.status == 401) {
      return 'Sesi anda tidak sah atau telah '
          'tamat. Sila log masuk semula.';
    }

    if (error.status == 429) {
      return 'Terlalu banyak permintaan. '
          'Sila tunggu sebentar dan '
          'cuba semula.';
    }

    if (serverMessage != null) {
      return serverMessage;
    }

    if (error.status >= 500) {
      return 'Server tidak dapat memadamkan '
          'akaun sekarang. Sila cuba semula.';
    }

    return 'Permintaan penghapusan akaun '
        'tidak dapat diselesaikan.';
  }

  String? _readFunctionMessage(Object? details) {
    if (details is Map) {
      final message = details['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return null;
  }
}
