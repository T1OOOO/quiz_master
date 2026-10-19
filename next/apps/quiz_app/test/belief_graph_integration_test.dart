import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/belief_atlas.dart';
import 'package:quiz_app/belief_atlas_models.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.data);
  final String data;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(data);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError('text only');
}

void main() {
  test('arrow tips remain outside target buttons from every direction', () {
    const target = Rect.fromLTWH(205, 36, 140, 56);
    for (final from in [
      const Offset(110, 64),
      const Offset(440, 64),
      const Offset(275, 174),
      const Offset(110, 174),
      const Offset(275, -46),
    ]) {
      final tip = beliefArrowTip(target, from);
      expect(target.inflate(5).contains(tip), isFalse);
      expect(
        (tip - target.center).distance,
        lessThan((from - target.center).distance),
      );
    }
  });
  testWidgets(
    'empty religion section can open populated Greek section and fit all nodes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Map<String, dynamic> data;
      await tester.runAsync(() async {
        data = jsonDecode(
          await rootBundle.loadString(beliefAtlasAsset),
        ) as Map<String, dynamic>;
      });
      data['nodes'] = (data['nodes'] as List)
          .where((n) => n['section'] == 'greek')
          .toList();
      final ids = (data['nodes'] as List).map((n) => n['id']).toSet();
      data['edges'] = (data['edges'] as List)
          .where((e) => ids.contains(e['from_id']) && ids.contains(e['to_id']))
          .toList();
      data['questions'] = [];
      await tester.pumpWidget(
        MaterialApp(
          home: BeliefAtlasPage(
            bundle: _Bundle(jsonEncode(data)),
            initialSection: 'religions',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No entries in this section.'), findsOneWidget);
      await tester.tap(find.text('Greek gods'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('belief-graph')), findsOneWidget);
      await tester.tap(find.byKey(const Key('belief-fit')));
      await tester.pump();
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('belief-graph')),
      );
      final scene = tester.getSize(find.byKey(const Key('belief-scene')));
      final viewport = tester.getSize(find.byKey(const Key('belief-graph')));
      final scale = viewer.transformationController!.value.entry(0, 0);
      expect(scene.width * scale, lessThanOrEqualTo(viewport.width + .01));
      expect(scene.height * scale, lessThanOrEqualTo(viewport.height + .01));
      expect(tester.takeException(), isNull);
    },
  );
}
