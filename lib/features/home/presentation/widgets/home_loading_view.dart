import 'package:flutter/material.dart';

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('home-loading-view'),
      child: CircularProgressIndicator(),
    );
  }
}
