import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
  test('late hover replies do not restore a country after pointer leaves', () {
    final hover = MapHoverState();
    final old = hover.begin();
    hover.clear();
    expect(hover.complete(old, 'FR', const Offset(20, 30)), isFalse);
    expect(hover.countryId, isNull);
    final current = hover.begin();
    expect(hover.complete(current, 'DE', const Offset(40, 50)), isTrue);
    expect(hover.countryId, 'DE');
  });
  test('hiding landmarks invalidates an unresolved landmark hover', () {
    final hover = MapHoverState();
    final pending = hover.begin();
    hover.clear();
    expect(
      hover.completeLandmark(pending, 'eiffel', const Offset(10, 10)),
      isFalse,
    );
    expect(hover.landmarkId, isNull);
  });
  test('tooltip placement stays inside even a small viewport', () {
    expect(
      clampHoverTooltip(
        const Offset(290, 180),
        const Size(300, 200),
        const Size(100, 60),
      ),
      const Offset(200, 140),
    );
    expect(
      clampHoverTooltip(
        const Offset(-30, -10),
        const Size(70, 40),
        const Size(100, 60),
      ),
      Offset.zero,
    );
  });
}
