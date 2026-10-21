import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/belief_atlas_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'shipped relationship atlas loads reviewed nodes and finite section rounds',
    () async {
      final atlas = BeliefAtlas.fromJson(
        jsonDecode(await rootBundle.loadString(beliefAtlasAsset))
            as Map<String, dynamic>,
      );
      expect(atlas.nodes.length, 36);
      expect(atlas.edges.length, 35);
      expect(atlas.nodes.where((n) => n.section == 'greek').length, 24);
      expect(atlas.nodes.where((n) => n.section == 'religions').length, 12);
      final greek = atlas.round('greek', seed: 19),
          religions = atlas.round('religions', seed: 19);
      expect(greek.length, 10);
      expect(religions.length, 9);
      expect(greek.map((q) => q.id).toSet().length, 10);
      expect(
        greek.map((q) => q.id),
        atlas.round('greek', seed: 19).map((q) => q.id),
      );
      for (final q in [...greek, ...religions]) {
        expect(q.options.length, 6);
        expect(q.options.toSet().length, 6);
        expect(q.options.where((id) => id == q.correct).length, 1);
        expect(q.sourceIds, isNotEmpty);
      }
    },
  );
}
