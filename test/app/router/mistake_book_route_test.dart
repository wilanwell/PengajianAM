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
      expect(
        router.namedLocation(RouteNames.mistakeBook),
        RoutePaths.mistakeBook,
      );
    },
  );
}
