import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/history_timeline.dart';
import 'package:quiz_app/knowledge_map/history_map_pins.dart';
import 'package:quiz_app/knowledge_map/history_event_symbol.dart';
import 'package:quiz_app/knowledge_map/history_period.dart'
    show HistoryPeriodMenu;

import 'package:quiz_app/knowledge_map/history_map.dart';

void main() {
  testWidgets(
    'the year selects all ongoing events, only tapping a pin focuses one',
    (tester) async {
      final records = [
        for (final (title, start, lon) in [
          ('Voyage', 1700, -90),
          ('Treaty', 1701, 90),
        ])
          {
            'title_en': title,
            'summary_en': title,
            'source_url': 'https://example.org',
            'start': start,
            'end': 1703,
            'kind': 'event',
            'countries': ['GB'],
            'location': [lon, 0],
          },
      ];
      final assets = {
        'history_events.json': {'records': records},
        'historical_land.json': [],
        'historical_polity_names_ru.json': {},
        'country_facts.json': {'countries': []},
        'country_labels.geojson': {'features': []},
        'historical_shapes_18.json': {'polities': []},
        'historical_shapes_17.json': {'polities': []},
      };
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (bytes) async {
        final path = utf8.decode(Uint8List.sublistView(bytes!));
        final data = assets[path.split('/').last];
        return data == null
            ? null
            : ByteData.sublistView(
                Uint8List.fromList(utf8.encode(jsonEncode(data))),
              );
      });
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.clear();
      });
      await tester.pumpWidget(
        const MaterialApp(home: HistoryMap(russian: false, initialYear: 1701)),
      );
      await tester.pumpAndSettle();
      HistoryMapPins overlay() => tester.widget(find.byType(HistoryMapPins));
      expect(overlay().pins.map((p) => p.title), ['Voyage', 'Treaty']);
      expect(overlay().focus, isNull);
      await tester.tap(find.text('Events · 2'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(overlay().pins.length, 2);
      await tester.tap(find.byTooltip('Search events'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Voyage');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voyage').last);
      await tester.pumpAndSettle();
      expect(find.text('Source'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to events'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Voyage',
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Treaty'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(overlay().focus?.title, 'Treaty');
      expect(find.byType(Slider), findsNothing);
      await tester.tap(find.text('1701'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('1701 · 2 events'), findsOneWidget);
      expect(find.bySemanticsLabel('1704 · 0 events'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('1702 · 2 events'));
      await tester.pumpAndSettle();
      expect(overlay().focus, isNull);
      expect(overlay().pins, hasLength(2));
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'decade start choices follow the selected step and support exact years',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      (int, int, bool)? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<(int, int, bool)>(
                  context: context,
                  builder: (_) => const HistoryPeriodMenu(
                    year: 1734,
                    step: 10,
                    customRange: false,
                    events: [],
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
      expect(find.bySemanticsLabel('1731–1740 · 0 событий'), findsOneWidget);
      expect(find.bySemanticsLabel('1732–1741 · 0 событий'), findsNothing);
      await tester.tap(find.text('Ввести год'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '1499');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.enterText(find.byType(TextFormField), '1896');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(result, (1896, 10, false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('XX'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('1991–2000 · 0 событий'), findsOneWidget);
      expect(find.bySemanticsLabel('1731–1740 · 0 событий'), findsNothing);
      await tester.tap(find.text('Весь век'));
      await tester.pumpAndSettle();
      expect(result, (1901, 100, false));
    },
  );

  testWidgets('empty decade can browse the nearest year with events', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryPeriodMenu(
          year: 1665,
          step: 1,
          customRange: false,
          russian: true,
          events: [
            {'start': 1590, 'end': 1610},
            {'start': 1675, 'end': 1680},
          ],
        ),
      ),
    );
    await tester.tap(find.text('К событиям 1675 года'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1675 · 1 событие'), findsOneWidget);
    expect(find.text('К событиям 1675 года'), findsNothing);
    expect(find.byType(HistoryPeriodMenu), findsOneWidget);
  });

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
                  builder: (_) => const HistoryPeriodMenu(
                    year: 1733,
                    step: 10,
                    customRange: true,
                    events: [],
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
      expect(result, (1698, 3, true));
    },
  );

  testWidgets(
    'calendar navigation keeps its height across events and empty years',
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
                period: (year, year),
                step: 1,
                russian: true,
                countryName: 'Все страны',
                eventCount: historyEventsFor(entries, year, year, null).length,
                onYear: (v) => refresh(() => year = v),
                openCalendar: () {},
                pickCountry: () {},
                openEvents: () => opened = true,
              ),
            ),
          ),
        ),
      );
      final timeline = tester.getRect(find.byType(HistoryTimeline));
      expect(timeline.height, lessThanOrEqualTo(56));
      expect(find.byType(Slider), findsNothing);
      expect(find.text('События · 2'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Следующий период'));
        await tester.pump();
      }
      expect(year, 1919);
      expect(tester.getRect(find.byType(HistoryTimeline)), timeline);
      await tester.tap(find.text('События · 0'));
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
      Widget frame(double separation, {bool focused = true}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 220,
            child: HistoryMapPins(
              size: const Size(320, 220),
              pins: const [a, b],
              focus: focused ? a : null,
              caption: '1700 · Island',
              russian: true,
              project: (p) => Offset(90 + separation * p.longitude, 90),
              onOpen: (pins) => chosen = pins,
            ),
          ),
        ),
      );
      await tester.pumpWidget(frame(8, focused: false));
      expect(find.text('Island'), findsOneWidget);
      await tester.tap(find.text('Harbour'));
      expect(chosen, [a, b]);
      await tester.pumpWidget(frame(8));
      await tester.tap(find.byTooltip('События рядом · 2\nIsland\nHarbour'));
      expect(chosen, [a, b]);
      await tester.tap(find.text('1700 · Island'));
      expect(chosen, [a]);
      await tester.pumpWidget(frame(90));
      expect(
        find.byTooltip('События рядом · 2\nIsland\nHarbour'),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Harbour'));
      expect(chosen, [b]);
    },
  );

  testWidgets('crowded groups show names outside the occupied band', (
    tester,
  ) async {
    const pins = [
      (longitude: 0.0, latitude: 0.0, title: 'Treaty of Riga', kind: 'treaty'),
      (
        longitude: 1.0,
        latitude: 0.0,
        title: 'Founding of the city',
        kind: 'culture',
      ),
    ];
    List<HistoryEventPin>? chosen;
    const band = Rect.fromLTWH(0, 95, 320, 120);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 310,
            child: HistoryMapPins(
              size: const Size(320, 310),
              pins: pins,
              project: (p) => Offset(155 + p.longitude, 155),
              focus: null,
              caption: null,
              russian: false,
              obstacles: const [band],
              onOpen: (v) => chosen = v,
            ),
          ),
        ),
      ),
    );
    final caption = find.text('Treaty of Riga');
    expect(tester.getRect(caption).overlaps(band), isFalse);
    await tester.tap(caption);
    expect(chosen, pins);
  });

  testWidgets(
    'edge captions stay inside the map and clear nearby tap targets',
    (tester) async {
      final pins = [
        for (final (x, y, title) in [
          (12.0, 8.0, 'Harbour'),
          (18.0, 70.0, 'Bridge'),
          (112.0, 8.0, 'Fort'),
        ])
          (longitude: x, latitude: y, title: title, kind: 'event'),
      ];
      List<HistoryEventPin>? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 290,
              height: 180,
              child: HistoryMapPins(
                size: const Size(290, 180),
                pins: pins,
                focus: pins.first,
                caption: '1700 · Harbour',
                russian: true,
                project: (p) => Offset(p.longitude, p.latitude),
                onOpen: (v) => chosen = v,
              ),
            ),
          ),
        ),
      );
      final bounds = tester.getRect(find.byType(HistoryMapPins));
      final targets = [
        for (final p in pins) tester.getRect(find.byTooltip(p.title)),
      ];
      final labels = <Rect>[];
      for (final title in ['1700 · Harbour', 'Bridge', 'Fort']) {
        final label = tester.getRect(find.text(title));
        expect(bounds.intersect(label), label);
        expect([...targets, ...labels].any(label.overlaps), isFalse);
        labels.add(label);
      }
      for (final p in pins) {
        await tester.tap(find.byTooltip(p.title));
        expect(chosen, [p]);
      }
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

    test(
      'windows include both ends, stop at 2000 and preserve ongoing events',
      () {
        expect(historyPeriod(1733, 10), (1733, 1742));
        expect(historyPeriod(1999, 50), (1999, 2000));
        expect(historyEventsFor(events, 1602, 1603, null), [
          events[0],
          events[2],
        ]);
      },
    );
  });
}
