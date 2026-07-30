import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/controllers/topics_state.dart';
import 'package:pengajian_am_stpm_objektif/features/topics/presentation/coordinators/topics_query_coordinator.dart';

void main() {
  group('TopicsQueryCoordinator', () {
    test('updateSearch menghantar nilai carian', () {
      String? receivedValue;

      final coordinator = TopicsQueryCoordinator(
        searchChangedAction: (value) {
          receivedValue = value;
        },
        clearSearchAction: () {},
        filterChangedAction: (_) {},
      );

      coordinator.updateSearch('perlembagaan');

      expect(receivedValue, 'perlembagaan');
    });

    test('clearSearch menjalankan tindakan kosongkan carian', () {
      var clearCount = 0;

      final coordinator = TopicsQueryCoordinator(
        searchChangedAction: (_) {},
        clearSearchAction: () {
          clearCount++;
        },
        filterChangedAction: (_) {},
      );

      coordinator.clearSearch();

      expect(clearCount, 1);
    });

    test('selectFilter menghantar filter yang dipilih', () {
      TopicProgressFilter? receivedFilter;

      final coordinator = TopicsQueryCoordinator(
        searchChangedAction: (_) {},
        clearSearchAction: () {},
        filterChangedAction: (filter) {
          receivedFilter = filter;
        },
      );

      coordinator.selectFilter(TopicProgressFilter.inProgress);

      expect(receivedFilter, TopicProgressFilter.inProgress);
    });
  });
}
