import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
  test(
    'cached sprite skips rendering and registration until invalidated',
    () async {
      final cache = <String>{};
      var renders = 0;
      var additions = 0;
      Future<void> request() => ensureMapSprite(
        cache,
        'fr-population-en',
        () async {
          renders++;
        },
        () async {
          additions++;
        },
      );
      await request();
      await request();
      expect(renders, 1);
      expect(additions, 1);
      cache.clear();
      await request();
      expect(renders, 2);
      expect(additions, 2);
    },
  );
  test('failed sprite registration is not cached', () async {
    final cache = <String>{};
    await expectLater(
      ensureMapSprite(
        cache,
        'fr',
        () async {},
        () async => throw StateError('failed'),
      ),
      throwsStateError,
    );
    expect(cache, isEmpty);
  });
}
