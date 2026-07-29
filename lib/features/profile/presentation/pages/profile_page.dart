import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../mistake_book/presentation/controllers/mistake_book_controller.dart';
import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../domain/entities/student_profile.dart';
import '../coordinators/profile_account_coordinator.dart';
import '../coordinators/profile_load_coordinator.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';
import '../dialogs/about_application_dialog.dart';
import '../dialogs/edit_display_name_dialog.dart';
import '../dialogs/logout_confirmation_dialog.dart';
import '../widgets/profile_error_view.dart';
import '../widgets/profile_loading_view.dart';
import '../widgets/profile_page_content.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() {
    return _ProfilePageState();
  }
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref.read(profileLoadCoordinatorProvider).loadInitial();
    });
  }

  Future<void> _refreshProfileContent() {
    return ref.read(profileLoadCoordinatorProvider).refreshAll();
  }

  Future<void> _editDisplayName(StudentProfile profile) async {
    final value = await showEditDisplayNameDialog(
      context,
      initialName: profile.displayName,
    );
    if (!mounted || value == null) {
      return;
    }

    final errorMessage = await ref
        .read(profileAccountCoordinatorProvider)
        .updateDisplayName(value);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Nama paparan telah '
                    'dikemas kini.',
          ),
        ),
      );
  }

  void _showAboutApplication() {
    showAboutApplicationDialog(
      context,
      onTermsOfUseTap: () {
        context.pushNamed(RouteNames.termsOfUse);
      },
      onPrivacyPolicyTap: () {
        context.pushNamed(RouteNames.privacyPolicy);
      },
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    final shouldLogout = await showLogoutConfirmationDialog(context);

    if (!shouldLogout || !mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    final errorMessage = await ref
        .read(profileAccountCoordinatorProvider)
        .logout();

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      context.goNamed(RouteNames.login);

      return;
    }

    setState(() {
      _isLoggingOut = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserProgress>(userProgressControllerProvider, (previous, next) {
      unawaited(
        ref
            .read(profileLoadCoordinatorProvider)
            .synchronizeAfterProgressChange(isLoggingOut: _isLoggingOut),
      );
    });
    final state = ref.watch(profileControllerProvider);

    final mistakeBookState = ref.watch(mistakeBookControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: switch (state.status) {
          ProfileStatus.initial ||
          ProfileStatus.loading => const ProfileLoadingView(),

          ProfileStatus.failure => ProfileErrorView(
            message:
                state.errorMessage ??
                'Profil tidak dapat '
                    'dimuatkan.',
            onRetry: () {
              ref.read(profileLoadCoordinatorProvider).retryProfile();
            },
          ),

          ProfileStatus.success =>
            state.profile == null
                ? ProfileErrorView(
                    message:
                        'Maklumat profil tidak '
                        'tersedia.',
                    onRetry: () {
                      ref.read(profileLoadCoordinatorProvider).retryProfile();
                    },
                  )
                : ProfilePageContent(
                    profile: state.profile!,
                    mistakeBookState: mistakeBookState,
                    isLoggingOut: _isLoggingOut,
                    onRefresh: _refreshProfileContent,
                    onEditName: () {
                      _editDisplayName(state.profile!);
                    },
                    onOpenMistakeBook: () {
                      context.pushNamed(RouteNames.mistakeBook);
                    },
                    onRetryMistakeBook: () {
                      ref
                          .read(profileLoadCoordinatorProvider)
                          .retryMistakeBook();
                    },
                    onOpenAnalytics: () {
                      context.pushNamed(RouteNames.topicAnalytics);
                    },
                    onOpenQuizHistory: () {
                      context.pushNamed(RouteNames.quizHistory);
                    },
                    onOpenSettings: () {
                      context.pushNamed(RouteNames.settings);
                    },
                    onShowAbout: _showAboutApplication,
                    onLogout: _logout,
                  ),
        },
      ),
    );
  }
}
