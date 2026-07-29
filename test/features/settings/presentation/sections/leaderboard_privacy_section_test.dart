import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/domain/entities/leaderboard_preference.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_preference_state.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/sections/leaderboard_privacy_section.dart';

void main() {
  testWidgets('memaparkan penyertaan aktif dan versi persetujuan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LeaderboardPrivacySection(
              state: LeaderboardPreferenceState(
                status: LeaderboardPreferenceStatus.success,
                preference: LeaderboardPreference(
                  isOptedIn: true,
                  consentAt: DateTime.utc(2026, 7, 29),
                  consentVersion: '1.0',
                  requiredConsentVersion: '1.0',
                  serverTime: DateTime.utc(2026, 7, 29),
                ),
              ),
              onChanged: (_) async {},
              onRetry: () async {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('settings-leaderboard-privacy-section')),
      findsOneWidget,
    );

    expect(find.text('Privasi Leaderboard'), findsOneWidget);

    expect(find.text('Penyertaan aktif'), findsOneWidget);

    expect(find.text('Persetujuan versi 1.0'), findsOneWidget);

    final participationSwitch = tester.widget<Switch>(
      find.byKey(const Key('settings-leaderboard-switch')),
    );

    expect(participationSwitch.value, isTrue);

    expect(participationSwitch.onChanged, isNotNull);
  });

  testWidgets('menghantar callback apabila penyertaan diaktifkan', (
    tester,
  ) async {
    bool? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LeaderboardPrivacySection(
              state: LeaderboardPreferenceState(
                status: LeaderboardPreferenceStatus.success,
                preference: LeaderboardPreference(
                  isOptedIn: false,
                  requiredConsentVersion: '1.0',
                  serverTime: DateTime.utc(2026, 7, 29),
                ),
              ),
              onChanged: (value) async {
                selectedValue = value;
              },
              onRetry: () async {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-leaderboard-switch')));

    await tester.pump();

    expect(selectedValue, isTrue);
  });

  testWidgets('memaparkan error dan menjalankan callback cuba semula', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LeaderboardPrivacySection(
              state: const LeaderboardPreferenceState(
                status: LeaderboardPreferenceStatus.failure,
                errorMessage: 'Tetapan leaderboard gagal dimuatkan.',
              ),
              onChanged: (_) async {},
              onRetry: () async {
                retryCount++;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('settings-leaderboard-error')), findsOneWidget);

    expect(find.text('Tetapan leaderboard gagal dimuatkan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-leaderboard-retry')));

    await tester.pump();

    expect(retryCount, 1);
  });
}
