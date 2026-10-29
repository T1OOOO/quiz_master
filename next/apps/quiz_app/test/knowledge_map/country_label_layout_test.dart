import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/country_label_layout.dart';

void main() {
  const view = GeoViewport(west: 0, east: 10, south: 0, north: 10);
  test('relocates an offscreen label to the visible country fragment', () {
    final labels = [
      {
        'properties': {'country_id': 'FR'},
        'geometry': {
          'type': 'Point',
          'coordinates': [-10.0, 5.0],
        },
      },
    ];
    final visible = [
      {
        'properties': {'country_id': 'FR'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-20, 2],
              [2, 2],
              [2, 8],
              [-20, 8],
              [-20, 2],
            ],
          ],
        },
      },
    ];
    final anchors = visibleCountryLabelAnchors(labels, visible, view);
    expect(anchors.keys, contains('FR'));
    expect(anchors['FR']!.$1, inInclusiveRange(0, 2));
    expect(anchors['FR']!.$2, inInclusiveRange(2, 8));
  });

  test('clips a country edge when centroid is outside viewport', () {
    final p = countryLabelAnchor({
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-5, 2],
            [5, 2],
            [5, 8],
            [-5, 8],
            [-5, 2],
          ],
        ],
      },
    }, view);
    expect(p, isNotNull);
    expect(p!.longitude, inInclusiveRange(0, 10));
    expect(p.latitude, inInclusiveRange(0, 10));
  });

  test('uses viewport center when viewport is inside a polygon', () {
    final p = countryLabelAnchor({
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-20, -20],
            [20, -20],
            [20, 20],
            [-20, 20],
            [-20, -20],
          ],
        ],
      },
    }, view);
    expect(p!.longitude, closeTo(5, 0.001));
    expect(p.latitude, closeTo(5, 0.001));
  });

  test('handles antimeridian viewport', () {
    const v = GeoViewport(west: 170, east: -170, south: -10, north: 10);
    final p = countryLabelAnchor({
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [175, -5],
            [-175, -5],
            [-175, 5],
            [175, 5],
            [175, -5],
          ],
        ],
      },
    }, v);
    expect(p, isNotNull);
    expect(v.contains(p!.longitude, p.latitude), isTrue);
  });

  test('does not average separate islands into ocean', () {
    final p = countryLabelAnchor({
      'geometry': {
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [1, 1],
              [2, 1],
              [2, 2],
              [1, 2],
              [1, 1],
            ],
          ],
          [
            [
              [8, 8],
              [9, 8],
              [9, 9],
              [8, 9],
              [8, 8],
            ],
          ],
        ],
      },
    }, view);
    expect(p, isNotNull);
    expect(p!.longitude, inInclusiveRange(1, 2));
  });

  test('does not use a point inside a polygon hole', () {
    final p = countryLabelAnchor({
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-20, -20],
            [20, -20],
            [20, 20],
            [-20, 20],
            [-20, -20],
          ],
          [
            [-2, -2],
            [2, -2],
            [2, 2],
            [-2, 2],
            [-2, -2],
          ],
        ],
      },
    }, view);
    expect(p, isNotNull);
    expect(p!.longitude.abs() >= 2 || p.latitude.abs() >= 2, isTrue);
  });
}
