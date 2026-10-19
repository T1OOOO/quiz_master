import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  for (final training in [false, true]) {
    testWidgets(
      'organ atlas opens shipped data from ${training ? 'training' : 'explore'} menu',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          final bundle = _Bundle({
            for (final key in [
              'assets/quizipedia/catalog.json',
              'assets/quizipedia/organ_atlas.json',
            ])
              key: await rootBundle.loadString(key),
          });
          await tester.pumpWidget(
            MaterialApp(home: QuizipediaPage(bundle: bundle)),
          );
          await tester.pump();
          final catalog = tester.widget<FutureBuilder<QuizipediaCatalog>>(
            find.byWidgetPredicate(
              (w) => w is FutureBuilder<QuizipediaCatalog>,
            ),
          );
          await catalog.future!;
        });
        await tester.pumpAndSettle();
        if (training) {
          await tester.tap(find.text('Training'));
          await tester.pump();
        }
        await tester.tap(find.text('Human organs and glands'));
        await tester.pumpAndSettle();
        expect(find.text('Retry'), findsNothing);
        if (training) {
          expect(find.text('Check'), findsOneWidget);
        } else {
          expect(find.byKey(const Key('organ-search')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Quizipedia exposes full organ atlas alongside endocrine exercise',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: QuizipediaPage()));
        await tester.pump();
        final catalog = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
        );
        await catalog.future!;
      });
      await tester.pumpAndSettle();
      expect(find.text('Human organs and glands'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Endocrine system'), 200);
      expect(find.text('Endocrine system'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.assets);
  final Map<String, String> assets;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(assets[key] ?? (throw FlutterError('Missing $key')));
  @override
  Future<ByteData> load(String key) =>
      throw UnsupportedError('Text assets only');
}
