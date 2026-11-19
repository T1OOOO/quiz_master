import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/history_globe.dart';

void main() {
  const pins = [
    (longitude: -15.0, latitude: 30.0, title: 'West', kind: 'war'),
    (longitude: 45.0, latitude: 30.0, title: 'East', kind: 'war'),
  ];

  Future<void> pumpGlobe(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryGlobe(
            land: const [],
            polities: const [],
            year: 1800,
            eventPins: pins,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double markerDistance(WidgetTester tester) {
    final west = tester.getCenter(find.byTooltip('West'));
    final east = tester.getCenter(find.byTooltip('East'));
    return (east - west).distance;
  }

  testWidgets(
    'pinch expands and contracts marker spacing, including second pinch',
    (tester) async {
      await pumpGlobe(tester);
      final center = tester.getCenter(find.byType(HistoryGlobe));
      final initial = markerDistance(tester);

      Future<void> pinch(double amount, {required int firstPointer}) async {
        final one = await tester.startGesture(
          center - const Offset(55, 0),
          pointer: firstPointer,
        );
        final two = await tester.startGesture(
          center + const Offset(55, 0),
          pointer: firstPointer + 1,
        );
        await one.moveTo(center - Offset(55 + amount, 0));
        await two.moveTo(center + Offset(55 + amount, 0));
        await tester.pump();
        await two.up();
        await one.up();
        await tester.pump();
      }

      await pinch(34, firstPointer: 1);
      final expanded = markerDistance(tester);
      expect(expanded, greaterThan(initial * 1.15));

      // A second gesture must remain anchored at the current zoom, rather than
      // jumping back to the first gesture's start scale.
      await pinch(18, firstPointer: 3);
      final expandedAgain = markerDistance(tester);
      expect(expandedAgain, greaterThan(expanded * 1.05));

      await pinch(-30, firstPointer: 5);
      final contracted = markerDistance(tester);
      expect(contracted, lessThan(expandedAgain * .9));
      expect(contracted, greaterThan(initial * .9));
    },
  );

  testWidgets(
    'lifting one contact and canceling the other keeps the globe usable',
    (tester) async {
      await pumpGlobe(tester);
      final center = tester.getCenter(find.byType(HistoryGlobe));
      final one = await tester.startGesture(
        center - const Offset(45, 0),
        pointer: 11,
      );
      final two = await tester.startGesture(
        center + const Offset(45, 0),
        pointer: 12,
      );
      await two.moveBy(const Offset(22, 0));
      await tester.pump();
      await two.cancel();
      await one.moveBy(const Offset(-16, 0));
      await tester.pump();
      await one.up();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('West'), findsOneWidget);
      expect(find.byTooltip('East'), findsOneWidget);
    },
  );

  testWidgets('first inward pinch reduces marker spacing from default zoom', (
    tester,
  ) async {
    await pumpGlobe(tester);
    final before = markerDistance(tester);
    final center = tester.getCenter(find.byType(HistoryGlobe));
    final one = await tester.startGesture(
      center - const Offset(55, 0),
      pointer: 21,
    );
    final two = await tester.startGesture(
      center + const Offset(55, 0),
      pointer: 22,
    );
    await one.moveTo(center - const Offset(24, 0));
    await two.moveTo(center + const Offset(24, 0));
    await tester.pump();
    await two.up();
    await one.up();
    await tester.pump();
    expect(markerDistance(tester), lessThan(before * .9));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('West'), findsOneWidget);
    expect(find.byTooltip('East'), findsOneWidget);
  });
}
