import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_atlas.dart';

void main() {
  test('event country ids are optional and keep reviewed unknown ids', () {
    final base = _event('unknown');
    expect(AtlasEvent.fromJson(base).countryIds, isEmpty);

    base['country_ids'] = ['ZZ'];
    expect(AtlasEvent.fromJson(base).countryIds, ['ZZ']);
    base['country_ids'] = ['US', 'US'];
    expect(() => AtlasEvent.fromJson(base), throwsFormatException);
  });

  testWidgets(
    'history map is lazy, filters reviewed events, and opens the same detail',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var mapBuilds = 0;
      Set<String>? receivedIds;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          home: KnowledgeAtlasPage(
            section: 'history',
            bundle: _KnowledgeBundle(_historyJson()),
            historyEventMapBuilder:
                (
                  context, {
                  required countryIds,
                  required selectedCountryId,
                  required onCountrySelected,
                }) {
                  mapBuilds++;
                  receivedIds = countryIds;
                  return TextButton(
                    key: const Key('test-history-country-us'),
                    onPressed: () => onCountrySelected('US'),
                    child: Text('US ${selectedCountryId ?? ''}'),
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mapBuilds, 0, reason: 'Timeline must not request map geometry.');

      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();
      expect(mapBuilds, greaterThan(0));
      expect(receivedIds, {'EG', 'GB', 'US', 'FR'});
      expect(
        find.text(
          '6 of 7 events have a reviewed location; the rest are available on the timeline.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Modern country areas are only reference points, not historical borders.',
        ),
        findsOneWidget,
      );

      final countryButton = find.byKey(const Key('test-history-country-us'));
      await tester.scrollUntilVisible(
        countryButton,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      tester.widget<TextButton>(countryButton).onPressed!();
      await tester.pumpAndSettle();
      final usEvent = find.byKey(const Key('knowledge-event-american_rev'));
      await tester.scrollUntilVisible(
        usEvent,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(usEvent);
      await tester.pumpAndSettle();
      expect(find.text('american_rev').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, dynamic> _event(String id, {List<String>? countryIds}) => {
  'id': id,
  'year': 1,
  'approximate': false,
  'era': 'modern',
  'title_ru': id == 'american_rev' ? 'Американская революция' : id,
  'title_en': id,
  'what_ru': 'Факт',
  'what_en': 'Fact',
  'why_ru': 'Причина',
  'why_en': 'Reason',
  'consequences_ru': 'Следствие',
  'consequences_en': 'Result',
  'source_url': 'https://example.test/$id',
  'country_ids': ?countryIds,
};

String _historyJson() => jsonEncode({
  'schema_version': 'qm-knowledge-atlas/v1',
  'events': [
    _event('pyramids', countryIds: ['EG']),
    _event('magna', countryIds: ['GB']),
    _event('glorious', countryIds: ['GB']),
    _event('american_rev', countryIds: ['US']),
    _event('french_rev', countryIds: ['FR']),
    _event('civil_rights', countryIds: ['US']),
    _event('unmapped'),
  ],
  'works': [],
  'people': [],
});

class _KnowledgeBundle extends CachingAssetBundle {
  _KnowledgeBundle(this.source);
  final String source;

  @override
  Future<ByteData> load(String key) async => ByteData(0);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => source;
}
