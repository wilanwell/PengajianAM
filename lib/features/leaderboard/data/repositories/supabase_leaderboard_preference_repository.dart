import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/leaderboard_preference.dart';
import '../../domain/exceptions/leaderboard_preference_failure.dart';
import '../../domain/repositories/leaderboard_preference_repository.dart';

class SupabaseLeaderboardPreferenceRepository
    implements LeaderboardPreferenceRepository {
  const SupabaseLeaderboardPreferenceRepository(
    this._client,
    this._requestExecutor,
  );

  final SupabaseClient _client;

  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<LeaderboardPreference> fetchPreference() async {
    _ensureAuthenticated();

    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc('get_my_leaderboard_preference');
        },
      );

      return _readPreference(response);
    } on LeaderboardPreferenceFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw LeaderboardPreferenceFailure(error.message);
    } on PostgrestException catch (error) {
      throw LeaderboardPreferenceFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const LeaderboardPreferenceFailure(
        'Tetapan leaderboard tidak dapat '
        'dimuatkan. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  @override
  Future<LeaderboardPreference> updateParticipation({
    required bool optIn,
    required String consentVersion,
  }) async {
    _ensureAuthenticated();

    final normalizedConsentVersion = consentVersion.trim();

    if (normalizedConsentVersion.isEmpty ||
        normalizedConsentVersion.length > 20) {
      throw const LeaderboardPreferenceFailure(
        'Versi persetujuan leaderboard '
        'tidak sah.',
      );
    }

    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc(
            'set_my_leaderboard_participation',
            params: {
              'p_opt_in': optIn,
              'p_consent_version': normalizedConsentVersion,
            },
          );
        },
      );

      final preference = _readPreference(response);

      if (preference.isOptedIn != optIn) {
        throw const LeaderboardPreferenceFailure(
          'Status penyertaan leaderboard '
          'daripada server tidak sepadan.',
        );
      }

      return preference;
    } on LeaderboardPreferenceFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw LeaderboardPreferenceFailure(error.message);
    } on PostgrestException catch (error) {
      throw LeaderboardPreferenceFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const LeaderboardPreferenceFailure(
        'Tetapan leaderboard tidak dapat '
        'dikemas kini. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  void _ensureAuthenticated() {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const LeaderboardPreferenceFailure(
        'Sesi pengguna tidak tersedia. '
        'Sila log masuk semula.',
      );
    }
  }

  LeaderboardPreference _readPreference(Object? response) {
    final responseMap = _readResponseMap(response);

    final isOptedIn = _readBoolean(responseMap, 'optedIn');

    final consentAt = _readOptionalDateTime(responseMap, 'consentAt');

    final consentVersion = _readOptionalString(responseMap, 'consentVersion');

    final requiredConsentVersion = _readRequiredString(
      responseMap,
      'requiredConsentVersion',
    );

    final serverTime = _readDateTime(responseMap, 'serverTime');

    /*
     * Opt-in wajib mempunyai tarikh dan
     * versi consent.
     */
    if (isOptedIn && (consentAt == null || consentVersion == null)) {
      throw const LeaderboardPreferenceFailure(
        'Data persetujuan leaderboard '
        'daripada server tidak lengkap.',
      );
    }

    /*
     * Opt-out tidak sepatutnya mempunyai
     * consent aktif.
     */
    if (!isOptedIn && (consentAt != null || consentVersion != null)) {
      throw const LeaderboardPreferenceFailure(
        'Status persetujuan leaderboard '
        'daripada server tidak konsisten.',
      );
    }

    return LeaderboardPreference(
      isOptedIn: isOptedIn,
      consentAt: consentAt,
      consentVersion: consentVersion,
      requiredConsentVersion: requiredConsentVersion,
      serverTime: serverTime,
    );
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const LeaderboardPreferenceFailure(
        'Response tetapan leaderboard '
        'daripada server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw LeaderboardPreferenceFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value.trim();
  }

  String? _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String || value.trim().isEmpty) {
      throw LeaderboardPreferenceFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value.trim();
  }

  bool _readBoolean(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! bool) {
      throw LeaderboardPreferenceFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value;
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final rawValue = _readRequiredString(json, key);

    final parsedValue = DateTime.tryParse(rawValue);

    if (parsedValue == null) {
      throw LeaderboardPreferenceFailure(
        'Tarikh $key daripada server '
        'tidak sah.',
      );
    }

    return parsedValue;
  }

  DateTime? _readOptionalDateTime(Map<String, dynamic> json, String key) {
    final rawValue = json[key];

    if (rawValue == null) {
      return null;
    }

    if (rawValue is! String || rawValue.trim().isEmpty) {
      throw LeaderboardPreferenceFailure(
        'Tarikh $key daripada server '
        'tidak sah.',
      );
    }

    final parsedValue = DateTime.tryParse(rawValue.trim());

    if (parsedValue == null) {
      throw LeaderboardPreferenceFailure(
        'Tarikh $key daripada server '
        'tidak sah.',
      );
    }

    return parsedValue;
  }

  String _mapPostgrestMessage(String originalMessage) {
    final message = originalMessage.toLowerCase();

    if (message.contains('authentication required')) {
      return 'Sesi anda telah tamat. '
          'Sila log masuk semula.';
    }

    if (message.contains('profile was not found')) {
      return 'Profil pengguna tidak ditemui.';
    }

    if (message.contains('opt_in is required')) {
      return 'Status penyertaan leaderboard '
          'tidak sah.';
    }

    if (message.contains('consent_version is invalid')) {
      return 'Versi persetujuan leaderboard '
          'tidak sah.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai '
          'kebenaran untuk mengubah '
          'tetapan leaderboard.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung dengan '
          'pelayan leaderboard. Semak '
          'sambungan Internet anda.';
    }

    return 'Operasi tetapan leaderboard '
        'gagal. Sila cuba semula.';
  }
}
