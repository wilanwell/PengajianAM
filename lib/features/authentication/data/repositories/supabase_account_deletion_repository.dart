import 'dart:convert';

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

    if (currentUser == null) {
      throw const AccountDeletionFailure(
        'Sesi pengguna tidak tersedia. '
        'Sila log masuk semula.',
      );
    }

    /*
     * Jangan trim kata laluan.
     *
     * Space boleh menjadi sebahagian daripada
     * kata laluan sebenar pengguna.
     */
    if (currentPassword.isEmpty) {
      throw const AccountDeletionFailure('Masukkan kata laluan semasa anda.');
    }

    if (currentPassword.length > 1024) {
      throw const AccountDeletionFailure('Kata laluan semasa tidak sah.');
    }

    try {
      /*
       * Kata laluan dihantar kepada Edge
       * Function melalui HTTPS.
       *
       * Edge Function akan:
       * 1. mengesahkan JWT pemanggil;
       * 2. mengesahkan kata laluan pada server;
       * 3. memastikan kedua-dua ID sepadan;
       * 4. memadam akaun.
       *
       * Flutter tidak lagi melakukan
       * signInWithPassword() sebagai kawalan
       * keselamatan utama.
       */
      final response = await _requestExecutor.run<FunctionResponse>(
        timeout: const Duration(seconds: 30),
        request: () {
          return _client.functions.invoke(
            _functionName,
            body: {'currentPassword': currentPassword},
          );
        },
      );

      _validateResponse(response);

      /*
       * Jangan sign out di repository ini.
       *
       * DeleteAccountPage masih perlu
       * membersihkan draft dan state tempatan
       * sebelum sesi local dibuang.
       */
    } on AccountDeletionFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw AccountDeletionFailure(error.message);
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
    final resolvedValue = _decodePossibleJson(value);

    if (resolvedValue is! Map) {
      throw const AccountDeletionFailure(
        'Pengesahan penghapusan daripada '
        'server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(resolvedValue);
  }

  Object? _decodePossibleJson(Object? value) {
    if (value is! String) {
      return value;
    }

    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return value;
    }

    try {
      return jsonDecode(normalizedValue);
    } catch (_) {
      return value;
    }
  }

  String? _readMessage(Map<dynamic, dynamic> data) {
    final value = data['message'];

    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  String _mapFunctionError(FunctionException error) {
    final serverMessage = _readFunctionMessage(error.details);

    if (error.status == 400) {
      return serverMessage ??
          'Maklumat pengesahan '
              'tidak lengkap.';
    }

    if (error.status == 401) {
      return 'Sesi anda tidak sah atau telah '
          'tamat. Sila log masuk semula.';
    }

    if (error.status == 403) {
      return serverMessage ?? 'Kata laluan semasa tidak betul.';
    }

    if (error.status == 409) {
      return serverMessage ??
          'Akaun ini tidak dapat disahkan '
              'menggunakan kata laluan.';
    }

    if (error.status == 429) {
      return serverMessage ??
          'Terlalu banyak percubaan. '
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
    final resolvedDetails = _decodePossibleJson(details);

    if (resolvedDetails is Map) {
      final message = resolvedDetails['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return null;
  }
}
