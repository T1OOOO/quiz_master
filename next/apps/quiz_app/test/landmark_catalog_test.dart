import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'expanded landmark photos have credits and complete fact practice',
    () async {
      final data = jsonDecode(
        await rootBundle.loadString('assets/quizipedia/catalog.json'),
      ) as Map<String, dynamic>;
      final rows = (data['landmarks'] as List).cast<Map<String, dynamic>>();
      expect(rows.length, greaterThanOrEqualTo(46));
      expect(
        rows.map((r) => r['country_iso2']).toSet().length,
        greaterThanOrEqualTo(24),
      );
      final facts = await loadStudyFacts('landmarks');
      expect((await loadStudyFacts('all')).length, 13725);
      final credits = (data['credits'] as List).cast<Map<String, dynamic>>();
      for (final row in rows) {
        expect(await rootBundle.load(row['image_asset'] as String), isNotNull);
        expect(credits.where((c) => c['id'] == row['credit_id']), hasLength(1));
        expect(
          facts
              .where((f) => f.entityId == row['id'])
              .map((f) => f.fieldPath)
              .toSet(),
          containsAll(['city', 'country', 'explanation']),
        );
      }
    },
  );
}
