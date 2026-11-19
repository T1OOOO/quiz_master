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
}
