import 'package:flutter/material.dart';

class TopicsLoadingView extends StatelessWidget {
  const TopicsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('topics-loading-view'),
      child: CircularProgressIndicator(),
    );
  }
}
