import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_app/knowledge_map/country_fact_reader.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a new atlas session resumes the country reading cycle', () async {
    SharedPreferences.setMockInitialValues({});
    final facts = List.generate(
      3,
      (i) => MapInterestingFact(
        textRu: 'Текст $i',
        textEn: 'Story $i',
        source: Uri.https('example.org', '/$i'),
      ),
    );
    final previous = CountryFactRotation();
    await previous.restore();
    final shown = previous.next('AT', facts);
    final reopened = CountryFactRotation();
    await reopened.restore();
    expect(reopened.next('AT', facts), isNot(shown));
  });

  test(
    'each bundled country and territory has distinct sourced reading choices',
    () {
      Map load(String file) =>
          jsonDecode(File('assets/quizipedia/$file').readAsStringSync()) as Map;
      final editorial =
          load('country_interesting_facts.json')['countries'] as Map;
      final countries = (load('country_facts.json')['countries'] as List)
          .map(
            (c) => MapCountry(
              id: c['id'],
              nameEn: c['name_en'],
              nameRu: c['name_ru'],
              area: c['area_km2'],
              interestingFacts: (editorial[c['id']] as List)
                  .map(MapInterestingFact.fromJson)
                  .whereType<MapInterestingFact>()
                  .toList(),
            ),
          )
          .toList();
      final places = (load('map_v2/landmarks.geojson')['features'] as List)
          .map((f) => MapLandmark.fromProperties(f['properties']))
          .toList();
      final food = load('food_atlas.json');
      final lists = countryReadingLists(
        countries,
        places,
        load('map_v2/capitals.geojson')['features'],
        load('map_feature_facts.json')['capitals'],
        dishes: food['dishes'],
        foodSources: food['sources'],
        storyPacks: countryStoryPacks
            .map((pack) => load('map_v2/$pack.json'))
            .toList(),
      );
      final seine = Uri.parse('https://whc.unesco.org/en/list/600/');
      expect(lists['FR']!.where((f) => f.source == seine), hasLength(1));
      final kimjang = Uri.parse('https://ich.unesco.org/en/RL/00881');
      expect(
        lists['KR']!.where((f) => f.source == kimjang).map((f) => f.subjectEn),
        containsAll(['Local food', 'Traditions and crafts']),
      );
      final deck = CountryFactRotation();
      expect(lists.length, countries.length);
      for (final entry in lists.entries) {
        final facts = entry.value;
        expect(facts.length, greaterThanOrEqualTo(4), reason: entry.key);
        final firstCycle = List.generate(
          facts.length,
          (_) => deck.next(entry.key, facts),
        );
        expect(firstCycle.toSet().length, facts.length);
        expect(deck.next(entry.key, facts), isNot(firstCycle.last));
        expect(
          facts.every(
            (f) =>
                f.source.isScheme('https') &&
                f.textRu.isNotEmpty &&
                f.textEn.isNotEmpty,
          ),
          isTrue,
        );
      }
    },
  );
}
