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
    const coordinates = {
      'FR': [2.0, 49.0],
      'DE': [13.0, 52.0],
      'PL': [21.0, 52.0],
      'JP': [140.0, 36.0],
    };
    expect(
      practiceHintExcluded(countries, 'FR', 0, coordinates: coordinates),
      isEmpty,
    );
    final first = practiceHintExcluded(
      countries,
      'FR',
      1,
      coordinates: coordinates,
    );
    final fourth = practiceHintExcluded(
      countries,
      'FR',
      4,
      coordinates: coordinates,
    );
    final last = practiceHintExcluded(
      countries,
      'FR',
      5,
      coordinates: coordinates,
    );
    expect(first, contains('JP'));
    expect(fourth, containsAll(first));
    expect(last, containsAll(fourth));
    expect(last, contains('PL'));
    expect(last, isNot(contains('FR')));
    expect(last, isNot(contains('XX')));
    expect(practiceHintRegion(countries, 'FR'), {'FR', 'DE'});
    expect(practiceHintRegion(countries, 'XX'), isEmpty);
    final farCoordinates = {
      ...coordinates,
      'DE': [100.0, 52.0],
    };
    expect(
      practiceHintExcluded(countries, 'FR', 4, coordinates: farCoordinates),
      contains('DE'),
    );
    expect(
      practiceHintExcluded(countries, 'FR', 5, coordinates: farCoordinates),
      isNot(contains('DE')),
    );
  });
}
