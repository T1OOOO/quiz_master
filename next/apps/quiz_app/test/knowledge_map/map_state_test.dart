import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
  test(
    'empty initial visible query retries, but cancellation prevents retry',
    () async {
      var calls = 0;
      final result = await queryVisibleWithRetry(
        () async => ++calls == 1 ? [] : ['FR'],
        () => true,
        () async {},
      );
      expect(result, ['FR']);
      expect(calls, 2);
      calls = 0;
      final cancelled = await queryVisibleWithRetry(
        () async {
          calls++;
          return [];
        },
        () => false,
        () async {},
      );
      expect(cancelled, isEmpty);
      expect(calls, 1);
    },
  );
  test(
    'visible countries deduplicate rendered polygons and ignore unknown IDs',
    () {
      final countries = [
        MapCountry(id: 'FR', nameRu: 'Франция', nameEn: 'France'),
        MapCountry(id: 'DE', nameRu: 'Германия', nameEn: 'Germany'),
      ];
      expect(
        visibleCountries(countries, [
          {
            'properties': {'country_id': 'DE'},
          },
          {
            'properties': {'country_id': 'DE'},
          },
          {
            'properties': {'country_id': 'XX'},
          },
          {
            'properties': {'country_id': 'FR'},
          },
        ]).map((c) => c.id),
        ['FR', 'DE'],
      );
    },
  );
  test(
    'search matches either language and ISO code, then selection can clear',
    () {
      final state = MapState([
        MapCountry(id: 'FR', nameRu: 'Франция', nameEn: 'France'),
        MapCountry(id: 'DE', nameRu: 'Германия', nameEn: 'Germany'),
      ]);
      expect(state.search('fr').single.id, 'FR');
      expect(state.search('герм').single.id, 'DE');
      state.select('FR');
      expect(state.selected?.id, 'FR');
      state.select(null);
      expect(state.selected, isNull);
    },
  );
  test('landmark selection is separate from country selection', () {
    final landmark = MapLandmark.fromProperties({
      'id': 'eiffel',
      'country_id': 'FR',
      'name_en': 'Eiffel Tower',
      'name_ru': 'Эйфелева башня',
      'explanation_en': 'A landmark in Paris.',
      'explanation_ru': 'Достопримечательность Парижа.',
      'source_url': 'https://example.org/source',
      'coordinate_source_url': 'https://example.org/location',
    });
    final state = MapState(
      [MapCountry(id: 'FR', nameRu: 'Франция', nameEn: 'France')],
      landmarks: [landmark],
    );
    state.selectLandmark('eiffel');
    expect(state.selectedLandmark?.nameEn, 'Eiffel Tower');
    expect(state.selected, isNull);
    state.select('FR');
    expect(state.selectedLandmark, isNull);
    expect(state.selected?.id, 'FR');
  });
  test('interesting facts require both languages and an HTTPS source', () {
    expect(
      MapInterestingFact.fromJson({
        'text_ru': 'Факт',
        'text_en': 'Fact',
        'source_url': 'javascript:alert(1)',
      }),
      isNull,
    );
    expect(
      MapInterestingFact.fromJson({
        'text_ru': '',
        'text_en': 'Fact',
        'source_url': 'https://example.org',
      }),
      isNull,
    );
    expect(
      MapInterestingFact.fromJson({
        'text_ru': 'Факт',
        'text_en': 'Fact',
        'source_url': 'https://example.org',
      }),
      isNotNull,
    );
  });
  test('a later tap invalidates an earlier asynchronous query', () {
    final requests = MapTapRequests();
    final first = requests.begin();
    final second = requests.begin();
    expect(requests.isCurrent(second), isTrue);
    expect(requests.isCurrent(first), isFalse);
    requests.invalidate();
    expect(requests.isCurrent(second), isFalse);
  });
}
