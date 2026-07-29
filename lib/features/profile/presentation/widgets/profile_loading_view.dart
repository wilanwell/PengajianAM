import 'package:flutter/material.dart';

class ProfileLoadingView extends StatelessWidget {
  const ProfileLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('profile-loading-view'),
      child: CircularProgressIndicator(),
    );
  }
}
