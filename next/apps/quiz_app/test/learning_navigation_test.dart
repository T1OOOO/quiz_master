import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  for (final section in ['Greek gods', 'Religions and traditions']) {
    testWidgets('$section menu loads the shipped relationship atlas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final bundle = _NavigationBundle({
          for (final key in [
            'assets/quizipedia/catalog.json',
            'assets/quizipedia/belief_atlas.json',
          ])
            key: await rootBundle.loadString(key),
        });
        await tester.pumpWidget(
          MaterialApp(home: QuizipediaPage(bundle: bundle)),
        );
        await tester.pump();
        final catalog = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
        );
        await catalog.future!;
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(section), 200);
      await tester.ensureVisible(find.text(section));
      await tester.pumpAndSettle();
      await tester.tap(find.text(section));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('belief-search')), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('food menu loads the shipped classic recipes', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final bundle = _NavigationBundle({
        for (final key in [
          'assets/quizipedia/catalog.json',
          'assets/quizipedia/food_atlas.json',
        ])
          key: await rootBundle.loadString(key),
      });
      await tester.pumpWidget(
        MaterialApp(home: QuizipediaPage(bundle: bundle)),
      );
      await tester.pump();
      final catalog = tester.widget<FutureBuilder<QuizipediaCatalog>>(
        find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
      );
      await catalog.future!;
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Food and regional cuisines'),
      200,
    );
    await tester.tap(find.text('Food and regional cuisines'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('food-search')), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('brands menu opens the shipped brand registry', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final bundle = _NavigationBundle({
        for (final key in [
          'assets/quizipedia/catalog.json',
          'assets/quizipedia/brands.json',
        ])
          key: await rootBundle.loadString(key),
      });
      await tester.pumpWidget(
        MaterialApp(home: QuizipediaPage(bundle: bundle)),
      );
      await tester.pump();
      final catalog = tester.widget<FutureBuilder<QuizipediaCatalog>>(
        find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
      );
      await catalog.future!;
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Brands and companies'), 200);
    await tester.tap(find.text('Brands and companies'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-search')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('brand-amazon')),
      200,
      scrollable: find
          .ancestor(
            of: find.byKey(const Key('brand-search')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('Amazon.com, Inc.'), findsWidgets);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Quizipedia exposes history culture and people alongside atlases',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: QuizipediaPage()));
        await tester.pump();
        final builder = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
        );
        await builder.future!;
      });
      await tester.pumpAndSettle();
      for (final name in [
        'World history',
        'Films, books and opera',
        'People and their works',
        'Brands and companies',
        'Food and regional cuisines',
        'Greek gods',
        'Religions and traditions',
      ]) {
        await tester.scrollUntilVisible(find.text(name), 200);
        expect(find.text(name), findsOneWidget);
      }
    },
  );
}

class _NavigationBundle extends CachingAssetBundle {
  _NavigationBundle(this.assets);
  final Map<String, String> assets;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(assets[key] ?? (throw FlutterError('Missing $key')));
  @override
  Future<ByteData> load(String key) =>
      throw UnsupportedError('Text assets only');
}
