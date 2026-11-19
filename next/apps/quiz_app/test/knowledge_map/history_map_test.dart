import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/history_timeline.dart';

import 'package:quiz_app/knowledge_map/history_map.dart';

void main() {
  testWidgets(
    'scrubbing and cycling update the visible story without a dialog',
    (tester) async {
      const entries = [
        {
          'start': 1914,
          'end': 1918,
          'title_ru': 'Долгое событие',
          'kind': 'war',
        },
        {
          'start': 1917,
          'end': 1917,
          'title_ru': 'Событие года',
          'kind': 'revolution',
        },
      ];
      var year = 1917;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => HistoryTimeline(
                year: year,
                centuryName: 'XX',
                russian: true,
                century: false,
                countryName: 'Россия',
                events: entries,
                rows: entries
                    .where(
                      (e) =>
                          (e['start'] as int) <= year &&
                          year <= (e['end'] as int),
                    )
                    .toList(),
                onYear: (v) => refresh(() => year = v),
                pickYear: () {},
                pickCentury: () {},
                pickCountry: () {},
                setCentury: (_) {},
                openEvents: () {},
                openEvent: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Событие года'), findsOneWidget);
      await tester.tap(find.byTooltip('Листать события'));
      await tester.pump();
      expect(find.text('Долгое событие'), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(1903);
      await tester.pump();
      expect(find.textContaining('Ближайшее событие'), findsOneWidget);
      expect(find.text('1903'), findsOneWidget);
      await tester.tap(find.byTooltip('Следующий год с событием'));
      await tester.pump();
      expect(find.text('1914'), findsOneWidget);
      expect(find.textContaining('Ближайшее событие'), findsNothing);
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
