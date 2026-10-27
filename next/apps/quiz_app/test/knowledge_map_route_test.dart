import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/main.dart';

void main() {
  test(
    'map preview has a standalone route outside the global navigation shell',
    () {
      final router = createRouter(initialLocation: '/atlas/map-preview');
      addTearDown(router.dispose);
      expect(
        router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
        contains('/atlas/map-preview'),
      );
    },
  );
}
