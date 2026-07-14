import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

/// Main application shell containing the persistent bottom navigation.
///
/// Every destination is managed by a separate StatefulShellBranch
/// inside app_router.dart.
class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,

      // ColoredBox turut mewarnakan ruang system navigation bar Android.
      bottomNavigationBar: ColoredBox(
        color: AppColors.surfaceMuted,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: AppColors.surface,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _selectDestination,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                ),
                label: 'Utama',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.menu_book_outlined,
                ),
                selectedIcon: Icon(
                  Icons.menu_book_rounded,
                ),
                label: 'Topik',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.quiz_outlined,
                ),
                selectedIcon: Icon(
                  Icons.quiz_rounded,
                ),
                label: 'Kuiz',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.emoji_events_outlined,
                ),
                selectedIcon: Icon(
                  Icons.emoji_events_rounded,
                ),
                label: 'Ranking',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}