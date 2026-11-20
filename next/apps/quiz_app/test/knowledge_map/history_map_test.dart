import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/history_timeline.dart';
import 'package:quiz_app/knowledge_map/history_map_pins.dart';
import 'package:quiz_app/knowledge_map/history_event_symbol.dart';
import 'package:quiz_app/knowledge_map/history_period.dart'
    show HistoryPeriodDialog;

import 'package:quiz_app/knowledge_map/history_map.dart';

void main() {
  testWidgets(
    'custom period rejects reversed dates and includes the last year',
    (tester) async {
      (int, int, bool)? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<(int, int, bool)>(
                  context: context,
                  builder: (_) => const HistoryPeriodDialog(
                    year: 1733,
                    period: (1733, 1742),
                    russian: true,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, '1700');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextFormField).first, '1698');
      await tester.pump();
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      expect(result, (1698, 3, false));
    },
  );

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
                eventCount: historyEventsFor(entries, year, year, null).length,
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
      final before = year;
      await tester.tap(find.byTooltip('Следующий год'));
      await tester.pump();
      expect(year, before + 1);
      expect(tester.getRect(slider), track);
      await tester.tap(find.text('0'));
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
      final result = historyEventsFor(events, 1601, 1601, null);
      expect(result, hasLength(2));
      expect(result.map((event) => event['start']), [1598, 1601]);
    });

    test('filters the selected country while retaining its overlaps', () {
      final result = historyEventsFor(events, 1601, 1601, 'SE');
      expect(result, hasLength(2));
      expect(
        result.every((event) => (event['countries'] as List).contains('SE')),
        isTrue,
      );
      expect(historyEventsFor(events, 1601, 1601, 'FR'), isEmpty);
    });

    test('whole century uses the selected century range', () {
      expect(historyEventsFor(events, 1601, 1700, null), hasLength(3));
      expect(historyEventsFor(events, 1601, 1700, 'FR'), hasLength(1));
    });

    test('windows include both ends, keep their duration at the edge and preserve ongoing events', () {
      expect(historyPeriod(1733, 10), (1733, 1742));
      expect(historyPeriod(1999, 50), (1951, 2000));
      expect(historyPeriod(1600, 100, calendarCentury: true), (1501, 1600));
      expect(historyEventsFor(events, 1602, 1603, null), [
        events[0],
        events[2],
      ]);
    });

    test('timeline preview follows the year and prefers new developments', () {
      expect(closestHistoryEvent(events, 1601), same(events[1]));
      expect(closestHistoryEvent(events, 1609), same(events[2]));
      expect(closestHistoryEvent(events.take(2), 1607), same(events[0]));
      expect(closestHistoryEvent([], 1690), isNull);
    });
  });
}
