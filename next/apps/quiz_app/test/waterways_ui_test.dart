import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/waterways_models.dart';
import 'package:quiz_app/waterways_page.dart';

const catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  constellations: [],
  credits: [],
);

class WaterBundle extends CachingAssetBundle {
  int loads = 0;
  bool fail = true;
  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('/waterways.json')) {
      loads++;
      if (fail) return Future.error(FlutterError('missing geometry'));
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('checked water choices stay readable in dark mode', (
    tester,
  ) async {
    late WaterAtlas atlas;
    await tester.runAsync(() async {
      atlas = await WaterAtlas.load();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: WaterPracticePage(catalog: catalog, atlas: atlas),
      ),
    );
    await tester.pumpAndSettle();
    final target = tester
        .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
        .selectedWater;
    final wrong = find
        .byType(OutlinedButton)
        .evaluate()
        .map((e) => e.widget as OutlinedButton)
        .firstWhere((b) => b.key != ValueKey('water-answer-$target'));
    await tester.ensureVisible(find.byKey(wrong.key!));
    await tester.tap(find.byKey(wrong.key!));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('water-check')));
    await tester.tap(find.byKey(const Key('water-check')));
    await tester.pumpAndSettle();
    for (final symbol in ['✗ ', '✓ ']) {
      final label = find.textContaining(symbol);
      final element = tester.element(label);
      final ink = DefaultTextStyle.of(element).style.color!;
      final material = tester.widget<Material>(
        find.ancestor(of: label, matching: find.byType(Material)).first,
      );
      final background = Color.alphaBlend(
        material.color ?? Colors.transparent,
        Theme.of(element).scaffoldBackgroundColor,
      );
      final a = Color.alphaBlend(ink, background).computeLuminance(),
          b = background.computeLuminance();
      expect(
        a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'explicit water focus handles split and polar oceans without automatic zoom',
    (tester) async {
      late WaterAtlas atlas;
      await tester.runAsync(() async {
        atlas = await WaterAtlas.load();
      });
      final controller = TransformationController();
      addTearDown(controller.dispose);
      for (final id in ['Q98', 'Q164466', 'Q788', 'Q7354']) {
        controller.value = Matrix4.identity();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuizipediaWorldMap(
                features: const [],
                waters: atlas.features,
                selectedWater: id,
                controller: controller,
                onSelect: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.value, Matrix4.identity());
        await tester.tap(find.byTooltip('Show selected water body'));
        await tester.pumpAndSettle();
        expect(
          controller.value.getMaxScaleOnAxis(),
          greaterThan(1.5),
          reason: id,
        );
      }
    },
  );
  testWidgets(
    'six water answers require checking, retain wrong choice and advance only manually',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late WaterAtlas atlas;
      await tester.runAsync(() async {
        atlas = await WaterAtlas.load();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: WaterPracticePage(catalog: catalog, atlas: atlas),
        ),
      );
      await tester.pumpAndSettle();
      final map = tester.widget<QuizipediaWorldMap>(
        find.byType(QuizipediaWorldMap),
      );
      final correct = map.selectedWater;
      expect(map.showWaterLabels, isFalse);
      final choices = find.byType(OutlinedButton);
      expect(choices, findsNWidgets(6));
      final wrong = choices
          .evaluate()
          .map((e) => e.widget as OutlinedButton)
          .firstWhere((b) => b.key != ValueKey('water-answer-$correct'));
      final wrongFinder = find.byKey(wrong.key!);
      await tester.ensureVisible(wrongFinder);
      await tester.tap(wrongFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('water-feedback')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('water-check')));
      await tester.tap(find.byKey(const Key('water-check')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Correct answer:'), findsOneWidget);
      expect(find.textContaining('✗ '), findsOneWidget);
      expect(find.textContaining('✓ '), findsOneWidget);
      final wrongLabel = find.textContaining('✗ ');
      final element = tester.element(wrongLabel);
      final ink = DefaultTextStyle.of(element).style.color!;
      final material = tester.widget<Material>(
        find.ancestor(of: wrongLabel, matching: find.byType(Material)).first,
      );
      final background = Color.alphaBlend(
        material.color ?? Colors.transparent,
        Theme.of(element).scaffoldBackgroundColor,
      );
      final visibleInk = Color.alphaBlend(ink, background);
      final a = visibleInk.computeLuminance(),
          b = background.computeLuminance();
      final contrast = (a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05));
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: 'Checked answer labels remain readable even when disabled',
      );
      await tester.pump(const Duration(seconds: 3));
      expect(
        tester
            .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
            .selectedWater,
        correct,
      );
      expect(find.byType(ActionChip), findsNWidgets(6));
      await tester.ensureVisible(find.byKey(const Key('water-next')));
      await tester.tap(find.byKey(const Key('water-next')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
            .selectedWater,
        isNot(correct),
      );
      expect(find.byKey(const Key('water-feedback')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'water layer loads on demand, retries separately and preserves manual camera',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bundle = WaterBundle();
      await tester.runAsync(() async {
        final realCatalog = QuizipediaCatalog.fromJson(
          jsonDecode(
            await rootBundle.loadString('assets/quizipedia/catalog.json'),
          ) as Map<String, dynamic>,
        );
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: CountryAtlasPage(catalog: realCatalog, bundle: bundle),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      expect(bundle.loads, 0);
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('quizipedia-viewport')),
      );
      final camera = Matrix4.identity()..scaleByDouble(2, 2, 1, 1);
      viewer.transformationController!.value = camera;
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('atlas-map-layer')));
      await tester.tap(find.byKey(const Key('atlas-map-layer')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Water bodies').last);
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byKey(const Key('atlas-map-layer'))))
          .pop();
      await tester.pumpAndSettle();
      expect(bundle.loads, 1);
      expect(find.byKey(const Key('water-geometry-retry')), findsOneWidget);
      expect(find.byKey(const Key('quizipedia-viewport')), findsOneWidget);
      bundle.fail = false;
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('water-geometry-retry')));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(bundle.loads, 2);
      expect(find.byKey(const Key('water-geometry-retry')), findsNothing);
      await tester.tap(find.byKey(const Key('water-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('water-search')), 'Байкал');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byKey(const Key('water-search'))).dy,
        lessThanOrEqualTo(288),
      );
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Baikal').last);
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value, camera);
      final map = tester.widget<QuizipediaWorldMap>(
        find.byType(QuizipediaWorldMap),
      );
      expect(map.selectedWater, 'Q5513');
      expect(map.waters, hasLength(63));
      expect(tester.takeException(), isNull);
    },
  );
}
