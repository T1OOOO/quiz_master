import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';
import 'package:quiz_app/knowledge_map/practice_hints.dart';

void main() {
  test('hints progressively exclude other known regions without excluding the answer', () {
    const countries = [
      MapCountry(
        id: 'FR',
        nameRu: 'Франция',
        nameEn: 'France',
        region: 'Europe',
        subregion: 'Western Europe',
      ),
      MapCountry(
        id: 'DE',
        nameRu: 'Германия',
        nameEn: 'Germany',
        region: 'Europe',
        subregion: 'Western Europe',
      ),
      MapCountry(
        id: 'PL',
        nameRu: 'Польша',
        nameEn: 'Poland',
        region: 'Europe',
        subregion: 'Eastern Europe',
      ),
      MapCountry(
        id: 'JP',
        nameRu: 'Япония',
        nameEn: 'Japan',
        region: 'Asia',
        subregion: 'Eastern Asia',
      ),
      MapCountry(id: 'XX', nameRu: 'Неизвестно', nameEn: 'Unknown'),
    ];
    expect(practiceHintExcluded(countries, 'FR', 0), isEmpty);
    expect(practiceHintExcluded(countries, 'FR', 1), {'JP'});
    expect(practiceHintExcluded(countries, 'FR', 2), {'JP', 'PL'});
    expect(practiceHintExcluded(countries, 'XX', 2), isEmpty);
  });
}
