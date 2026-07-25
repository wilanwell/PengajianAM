import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/domain/exceptions/network_request_timeout_failure.dart';
import '../../../../core/network/domain/services/network_request_executor.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../../domain/entities/leaderboard_snapshot.dart';
import '../../domain/exceptions/leaderboard_failure.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  const SupabaseLeaderboardRepository(this._client, this._requestExecutor);

  final SupabaseClient _client;

  final NetworkRequestExecutor _requestExecutor;

  @override
  Future<LeaderboardSnapshot> fetchLeaderboard({
    required LeaderboardPeriod period,
    int limit = 100,
  }) async {
    if (limit < 3 || limit > 100) {
      throw const LeaderboardFailure(
        'Had leaderboard mestilah antara '
        '3 dan 100.',
      );
    }

    try {
      final response = await _requestExecutor.run<Object?>(
        request: () {
          return _client.rpc(
            'get_leaderboard_v2',
            params: {'p_period': period.name, 'p_limit': limit},
          );
        },
      );

      final responseMap = _readResponseMap(response);

      final responsePeriod = _readPeriod(responseMap, 'period');

      if (responsePeriod != period) {
        throw const LeaderboardFailure(
          'Tempoh leaderboard daripada '
          'server tidak sepadan.',
        );
      }

      final generatedAt = _readDateTime(responseMap, 'generatedAt');

      final periodStartsAt = _readDateTime(responseMap, 'periodStartsAt');

      final periodEndsAt = _readDateTime(responseMap, 'periodEndsAt');

      if (!periodEndsAt.isAfter(periodStartsAt)) {
        throw const LeaderboardFailure(
          'Julat masa leaderboard '
          'daripada server tidak sah.',
        );
      }

      final timezone = _readRequiredString(responseMap, 'timezone');

      if (timezone != 'Asia/Kuala_Lumpur') {
        throw const LeaderboardFailure(
          'Timezone leaderboard daripada '
          'server tidak sah.',
        );
      }

      final isParticipating = _readBoolean(responseMap, 'isParticipating');

      final currentUserXp = _readInteger(
        responseMap,
        'currentUserXp',
        minimum: 0,
      );

      final participantCount = _readInteger(
        responseMap,
        'participantCount',
        minimum: 0,
      );

      final rawEntries = responseMap['entries'];

      if (rawEntries is! List) {
        throw const LeaderboardFailure(
          'Senarai leaderboard daripada '
          'server tidak sah.',
        );
      }

      final entries = <LeaderboardEntry>[];

      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map) {
          throw const LeaderboardFailure(
            'Data peserta leaderboard '
            'tidak sah.',
          );
        }

        entries.add(_readLeaderboardEntry(Map<String, dynamic>.from(rawEntry)));
      }

      final entryIds = entries.map((entry) => entry.userId).toSet();

      if (entryIds.length != entries.length) {
        throw const LeaderboardFailure(
          'Leaderboard mengandungi '
          'peserta berulang.',
        );
      }

      final ranks = entries.map((entry) => entry.rank).toSet();

      if (ranks.length != entries.length) {
        throw const LeaderboardFailure(
          'Leaderboard mengandungi '
          'ranking berulang.',
        );
      }

      final currentUserEntries = entries
          .where((entry) {
            return entry.isCurrentUser;
          })
          .toList(growable: false);

      if (isParticipating) {
        if (participantCount < 1) {
          throw const LeaderboardFailure(
            'Jumlah peserta leaderboard '
            'tidak sah.',
          );
        }

        if (currentUserEntries.length != 1) {
          throw const LeaderboardFailure(
            'Kedudukan pengguna semasa '
            'tidak dapat dikenal pasti.',
          );
        }

        if (currentUserEntries.single.xp != currentUserXp) {
          throw const LeaderboardFailure(
            'XP pengguna semasa tidak '
            'sepadan dengan ranking.',
          );
        }
      } else if (currentUserEntries.isNotEmpty) {
        throw const LeaderboardFailure(
          'Pengguna opt-out tidak '
          'sepatutnya mempunyai ranking.',
        );
      }

      entries.sort((first, second) {
        return first.rank.compareTo(second.rank);
      });

      if (participantCount < entries.length) {
        throw const LeaderboardFailure(
          'Jumlah peserta leaderboard '
          'tidak sah.',
        );
      }

      return LeaderboardSnapshot(
        period: responsePeriod,
        generatedAt: generatedAt,
        periodStartsAt: periodStartsAt,
        periodEndsAt: periodEndsAt,
        timezone: timezone,
        isParticipating: isParticipating,
        currentUserXp: currentUserXp,
        participantCount: participantCount,
        entries: List<LeaderboardEntry>.unmodifiable(entries),
      );
    } on LeaderboardFailure {
      rethrow;
    } on NetworkRequestTimeoutFailure catch (error) {
      throw LeaderboardFailure(error.message);
    } on PostgrestException catch (error) {
      throw LeaderboardFailure(_mapPostgrestMessage(error.message));
    } catch (_) {
      throw const LeaderboardFailure(
        'Leaderboard tidak dapat '
        'dimuatkan. Semak sambungan '
        'Internet anda.',
      );
    }
  }

  Map<String, dynamic> _readResponseMap(Object? response) {
    if (response is! Map) {
      throw const LeaderboardFailure(
        'Response leaderboard daripada '
        'server tidak sah.',
      );
    }

    return Map<String, dynamic>.from(response);
  }

  LeaderboardEntry _readLeaderboardEntry(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: _readRequiredString(json, 'entryId'),
      nickname: _readRequiredString(json, 'nickname'),
      rank: _readInteger(json, 'rank', minimum: 1),
      xp: _readInteger(json, 'xp', minimum: 0),
      previousRank: _readOptionalInteger(json, 'previousRank', minimum: 1),
      isCurrentUser: _readBoolean(json, 'isCurrentUser'),
    );
  }

  LeaderboardPeriod _readPeriod(Map<String, dynamic> json, String key) {
    final value = _readRequiredString(json, key);

    for (final period in LeaderboardPeriod.values) {
      if (period.name == value) {
        return period;
      }
    }

    throw const LeaderboardFailure(
      'Tempoh leaderboard daripada '
      'server tidak sah.',
    );
  }

  String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw LeaderboardFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    return value.trim();
  }

  int _readInteger(
    Map<String, dynamic> json,
    String key, {
    required int minimum,
  }) {
    final value = json[key];

    if (value is! num) {
      throw LeaderboardFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    final result = value.toInt();

    if (result < minimum) {
      throw LeaderboardFailure(
        'Data $key daripada server '
        'berada di luar julat.',
      );
    }

    return result;
  }

  int? _readOptionalInteger(
    Map<String, dynamic> json,
    String key, {
    required int minimum,
  }) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! num) {
      throw LeaderboardFailure(
        'Data $key daripada server '
        'tidak sah.',
      );
    }

    final result = value.toInt();

    if (result < minimum) {
      throw LeaderboardFailure(
        'Data $key daripada server '
        'berada di luar julat.',
      );
    }

    return result;
  }

  bool _readBoolean(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! bool) {
      throw LeaderboardFailure(
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
      throw LeaderboardFailure(
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

    if (message.contains('period must be')) {
      return 'Tempoh leaderboard tidak sah.';
    }

    if (message.contains('limit must be')) {
      return 'Had peserta leaderboard '
          'tidak sah.';
    }

    if (message.contains('permission denied') ||
        message.contains('row-level security')) {
      return 'Anda tidak mempunyai '
          'kebenaran untuk membuka '
          'leaderboard.';
    }

    if (message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network')) {
      return 'Tidak dapat berhubung '
          'dengan pelayan leaderboard. '
          'Semak sambungan Internet anda.';
    }

    return 'Operasi leaderboard gagal. '
        'Sila cuba semula.';
  }
}
