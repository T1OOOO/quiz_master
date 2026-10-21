import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  test(
    'a compact constellation preview retains a recognizable star pattern',
    () {
      final points = projectConstellation([
        {'id': 'a', 'ra_hours': 5.4, 'dec_degrees': 6},
        {'id': 'b', 'ra_hours': 5.7, 'dec_degrees': -2},
        {'id': 'c', 'ra_hours': 5.2, 'dec_degrees': -8},
      ], const Size(40, 40));
      final span = (points['a']! - points['c']!).distance;
      expect(
        span,
        greaterThan(20),
        reason:
            'A 48px picker preview must show a shape, not one collapsed dot.',
      );
      for (final point in points.values) {
        expect(point.dx, inInclusiveRange(0, 40));
        expect(point.dy, inInclusiveRange(0, 40));
      }
    },
  );
}
