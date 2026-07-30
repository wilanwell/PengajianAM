import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/coordinators/topics_load_coordinator.dart';

void main() {
  group('TopicsLoadCoordinator', () {
    test('loadInitial memuatkan topik tanpa force refresh', () async {
      final calls = <String>[];

      final coordinator = TopicsLoadCoordinator(
        loadTopicsAction: (forceRefresh) async {
          calls.add('loadTopics:$forceRefresh');
        },
      );

      await coordinator.loadInitial();

      expect(calls, ['loadTopics:false']);
    });

    test('retryTopics memuatkan topik dengan force refresh', () async {
      final calls = <String>[];

      final coordinator = TopicsLoadCoordinator(
        loadTopicsAction: (forceRefresh) async {
          calls.add('loadTopics:$forceRefresh');
        },
      );

      await coordinator.retryTopics();

      expect(calls, ['loadTopics:true']);
    });

    test('refreshTopics memuatkan topik dengan force refresh', () async {
      final calls = <String>[];

      final coordinator = TopicsLoadCoordinator(
        loadTopicsAction: (forceRefresh) async {
          calls.add('loadTopics:$forceRefresh');
        },
      );

      await coordinator.refreshTopics();

      expect(calls, ['loadTopics:true']);
    });
  });
}
