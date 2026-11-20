import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/history_timeline.dart';
import 'package:quiz_app/knowledge_map/history_map_pins.dart';
import 'package:quiz_app/knowledge_map/history_event_symbol.dart';

import 'package:quiz_app/knowledge_map/history_map.dart';

void main() {
  testWidgets(
    'a full-width year slider keeps the timeline stable across events and empty years',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const entries = [
        {'start': 1914, 'end': 1918},
        {'start': 1917, 'end': 1917},
      ];
      var year = 1917;
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, refresh) => HistoryTimeline(
                year: year,
                centuryName: 'XX',
                russian: true,
                countryName: 'Все страны',
                events: entries,
                eventCount: historyEventsFor(entries, year, false, null).length,
                onYear: (v) => refresh(() => year = v),
                pickYear: () {},
                pickCentury: () {},
                pickCountry: () {},
                openEvents: () => opened = true,
              ),
            ),
          ),
        ),
      );
      final slider = find.byType(Slider);
      final timeline = tester.getRect(find.byType(HistoryTimeline));
      final track = tester.getRect(slider);
      expect(track.width, greaterThan(340));
      expect(track.height, greaterThanOrEqualTo(48));
      expect(timeline.height, lessThanOrEqualTo(100));
      await tester.tapAt(Offset(track.left + 30, track.center.dy));
      await tester.pump();
      expect(year, lessThan(1600));
      expect(find.text('0'), findsOneWidget);
      expect(tester.getRect(find.byType(HistoryTimeline)), timeline);
      await tester.tap(find.byTooltip('Следующий год с событием'));
      await tester.pump();
      expect(year, 1914);
      expect(tester.getRect(slider), track);
      await tester.tap(find.text('1'));
      expect(opened, isTrue);
    },
  );

  testWidgets(
    'nearby marks open every member, the caption opens just the focus, and zoom separates them',
    (tester) async {
      const a = (
        longitude: 0.0,
        latitude: 0.0,
        title: 'Island',
        kind: 'culture',
      );
      const b = (
        longitude: 1.0,
        latitude: 0.0,
        title: 'Harbour',
        kind: 'event',
      );
      List<HistoryEventPin>? chosen;
      Widget frame(double separation) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 220,
            child: HistoryMapPins(
              size: const Size(320, 220),
              pins: const [a, b],
              focus: a,
              caption: '1700 · Island',
              russian: true,
              project: (p) => Offset(90 + separation * p.longitude, 90),
              onOpen: (pins) => chosen = pins,
            ),
          ),
        ),
      );
      await tester.pumpWidget(frame(8));
      await tester.tap(find.byTooltip('События рядом · 2'));
      expect(chosen, [a, b]);
      await tester.tap(find.text('1700 · Island'));
      expect(chosen, [a]);
      await tester.pumpWidget(frame(90));
      expect(find.byTooltip('События рядом · 2'), findsNothing);
      await tester.tap(find.byTooltip('Harbour'));
      expect(chosen, [b]);
    },
  );

  group('history map period helpers', () {
    test('maps years to their historical century', () {
      expect(historyCentury(1600), 16);
      expect(historyCentury(1601), 17);
      expect(historyCentury(1900), 19);
      expect(historyCentury(1901), 20);
    });

    final events = <Map>[
      {
        'start': 1598,
        'end': 1602,
        'countries': ['PL', 'SE'],
      },
      {
        'start': 1601,
        'end': 1601,
        'countries': ['SE'],
      },
      {
        'start': 1603,
        'end': 1610,
        'countries': ['FR'],
      },
    ];

    test('filters a year and preserves overlapping events', () {
      final result = historyEventsFor(events, 1601, false, null);
      expect(result, hasLength(2));
      expect(result.map((event) => event['start']), [1598, 1601]);
    });

    test('filters the selected country while retaining its overlaps', () {
      final result = historyEventsFor(events, 1601, false, 'SE');
      expect(result, hasLength(2));
      expect(
        result.every((event) => (event['countries'] as List).contains('SE')),
        isTrue,
      );
      expect(historyEventsFor(events, 1601, false, 'FR'), isEmpty);
    });

    test('whole century uses the selected century range', () {
      expect(historyEventsFor(events, 1601, true, null), hasLength(3));
      expect(historyEventsFor(events, 1601, true, 'FR'), hasLength(1));
    });

    test('timeline preview follows the year and prefers new developments', () {
      expect(closestHistoryEvent(events, 1601), same(events[1]));
      expect(closestHistoryEvent(events, 1609), same(events[2]));
      expect(closestHistoryEvent(events.take(2), 1607), same(events[0]));
      expect(closestHistoryEvent([], 1690), isNull);
    });
  });
}
