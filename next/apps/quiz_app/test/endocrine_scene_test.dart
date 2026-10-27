import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/organ_atlas.dart';

class _TrackingBundle extends CachingAssetBundle {
  _TrackingBundle(this.atlas);
  final String atlas;
  final requests = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requests.add(key);
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    requests.add(key);
    return atlas;
  }
}

void main() {
  testWidgets(
    'endocrine scene is lazy, source-labelled and opens a gland card',
    (tester) async {
      tester.view.physicalSize = const Size(360, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late String atlas;
      await tester.runAsync(() async {
        atlas = await rootBundle.loadString(
          'assets/quizipedia/organ_atlas.json',
        );
      });
      final bundle = _TrackingBundle(atlas);
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: OrganAtlasPage(
                bundle: bundle,
                initialScope: OrganAtlasScope.organs,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        bundle.requests,
        isNot(contains('assets/quizipedia/endocrine-ru-display.png')),
      );

      await tester.ensureVisible(find.byKey(const Key('organ-view-endocrine')));
      await tester.tap(find.byKey(const Key('organ-view-endocrine')));
      await tester.pump(const Duration(seconds: 1));
      expect(
        bundle.requests,
        contains('assets/quizipedia/endocrine-ru-display.png'),
      );
      expect(find.byKey(const Key('anatomy-scene')), findsOneWidget);
      for (final id in [
        'pituitary',
        'pineal',
        'thyroid',
        'thymus',
        'adrenals',
        'pancreas',
        'ovaries',
        'testes',
      ]) {
        expect(find.byKey(Key('anatomy-marker-$id')), findsOneWidget);
      }
      final endocrinePins =
          [
                'pituitary',
                'pineal',
                'thyroid',
                'thymus',
                'adrenals',
                'pancreas',
                'ovaries',
                'testes',
              ]
              .map(
                (id) => tester.getRect(find.byKey(Key('anatomy-marker-$id'))),
              )
              .toList();
      for (var first = 0; first < endocrinePins.length; first++) {
        for (var second = first + 1; second < endocrinePins.length; second++) {
          expect(endocrinePins[first].overlaps(endocrinePins[second]), isFalse);
        }
      }
      final endocrineScene = tester.getRect(
        find.byKey(const Key('anatomy-scene')),
      );
      expect(
        tester
            .getRect(find.byKey(const Key('anatomy-marker-ovaries')))
            .center
            .dx,
        greaterThan(endocrineScene.center.dx),
      );
      expect(
        tester
            .getRect(find.byKey(const Key('anatomy-marker-testes')))
            .center
            .dx,
        lessThan(endocrineScene.center.dx),
      );
      expect(
        find.byKey(const Key('anatomy-marker-hypothalamus')),
        findsNothing,
      );
      expect(find.byKey(const Key('anatomy-scene-credit')), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('anatomy-scene-credit'))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('anatomy-scene-credit')));
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.textContaining('Правительство США; исходная иллюстрация NCI SEER'),
        findsOneWidget,
      );
      expect(find.text('Image source'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pump(const Duration(seconds: 1));

      final pituitaryAction = find.byKey(
        const Key('anatomy-marker-action-pituitary'),
      );
      await tester.ensureVisible(pituitaryAction);
      expect(tester.getSize(pituitaryAction).height, greaterThanOrEqualTo(48));
      await tester.tap(pituitaryAction);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('organ-detail')), findsOneWidget);
      expect(find.text('Pituitary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
