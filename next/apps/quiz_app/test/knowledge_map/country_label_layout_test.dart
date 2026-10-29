import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/country_label_layout.dart';

import 'dart:convert';
import 'dart:io';

void main() {
  const view = GeoViewport(west: 0, east: 10, south: 0, north: 10);
  test('keeps an antimeridian island at the edge of a world view', () {
    const world = GeoViewport(west: -180, east: 180, south: -30, north: 30);
    final point = countryLabelAnchor({
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
    }, world);
    expect(point, isNotNull);
    expect(point!.longitude.abs(), greaterThanOrEqualTo(175));
  });
  test(
    'does not move Canada onto Russia when the view crosses the date line',
    () {
      final data = jsonDecode(
        File('assets/quizipedia/map_v2/countries.geojson').readAsStringSync(),
      ) as Map;
      final features = data['features'] as List;
      final canada = features.firstWhere((f) => f['id'] == 'CA') as Map;
      const cross = GeoViewport(west: -40, east: -140, south: 0, north: 80);
      final point = countryLabelAnchor(canada, cross);
      if (point != null) expect(point.longitude, inInclusiveRange(-180, -140));
      final russia = features.firstWhere((f) => f['id'] == 'RU') as Map;
      final russiaPoint = countryLabelAnchor(russia, cross);
      expect(russiaPoint, isNotNull);
      expect(russiaPoint!.longitude, inInclusiveRange(20, 180));
    },
  );
  test('uses the full outline instead of the first rendered tile fragment', () {
    final label = {
      'properties': {'country_id': 'RU'},
      'geometry': {
        'coordinates': [1, 1],
      },
    };
    Map polygon(List<List<int>> ring) => {
      'properties': {'country_id': 'RU'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [ring],
      },
    };
    final fragment = polygon([
      [0, 0],
      [1, 0],
      [1, 1],
      [0, 1],
      [0, 0],
    ]);
    final full = polygon([
      [0, 0],
      [8, 0],
      [8, 8],
      [0, 8],
      [0, 0],
    ]);
    final result = visibleCountryLabelAnchors(
      [label],
      [fragment],
      view,
      fullOutlines: [full],
    );
    expect(result['RU']!.$1, closeTo(4, .01));
  });
  test(
    'centers the label on the largest visible part, not its first island',
    () {
      final p = countryLabelAnchor({
        'geometry': {
          'type': 'MultiPolygon',
          'coordinates': [
            [
              [
                [0, 0],
                [1, 0],
                [1, 1],
                [0, 1],
                [0, 0],
              ],
            ],
            [
              [
                [2, 2],
                [8, 2],
                [8, 8],
                [2, 8],
                [2, 2],
              ],
            ],
          ],
        },
      }, view)!;
      expect(p.longitude, closeTo(5, .01));
      expect(p.latitude, closeTo(5, .01));
    },
  );

  test('recenters even when the old anchor remains in view', () {
    final labels = [
      {
        'properties': {'country_id': 'RU'},
        'geometry': {
          'coordinates': [1, 1],
        },
      },
    ];
    final visible = [
      {
        'properties': {'country_id': 'RU'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [0, 0],
              [8, 0],
              [8, 8],
              [0, 8],
              [0, 0],
            ],
          ],
        },
      },
    ];
    final point = visibleCountryLabelAnchors(labels, visible, view)['RU']!;
    expect(point.$1, closeTo(4, .01));
    expect(point.$2, closeTo(4, .01));
  });
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
