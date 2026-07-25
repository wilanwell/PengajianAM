import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_preference.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/repositories/leaderboard_preference_repository.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_preference_controller.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_preference_state.dart';

class _FakeLeaderboardPreferenceRepository
    implements LeaderboardPreferenceRepository {
  var fetchCount = 0;

  final requestedOptInValues = <bool>[];

  final requestedConsentVersions = <String>[];

  LeaderboardPreference preference = LeaderboardPreference(
    isOptedIn: false,
    requiredConsentVersion: '1.0',
    serverTime: DateTime.utc(2026, 7, 24, 3),
  );

  @override
  Future<LeaderboardPreference> fetchPreference() async {
    fetchCount++;

    return preference;
  }

  @override
  Future<LeaderboardPreference> updateParticipation({
    required bool optIn,
    required String consentVersion,
  }) async {
    requestedOptInValues.add(optIn);

    requestedConsentVersions.add(consentVersion);

    preference = LeaderboardPreference(
      isOptedIn: optIn,
      consentAt: optIn ? DateTime.utc(2026, 7, 24, 4) : null,
      consentVersion: optIn ? consentVersion : null,
      requiredConsentVersion: '1.0',
      serverTime: DateTime.utc(2026, 7, 24, 4),
    );

    return preference;
  }
}

void main() {
  test('memuatkan preference leaderboard '
      'default opt-out', () async {
    final repository = _FakeLeaderboardPreferenceRepository();

    final container = ProviderContainer(
      overrides: [
        leaderboardPreferenceRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    await container
        .read(leaderboardPreferenceControllerProvider.notifier)
        .loadPreference();

    final state = container.read(leaderboardPreferenceControllerProvider);

    expect(state.status, LeaderboardPreferenceStatus.success);

    expect(state.isOptedIn, isFalse);

    expect(state.preference, isNotNull);

    expect(state.preference!.consentAt, isNull);

    expect(repository.fetchCount, 1);
  });

  test('mengaktifkan penyertaan leaderboard '
      'dengan consent version semasa', () async {
    final repository = _FakeLeaderboardPreferenceRepository();

    final container = ProviderContainer(
      overrides: [
        leaderboardPreferenceRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      leaderboardPreferenceControllerProvider.notifier,
    );

    await controller.loadPreference();

    final errorMessage = await controller.updateParticipation(true);

    final state = container.read(leaderboardPreferenceControllerProvider);

    expect(errorMessage, isNull);

    expect(state.status, LeaderboardPreferenceStatus.success);

    expect(state.isOptedIn, isTrue);

    expect(state.preference!.hasCurrentConsent, isTrue);

    expect(repository.requestedOptInValues, [true]);

    expect(repository.requestedConsentVersions, ['1.0']);
  });

  test('mematikan penyertaan membuang consent '
      'aktif', () async {
    final repository = _FakeLeaderboardPreferenceRepository();

    final container = ProviderContainer(
      overrides: [
        leaderboardPreferenceRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(
      leaderboardPreferenceControllerProvider.notifier,
    );

    await controller.loadPreference();

    await controller.updateParticipation(true);

    final errorMessage = await controller.updateParticipation(false);

    final state = container.read(leaderboardPreferenceControllerProvider);

    expect(errorMessage, isNull);

    expect(state.isOptedIn, isFalse);

    expect(state.preference!.consentAt, isNull);

    expect(state.preference!.consentVersion, isNull);

    expect(repository.requestedOptInValues, [true, false]);
  });
}
