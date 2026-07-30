import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../domain/entities/study_topic.dart';
import '../controllers/topics_controller.dart';
import '../controllers/topics_state.dart';
import '../coordinators/topics_load_coordinator.dart';
import '../coordinators/topics_query_coordinator.dart';
import '../widgets/topics_error_view.dart';
import '../widgets/topics_loading_view.dart';
import '../widgets/topics_page_content.dart';

class TopicsPage extends ConsumerStatefulWidget {
  const TopicsPage({super.key});

  @override
  ConsumerState<TopicsPage> createState() {
    return _TopicsPageState();
  }
}

class _TopicsPageState extends ConsumerState<TopicsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      return ref.read(topicsLoadCoordinatorProvider).loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();

    ref.read(topicsQueryCoordinatorProvider).clearSearch();
  }

  void _retryLoadingTopics() {
    unawaited(ref.read(topicsLoadCoordinatorProvider).retryTopics());
  }

  void _openTopic(StudyTopic topic) {
    context.goNamed(RouteNames.quiz, queryParameters: {'topicId': topic.id});
  }

  @override
  Widget build(BuildContext context) {
    final topicsState = ref.watch(topicsControllerProvider);

    final queryCoordinator = ref.read(topicsQueryCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Topik Pembelajaran')),
      body: SafeArea(
        child: switch (topicsState.status) {
          TopicsStatus.initial ||
          TopicsStatus.loading => const TopicsLoadingView(),

          TopicsStatus.failure => TopicsErrorView(
            message:
                topicsState.errorMessage ??
                'Senarai topik tidak dapat '
                    'dimuatkan.',
            onRetry: _retryLoadingTopics,
          ),

          TopicsStatus.success => TopicsPageContent(
            state: topicsState,
            searchController: _searchController,
            onSearchChanged: queryCoordinator.updateSearch,
            onClearSearch: _clearSearch,
            onFilterSelected: queryCoordinator.selectFilter,
            onRefresh: ref.read(topicsLoadCoordinatorProvider).refreshTopics,
            onTopicSelected: _openTopic,
          ),
        },
      ),
    );
  }
}
