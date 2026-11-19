import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/knowledge_map_page.dart';

void main() {
  test('each selectable sea or ocean has a story in both languages', () {
    Map asset(String file) =>
        jsonDecode(File('assets/quizipedia/$file').readAsStringSync()) as Map;
    final facts = asset('map_feature_facts.json')['waterways'] as Map;
    final marine = (asset('map_v2/waterways.geojson')['features'] as List)
        .map((f) => f['properties'] as Map)
        .where((p) => p['kind'] == 'marine');
    expect(marine, isNotEmpty);
    for (final feature in marine) {
      final rows = facts[waterFeatureId(feature)] as List;
      expect(
        rows.any(
          (row) =>
              (row['text_ru'] as String).isNotEmpty &&
              (row['text_en'] as String).isNotEmpty &&
              Uri.parse(row['source_url']).isScheme('https'),
        ),
        isTrue,
        reason: feature['name_en'],
      );
    }
  });
  test('water identity prefers canonical detailed geometry id', () {
    expect(waterFeatureId({'id': 'detail-1', 'water_id': 'Q1062'}), 'Q1062');
    expect(waterFeatureId({'id': 'Q123'}), 'Q123');
    expect(waterFeatureId({'id': 'detail-1', 'water_id': ''}), 'detail-1');
  });
  test('a sea takes priority over an overlapping ocean', () {
    final features = [
      {
        'properties': {'name_en': 'Indian Ocean', 'id': 'ocean'},
      },
      {
        'properties': {'name_en': 'Arabian Sea', 'id': 'sea'},
      },
    ];
    expect(preferredMarineFeature(features)?['properties']['id'], 'sea');
    expect(
      preferredMarineFeature(features.take(1).toList())?['properties']['id'],
      'ocean',
    );
    expect(preferredMarineFeature([]), isNull);
  });
}
