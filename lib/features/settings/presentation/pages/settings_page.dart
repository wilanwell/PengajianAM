import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_preference_controller.dart';
import '../../../quiz/domain/entities/quiz_mode.dart';
import '../coordinators/settings_data_reset_coordinator.dart';
import '../coordinators/settings_leaderboard_participation_coordinator.dart';
import '../coordinators/settings_load_coordinator.dart';
import '../dialogs/leaderboard_participation_dialog.dart';
import '../dialogs/reset_learning_data_dialog.dart';
import '../controllers/app_settings_controller.dart';
import '../controllers/app_settings_state.dart';

import '../widgets/settings_error_view.dart';

import '../widgets/settings_page_content.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isResettingData = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref.read(settingsLoadCoordinatorProvider).loadInitial();
    });
  }

  Future<void> _updateDefaultMode(QuizMode mode) async {
    final errorMessage = await ref
        .read(appSettingsControllerProvider.notifier)
        .updateDefaultQuizMode(mode);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Mode kuiz lalai telah '
                    'dikemas kini.',
          ),
        ),
      );
  }

  Future<void> _updateDefaultQuestionCount(int questionCount) async {
    final errorMessage = await ref
        .read(appSettingsControllerProvider.notifier)
        .updateDefaultQuestionCount(questionCount);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Jumlah soalan lalai telah '
                    'dikemas kini.',
          ),
        ),
      );
  }

  Future<void> _updateLeaderboardParticipation(bool optIn) async {
    final preferenceState = ref.read(leaderboardPreferenceControllerProvider);

    if (preferenceState.isBusy) {
      return;
    }

    final shouldUpdate = await showLeaderboardParticipationDialog(
      context,
      optIn: optIn,
    );
    if (shouldUpdate != true || !mounted) {
      return;
    }

    final errorMessage = await ref
        .read(settingsLeaderboardParticipationCoordinatorProvider)
        .updateParticipation(optIn);

    if (!mounted) {
      return;
    }
    final successMessage = optIn
        ? 'Anda kini menyertai leaderboard.'
        : 'Anda tidak lagi menyertai leaderboard.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorMessage ?? successMessage)));
  }

  Future<void> _resetAllData() async {
    if (_isResettingData) {
      return;
    }

    final shouldReset = await showResetLearningDataDialog(context);
    if (shouldReset != true || !mounted) {
      return;
    }

    setState(() {
      _isResettingData = true;
    });

    final errorMessage = await ref
        .read(settingsDataResetCoordinatorProvider)
        .resetAllData();
    if (!mounted) {
      return;
    }

    setState(() {
      _isResettingData = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Semua data pembelajaran '
                    'telah direset.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSettingsControllerProvider);

    final leaderboardPreferenceState = ref.watch(
      leaderboardPreferenceControllerProvider,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Tetapan')),
      body: SafeArea(
        child: switch (state.status) {
          AppSettingsStatus.initial || AppSettingsStatus.loading =>
            const Center(child: CircularProgressIndicator()),

          AppSettingsStatus.failure => SettingsErrorView(
            message: state.errorMessage ?? 'Tetapan tidak dapat dimuatkan.',
            onRetry: () {
              unawaited(
                ref.read(settingsLoadCoordinatorProvider).retrySettings(),
              );
            },
          ),
          AppSettingsStatus.success => SettingsPageContent(
            settings: state.settings,
            leaderboardPreferenceState: leaderboardPreferenceState,
            isResettingData: _isResettingData,
            onRefresh: () {
              return ref.read(settingsLoadCoordinatorProvider).refreshAll();
            },
            onModeSelected: _updateDefaultMode,
            onQuestionCountSelected: _updateDefaultQuestionCount,
            onLeaderboardParticipationChanged: _updateLeaderboardParticipation,
            onRetryLeaderboardPreference: () {
              return ref
                  .read(settingsLoadCoordinatorProvider)
                  .retryLeaderboardPreference();
            },
            onResetData: _resetAllData,
            onTermsOfUseTap: () {
              context.pushNamed(RouteNames.termsOfUse);
            },
            onPrivacyPolicyTap: () {
              context.pushNamed(RouteNames.privacyPolicy);
            },
            onDeleteAccountTap: () {
              context.pushNamed(RouteNames.deleteAccount);
            },
          ),
        },
      ),
    );
  }
}
