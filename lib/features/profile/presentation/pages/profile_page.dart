import 'package:flutter/material.dart';

import '../../../../core/widgets/feature_placeholder_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const SafeArea(
        child: FeaturePlaceholderView(
          icon: Icons.person_rounded,
          title: 'Profil Pelajar',
          description:
              'Maklumat akaun, kemajuan dan tetapan akan dipaparkan di sini.',
        ),
      ),
    );
  }
}
