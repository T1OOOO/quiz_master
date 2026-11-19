import 'package:flutter_test/flutter_test.dart';

import 'package:quiz_app/knowledge_map/history_map.dart';

void main() {
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
  });
}
