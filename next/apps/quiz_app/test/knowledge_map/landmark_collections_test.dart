import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'wonder collections contain seven uniquely identified sourced places each',
    () async {
      final json = jsonDecode(
        await rootBundle.loadString(
          'assets/quizipedia/map_v2/landmarks.geojson',
        ),
      ) as Map;
      final features = json['features'] as List;
      final ids = <String>{};
      final counts = <String, int>{
        'ancient_wonders': 0,
        'new_wonders': 0,
        'nature_wonders': 0,
      };
      for (final raw in features) {
        final feature = raw as Map;
        final p = feature['properties'] as Map;
        final id = p['id'] as String;
        expect(feature['id'], id);
        expect(ids.add(id), isTrue, reason: 'Duplicate landmark $id');
        expect(p['country_id'], matches(RegExp(r'^[A-Z]{2}$')));
        for (final key in [
          'name_ru',
          'name_en',
          'explanation_ru',
          'explanation_en',
        ]) {
          expect((p[key] as String).trim(), isNotEmpty, reason: '$id: $key');
        }
        for (final key in ['source_url', 'coordinate_source_url']) {
          final uri = Uri.parse(p[key] as String);
          expect(uri.scheme, 'https', reason: '$id: $key');
          expect(uri.host, isNotEmpty);
        }
        final geometry = feature['geometry'] as Map;
        expect(geometry['type'], 'Point');
        final coordinates = geometry['coordinates'] as List;
        expect(coordinates[0] as num, inInclusiveRange(-180, 180));
        expect(coordinates[1] as num, inInclusiveRange(-90, 90));
        for (final category in (p['categories'] as List? ?? const [])) {
          if (counts.containsKey(category)) {
            counts[category as String] = counts[category]! + 1;
          }
        }
      }
      expect(counts.values, everyElement(7));
      for (final category in [
        'mountains',
        'depressions',
        'deserts',
        'reserves',
      ]) {
        final total = features
            .where(
              (f) =>
                  ((f['properties'] as Map)['categories'] as List? ?? const [])
                      .contains(category),
            )
            .length;
        expect(total, greaterThanOrEqualTo(3), reason: category);
      }
    },
  );
}
