import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pengajian_am_stpm_objektif/app/router/app_router.dart';
import 'package:pengajian_am_stpm_objektif/app/router/route_names.dart';

void main() {
  test(
    'mendaftarkan route Buku Kesilapan dengan nama dan path yang stabil',
    () {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);

      expect(RouteNames.mistakeBook, 'mistake-book');
      expect(RoutePaths.mistakeBook, '/mistake-book');
      expect(RouteNames.mistakeBookTopic, 'mistake-book-topic');
      expect(RoutePaths.mistakeBookTopic, '/mistake-book/:topicId');
      expect(RouteNames.mistakeReviewSession, 'mistake-review-session');
      expect(
        RoutePaths.mistakeReviewSession,
        '/mistake-book/:topicId/review-session',
      );
      expect(
        router.namedLocation(RouteNames.mistakeBook),
        RoutePaths.mistakeBook,
      );
      expect(
        router.namedLocation(
          RouteNames.mistakeBookTopic,
          pathParameters: {'topicId': 'topic-s1-01'},
        ),
        '/mistake-book/topic-s1-01',
      );
      expect(
        router.namedLocation(
          RouteNames.mistakeReviewSession,
          pathParameters: {'topicId': 'topic-s1-01'},
          queryParameters: {'questionCount': '15'},
        ),
        '/mistake-book/topic-s1-01/review-session?questionCount=15',
      );
    },
  );
}
