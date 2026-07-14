import 'package:flutter/material.dart';

import '../../../../core/widgets/feature_placeholder_view.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topik Pembelajaran')),
      body: const SafeArea(
        child: FeaturePlaceholderView(
          icon: Icons.menu_book_rounded,
          title: 'Topik Semester 1',
          description:
              'Senarai topik Pengajian AM STPM akan dipaparkan di sini.',
        ),
      ),
    );
  }
}
