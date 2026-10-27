import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/waterways_models.dart';

const _catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  constellations: [],
  credits: [],
);

class _NameLayerBundle extends CachingAssetBundle {
  final requests = <String>[];

  @override
  Future<ByteData> load(String key) {
    requests.add(key);
    return rootBundle.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    requests.add(key);
    return rootBundle.loadString(key, cache: cache);
  }
}

QuizipediaFeature _country(String id, double x, double y) => QuizipediaFeature(
  id: id,
  nameEn: 'Country $id',
  nameRu: 'Страна $id',
  polygons: [
    [
      [
        QuizipediaPoint(x, y),
        QuizipediaPoint(x + .01, y),
        QuizipediaPoint(x + .01, y + .01),
        QuizipediaPoint(x, y + .01),
        QuizipediaPoint(x, y),
      ],
    ],
  ],
);

void main() {
  testWidgets(
    'explicit all-country-name mode keeps tiny colliding names with map layers',
    (tester) async {
      final controller = TransformationController(
        Matrix4.identity()..translateByDouble(6, 3, 0, 1),
      );
      addTearDown(controller.dispose);
      final before = controller.value.clone();
      final countries = [
        _country('AA', .48, .48),
        _country('BB', .50, .48),
        _country('CC', .52, .48),
      ];
      const water = WaterShape(
        id: 'sea',
        nameRu: 'Море',
        nameEn: 'Sea',
        kind: 'marine',
        anchor: WaterPoint(.5, .52),
        polygons: [],
        lines: [
          [WaterPoint(.45, .52), WaterPoint(.55, .52)],
        ],
      );
      Widget map({required bool alwaysShowCountryNames}) => MaterialApp(
        home: SizedBox(
          width: 390,
          height: 260,
          child: QuizipediaWorldMap(
            features: countries,
            controller: controller,
            onSelect: (_) {},
            showFlags: true,
            alwaysShowCountryNames: alwaysShowCountryNames,
            waters: const [water],
            capitalPoints: const {
              'AA': Offset(.485, .485),
              'BB': Offset(.505, .485),
              'CC': Offset(.525, .485),
            },
            capitalLabels: const {'AA': 'Альфа', 'BB': 'Бета', 'CC': 'Гамма'},
            overlayLabels: const {'AA': 'факт A'},
          ),
        ),
      );
      await tester.pumpWidget(map(alwaysShowCountryNames: false));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-country-name-aa')), findsNothing);

      await tester.pumpWidget(map(alwaysShowCountryNames: true));
      await tester.pumpAndSettle();

      for (final id in ['aa', 'bb', 'cc']) {
        expect(find.byKey(Key('map-country-name-$id')), findsOneWidget);
      }
      expect(controller.value.storage, orderedEquals(before.storage));
    },
  );

  testWidgets(
    'mobile names setting preserves manual camera without loading map layers',
    (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bundle = _NameLayerBundle();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: CountryAtlasPage(catalog: _catalog, bundle: bundle),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('quizipedia-viewport')),
      );
      final camera = Matrix4.identity()..scaleByDouble(1.7, 1.7, 1, 1);
      viewer.transformationController!.value = camera;
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      final names = find.byKey(const Key('country-sheet-always-country-names'));
      await tester.ensureVisible(names);
      await tester.tap(names);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(names).selected, isTrue);
      expect(
        bundle.requests.where(
          (key) =>
              key.endsWith('/waterways.json') ||
              key.endsWith('/capital_points.json'),
        ),
        isEmpty,
      );
      await tester.ensureVisible(find.byKey(const Key('country-apply-layer')));
      await tester.tap(find.byKey(const Key('country-apply-layer')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
            .alwaysShowCountryNames,
        isTrue,
      );
      expect(viewer.transformationController!.value, camera);
    },
  );
}
