import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/history_globe.dart';

void main() {
  test('orthographic projection rejects the back hemisphere', () {
    expect(projectGlobePoint(0, 0, 0, 0), isNotNull);
    expect(projectGlobePoint(180, 0, 0, 0), isNull);
    expect(projectGlobePoint(90, 0, 0, 0)!.dx, closeTo(1, 1e-8));
  });
  testWidgets('globe supports zoom and drag', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryGlobe(
            land: const [],
            polities: const [],
            year: 1800,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.drag(find.byType(CustomPaint).last, const Offset(40, 10));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('selects a visible polity and ignores a back-facing one', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryGlobe(
            land: const [],
            year: 1800,
            polities: const [
              GlobePolity(
                name: 'Front',
                polygons: [
                  [
                    [
                      [10, 25],
                      [20, 25],
                      [20, 35],
                      [10, 35],
                      [10, 25],
                    ],
                  ],
                ],
              ),
              GlobePolity(
                name: 'Back',
                polygons: [
                  [
                    [
                      [170, 25],
                      [-170, 25],
                      [-170, 35],
                      [170, 35],
                      [170, 25],
                    ],
                  ],
                ],
              ),
            ],
            onSelect: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.byType(HistoryGlobe)));
    await tester.pump();
    expect(selected, 'Front');
  });
  testWidgets('C-shaped polygon agrees with inverse projection at horizon', (
    tester,
  ) async {
    final corners = <List<double>>[
      [135, -35],
      [50, -35],
      [50, -15],
      [110, -15],
      [110, 15],
      [50, 15],
      [50, 40],
      [135, 40],
      [135, -35],
    ];
    final ring = <List<double>>[];
    for (var i = 0; i < corners.length - 1; i++) {
      final a = corners[i], b = corners[i + 1];
      final steps = math.max((b[0] - a[0]).abs(), (b[1] - a[1]).abs()).ceil();
      for (var j = 0; j < steps; j++) {
        final t = j / steps;
        ring.add([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
      }
    }
    ring.add(corners.last);
    final reference = Path()..moveTo(corners[0][0], corners[0][1]);
    for (final p in corners.skip(1)) {
      reference.lineTo(p[0], p[1]);
    }
    reference.close();
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryGlobe(
            land: const [],
            year: 1800,
            polities: [
              GlobePolity(
                name: 'C',
                polygons: [
                  [ring],
                ],
              ),
            ],
            onSelect: (v) => selected = v,
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(HistoryGlobe));
    final center = rect.center;
    final radius = math.min(rect.width, rect.height) * .47;
    final lat0 = 30 * math.pi / 180;
    var checked = 0;
    for (var ix = -8; ix <= 8; ix++) {
      for (var iy = -8; iy <= 8; iy++) {
        final x = ix / 10, y = iy / 10;
        if (x * x + y * y >= .90) continue;
        final z = math.sqrt(1 - x * x - y * y);
        final lat =
            math.asin(z * math.sin(lat0) - y * math.cos(lat0)) * 180 / math.pi;
        final lon =
            15 +
            math.atan2(x, z * math.cos(lat0) + y * math.sin(lat0)) *
                180 /
                math.pi;
        if ([50.0, 110.0, 135.0].any((v) => (lon - v).abs() < 1) ||
            [-35.0, -15.0, 15.0, 40.0].any((v) => (lat - v).abs() < 1)) {
          continue;
        }
        selected = null;
        await tester.tapAt(center + Offset(x * radius, y * radius));
        await tester.pump();
        final expected = reference.contains(Offset(lon, lat));
        expect(
          selected == 'C',
          expected,
          reason: 'lon=$lon lat=$lat screen=$x,$y',
        );
        checked++;
      }
    }
    expect(checked, greaterThan(50));
  });
  testWidgets(
    'opposite C-shaped polygon agrees with inverse projection at horizon',
    (tester) async {
      final corners = <List<double>>[
        [50, -35],
        [135, -35],
        [135, -15],
        [75, -15],
        [75, 15],
        [135, 15],
        [135, 40],
        [50, 40],
        [50, -35],
      ];
      final ring = <List<double>>[];
      for (var i = 0; i < corners.length - 1; i++) {
        final a = corners[i], b = corners[i + 1];
        final steps = math.max((b[0] - a[0]).abs(), (b[1] - a[1]).abs()).ceil();
        for (var j = 0; j < steps; j++) {
          final t = j / steps;
          ring.add([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
        }
      }
      ring.add(corners.last);
      final reference = Path()..moveTo(corners[0][0], corners[0][1]);
      for (final p in corners.skip(1)) {
        reference.lineTo(p[0], p[1]);
      }
      reference.close();
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryGlobe(
              land: const [],
              year: 1800,
              polities: [
                GlobePolity(
                  name: 'C',
                  polygons: [
                    [ring],
                  ],
                ),
              ],
              onSelect: (v) => selected = v,
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(HistoryGlobe));
      final center = rect.center;
      final radius = math.min(rect.width, rect.height) * .47;
      final lat0 = 30 * math.pi / 180;
      var checked = 0;
      for (var ix = -8; ix <= 8; ix++) {
        for (var iy = -8; iy <= 8; iy++) {
          final x = ix / 10, y = iy / 10;
          if (x * x + y * y >= .90) continue;
          final z = math.sqrt(1 - x * x - y * y);
          final lat =
              math.asin(z * math.sin(lat0) - y * math.cos(lat0)) *
              180 /
              math.pi;
          final lon =
              15 +
              math.atan2(x, z * math.cos(lat0) + y * math.sin(lat0)) *
                  180 /
                  math.pi;
          if ([50.0, 75.0, 135.0].any((v) => (lon - v).abs() < 1) ||
              [-35.0, -15.0, 15.0, 40.0].any((v) => (lat - v).abs() < 1)) {
            continue;
          }
          selected = null;
          await tester.tapAt(center + Offset(x * radius, y * radius));
          await tester.pump();
          final expected = reference.contains(Offset(lon, lat));
          expect(
            selected == 'C',
            expected,
            reason: 'lon=$lon lat=$lat screen=$x,$y',
          );
          checked++;
        }
      }
      expect(checked, greaterThan(50));
    },
  );
  testWidgets('real land avoids a giant Eurasian fill', (tester) async {
    final raw = jsonDecode(
      File('assets/quizipedia/map_v2/historical_land.json').readAsStringSync(),
    ) as List;
    final reference = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in raw) {
      for (final ring in polygon) {
        if (ring.length < 3) continue;
        var crossesDateLine = false;
        for (var i = 1; i < ring.length; i++) {
          if (((ring[i][0] as num) - (ring[i - 1][0] as num)).abs() > 180) {
            crossesDateLine = true;
          }
        }
        if (crossesDateLine) continue;
        reference.moveTo(
          (ring[0][0] as num).toDouble(),
          (ring[0][1] as num).toDouble(),
        );
        for (final p in ring.skip(1)) {
          reference.lineTo((p[0] as num).toDouble(), (p[1] as num).toDouble());
        }
        reference.close();
      }
    }
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryGlobe(
            land: const [],
            year: 1800,
            polities: [GlobePolity(name: 'land', polygons: raw)],
            onSelect: (v) => selected = v,
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(HistoryGlobe)),
        center = rect.center;
    final radius = math.min(rect.width, rect.height) * .47,
        lat0 = 30 * math.pi / 180;
    var checked = 0;
    for (var ix = -8; ix <= 8; ix++) {
      for (var iy = -8; iy <= 8; iy++) {
        final x = ix / 10, y = iy / 10;
        if (x * x + y * y >= .85) continue;
        final z = math.sqrt(1 - x * x - y * y);
        final lat =
            math.asin(z * math.sin(lat0) - y * math.cos(lat0)) * 180 / math.pi;
        final lon =
            15 +
            math.atan2(x, z * math.cos(lat0) + y * math.sin(lat0)) *
                180 /
                math.pi;
        if (lon < -60 || lon > 100) continue;
        final expected = reference.contains(Offset(lon, lat));
        if ([
          const Offset(-1, 0),
          const Offset(1, 0),
          const Offset(0, -1),
          const Offset(0, 1),
        ].any((o) => reference.contains(Offset(lon, lat) + o) != expected)) {
          continue;
        }
        selected = null;
        await tester.tapAt(center + Offset(x * radius, y * radius));
        await tester.pump();
        expect(selected == 'land', expected, reason: 'lon=$lon lat=$lat');
        checked++;
      }
    }
    expect(checked, greaterThan(30));
  });
  testWidgets('1914 Russian Empire avoids a giant Eurasian fill', (
    tester,
  ) async {
    final data = jsonDecode(
      File('assets/quizipedia/map_v2/historical_shapes_20.json')
          .readAsStringSync(),
    );
    final raw =
        (data['polities'] as List).firstWhere(
              (row) =>
                  row[0] == 'Russian Empire' &&
                  row[1] <= 1914 &&
                  row[2] >= 1914,
            )[3]
            as List;
    final reference = Path()..fillType = PathFillType.evenOdd;
    for (final polygon in raw) {
      for (final ring in polygon) {
        if (ring.length < 3) continue;
        var crossesDateLine = false;
        for (var i = 1; i < ring.length; i++) {
          if (((ring[i][0] as num) - (ring[i - 1][0] as num)).abs() > 180) {
            crossesDateLine = true;
          }
        }
        if (crossesDateLine) continue;
        reference.moveTo(
          (ring[0][0] as num).toDouble(),
          (ring[0][1] as num).toDouble(),
        );
        for (final p in ring.skip(1)) {
          reference.lineTo((p[0] as num).toDouble(), (p[1] as num).toDouble());
        }
        reference.close();
      }
    }
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryGlobe(
            land: const [],
            year: 1800,
            polities: [GlobePolity(name: 'land', polygons: raw)],
            onSelect: (v) => selected = v,
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(HistoryGlobe)),
        center = rect.center;
    final radius = math.min(rect.width, rect.height) * .47,
        lat0 = 30 * math.pi / 180;
    var checked = 0;
    for (var ix = -8; ix <= 8; ix++) {
      for (var iy = -8; iy <= 8; iy++) {
        final x = ix / 10, y = iy / 10;
        if (x * x + y * y >= .85) continue;
        final z = math.sqrt(1 - x * x - y * y);
        final lat =
            math.asin(z * math.sin(lat0) - y * math.cos(lat0)) * 180 / math.pi;
        final lon =
            15 +
            math.atan2(x, z * math.cos(lat0) + y * math.sin(lat0)) *
                180 /
                math.pi;
        if (lon < -60 || lon > 100) continue;
        final expected = reference.contains(Offset(lon, lat));
        if ([
          const Offset(-1, 0),
          const Offset(1, 0),
          const Offset(0, -1),
          const Offset(0, 1),
        ].any((o) => reference.contains(Offset(lon, lat) + o) != expected)) {
          continue;
        }
        selected = null;
        await tester.tapAt(center + Offset(x * radius, y * radius));
        await tester.pump();
        expect(selected == 'land', expected, reason: 'lon=$lon lat=$lat');
        checked++;
      }
    }
    expect(checked, greaterThan(30));
  });
}
