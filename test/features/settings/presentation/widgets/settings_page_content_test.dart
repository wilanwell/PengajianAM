import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/leaderboard/presentation/controllers/leaderboard_preference_state.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/domain/entities/app_settings.dart';
import 'package:pengajian_am_stpm_objektif/features/settings/presentation/widgets/settings_page_content.dart';

void main() {
  testWidgets('menyalurkan callback navigation kepada section berkaitan', (
    tester,
  ) async {
    var termsTapCount = 0;
    var privacyTapCount = 0;
    var deleteAccountTapCount = 0;

    await tester.binding.setSurfaceSize(const Size(800, 1200));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPageContent(
            settings: AppSettings.defaults,
            leaderboardPreferenceState: const LeaderboardPreferenceState(),
            isResettingData: false,
            onRefresh: () async {},
            onModeSelected: (_) async {},
            onQuestionCountSelected: (_) async {},
            onLeaderboardParticipationChanged: (_) async {},
            onRetryLeaderboardPreference: () async {},
            onResetData: () async {},
            onTermsOfUseTap: () {
              termsTapCount++;
            },
            onPrivacyPolicyTap: () {
              privacyTapCount++;
            },
            onDeleteAccountTap: () {
              deleteAccountTapCount++;
            },
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-terms-of-use-tile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('settings-terms-of-use-tile')));

    await tester.pump();

    expect(termsTapCount, 1);

    await tester.tap(find.byKey(const Key('settings-privacy-policy-tile')));

    await tester.pump();

    expect(privacyTapCount, 1);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-delete-account-tile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('settings-delete-account-tile')));

    await tester.pump();

    expect(deleteAccountTapCount, 1);
  });
}
