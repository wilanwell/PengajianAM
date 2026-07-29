import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_preference_state.dart';
import '../../../quiz/domain/entities/quiz_mode.dart';
import '../../domain/entities/app_settings.dart';
import '../sections/account_management_section.dart';
import '../sections/data_management_section.dart';
import '../sections/leaderboard_privacy_section.dart';
import '../sections/legal_privacy_section.dart';
import '../sections/quiz_preferences_section.dart';
import 'settings_header.dart';

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({
    required this.settings,
    required this.leaderboardPreferenceState,
    required this.isResettingData,
    required this.onRefresh,
    required this.onModeSelected,
    required this.onQuestionCountSelected,
    required this.onLeaderboardParticipationChanged,
    required this.onRetryLeaderboardPreference,
    required this.onResetData,
    required this.onTermsOfUseTap,
    required this.onPrivacyPolicyTap,
    required this.onDeleteAccountTap,
    super.key,
  });

  final AppSettings settings;

  final LeaderboardPreferenceState leaderboardPreferenceState;

  final bool isResettingData;

  final Future<void> Function() onRefresh;

  final Future<void> Function(QuizMode) onModeSelected;

  final Future<void> Function(int) onQuestionCountSelected;

  final Future<void> Function(bool) onLeaderboardParticipationChanged;

  final Future<void> Function() onRetryLeaderboardPreference;

  final Future<void> Function() onResetData;

  final VoidCallback onTermsOfUseTap;

  final VoidCallback onPrivacyPolicyTap;

  final VoidCallback onDeleteAccountTap;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          const SettingsHeader(),
          const SizedBox(height: AppSpacing.lg),
          QuizPreferencesSection(
            settings: settings,
            onModeSelected: onModeSelected,
            onQuestionCountSelected: onQuestionCountSelected,
          ),
          const SizedBox(height: AppSpacing.lg),
          LeaderboardPrivacySection(
            state: leaderboardPreferenceState,
            onChanged: onLeaderboardParticipationChanged,
            onRetry: onRetryLeaderboardPreference,
          ),
          const SizedBox(height: AppSpacing.lg),
          LegalPrivacySection(
            onTermsOfUseTap: onTermsOfUseTap,
            onPrivacyPolicyTap: onPrivacyPolicyTap,
          ),
          const SizedBox(height: AppSpacing.lg),
          DataManagementSection(
            isResetting: isResettingData,
            onReset: onResetData,
          ),
          const SizedBox(height: AppSpacing.lg),
          AccountManagementSection(onDeleteAccountTap: onDeleteAccountTap),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
