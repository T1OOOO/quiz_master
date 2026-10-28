import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
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
}
