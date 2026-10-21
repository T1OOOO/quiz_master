import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/map_interaction.dart';

const _catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  constellations: [],
  credits: [],
);

void main() {
  testWidgets('country labels fit a whole readable name on a narrow map', (
    tester,
  ) async {
    final camera = TransformationController();
    addTearDown(camera.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 393,
              height: 500,
              child: QuizipediaWorldMap(
                features: const [
                  QuizipediaFeature(
                    id: 'NL',
                    nameEn: 'Netherlands',
                    nameRu: 'Нидерланды',
                    polygons: [
                      [
                        [
                          QuizipediaPoint(.45, .2),
                          QuizipediaPoint(.55, .2),
                          QuizipediaPoint(.55, .5),
                          QuizipediaPoint(.45, .5),
                          QuizipediaPoint(.45, .2),
                        ],
                      ],
                    ],
                  ),
                ],
                controller: camera,
                onSelect: (_) {},
                showLabels: false,
                overlayLabels: const {'NL': 'Нидерланды'},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(const Key('map-overlay-label-NL')),
    );
    expect(
      paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 10),
      ),
      hasLength(1),
    );
  });
  testWidgets(
    'country name labels remain visible across irregular coastlines',
    (tester) async {
      late QuizipediaCatalog catalog;
      await tester.runAsync(() async {
        catalog = QuizipediaCatalog.fromJson(
          jsonDecode(
            await rootBundle.loadString('assets/quizipedia/catalog.json'),
          ) as Map<String, dynamic>,
        );
      });
      final camera = TransformationController();
      addTearDown(camera.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 393,
                height: 500,
                child: QuizipediaWorldMap(
                  features: catalog.countries,
                  controller: camera,
                  onSelect: (_) {},
                  showLabels: false,
                  overlayLabels: const {'AU': 'Australia'},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-overlay-label-AU')), findsOneWidget);
    },
  );
  testWidgets('a repeated explicit focus request recentres the same country', (
    tester,
  ) async {
    final camera = TransformationController();
    final request = ValueNotifier(0);
    addTearDown(camera.dispose);
    addTearDown(request.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: request,
            builder: (context, value, _) => QuizipediaWorldMap(
              features: const [
                QuizipediaFeature(
                  id: 'FR',
                  nameEn: 'France',
                  nameRu: 'Франция',
                  polygons: [
                    [
                      [
                        QuizipediaPoint(.3, .2),
                        QuizipediaPoint(.4, .2),
                        QuizipediaPoint(.4, .4),
                        QuizipediaPoint(.3, .4),
                        QuizipediaPoint(.3, .2),
                      ],
                    ],
                  ],
                ),
              ],
              controller: camera,
              onSelect: (_) {},
              focusTarget: 'FR',
              focusRequest: value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final focused = camera.value.clone();
    camera.value = Matrix4.identity()..translateByDouble(-20, -30, 0, 1);
    request.value++;
    await tester.pumpAndSettle();
    for (final index in [0, 5, 12, 13]) {
      expect(camera.value.storage[index], closeTo(focused.storage[index], .01));
    }
  });
  testWidgets(
    'vertical touch drag moves an embedded world map rather than its page',
    (tester) async {
      final camera = TransformationController();
      addTearDown(camera.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 320,
                    height: 300,
                    child: QuizipediaWorldMap(
                      features: const [],
                      controller: camera,
                      onSelect: (_) {},
                    ),
                  ),
                  const SizedBox(height: 900),
                ],
              ),
            ),
          ),
        ),
      );
      final page = tester.state<ScrollableState>(find.byType(Scrollable));
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(InteractiveViewer)),
      );
      await tester.pump();
      await finger.moveBy(const Offset(0, -35));
      await tester.pump(const Duration(milliseconds: 16));
      await finger.moveBy(const Offset(0, -45));
      await finger.up();
      await tester.pumpAndSettle();
      expect(page.position.pixels, 0);
      expect(camera.value.storage[13], lessThan(-10));
      await tester.dragFrom(const Offset(5, 180), const Offset(0, -90));
      await tester.pumpAndSettle();
      expect(page.position.pixels, greaterThan(0));
    },
  );
  testWidgets(
    'world map preserves coordinate taps without a centre-tap semantic action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final camera = TransformationController();
        addTearDown(camera.dispose);
        String? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  height: 300,
                  child: QuizipediaWorldMap(
                    features: const [
                      QuizipediaFeature(
                        id: 'FR',
                        nameEn: 'France',
                        nameRu: 'Франция',
                        polygons: [
                          [
                            [
                              QuizipediaPoint(.1, .1),
                              QuizipediaPoint(.4, .1),
                              QuizipediaPoint(.4, .8),
                              QuizipediaPoint(.1, .8),
                              QuizipediaPoint(.1, .1),
                            ],
                          ],
                        ],
                      ),
                    ],
                    controller: camera,
                    onSelect: (id) => selected = id,
                  ),
                ),
              ),
            ),
          ),
        );
        final map = find.bySemanticsLabel('Interactive world map');
        expect(
          tester
              .getSemantics(map)
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
        final rect = tester.getRect(find.byKey(const Key('quizipedia-map')));
        await tester.tapAt(
          rect.topLeft + Offset(rect.width * .25, rect.height * .5),
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(selected, 'FR');
        expect(camera.value.getMaxScaleOnAxis(), 1);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('map flags request only an individual visible marker asset', (
    tester,
  ) async {
    late ByteData manifest, png;
    await tester.runAsync(() async {
      manifest = await rootBundle.load('AssetManifest.bin');
      png = await rootBundle.load('assets/quizipedia/flag-fr.png');
    });
    final requests = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      requests.add(key);
      if (key == 'AssetManifest.bin') return manifest;
      if (key.startsWith('assets/quizipedia/flag-')) return png;
      return null;
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final camera = TransformationController();
    addTearDown(camera.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 300,
          child: QuizipediaWorldMap(
            features: const [
              QuizipediaFeature(
                id: 'FR',
                nameEn: 'France',
                nameRu: 'Франция',
                polygons: [
                  [
                    [
                      QuizipediaPoint(.1, .2),
                      QuizipediaPoint(.4, .2),
                      QuizipediaPoint(.4, .5),
                      QuizipediaPoint(.1, .5),
                      QuizipediaPoint(.1, .2),
                    ],
                  ],
                ],
              ),
            ],
            controller: camera,
            onSelect: (_) {},
            showFlags: true,
            selected: 'FR',
            overlayLabels: const {'FR': 'France'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      requests,
      isNot(contains('assets/quizipedia/country_flag_images.json')),
    );
    expect(
      requests.where((key) => key.startsWith('assets/quizipedia/flag-')),
      equals(['assets/quizipedia/flag-fr.png']),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'country ranking selection returns to the map without moving its camera',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      final initialMap = tester.widget<QuizipediaWorldMap>(
        find.byType(QuizipediaWorldMap),
      );
      initialMap.controller.value = Matrix4.identity()
        ..translateByDouble(-34, -18, 0, 1)
        ..scaleByDouble(1.5, 1.5, 1.5, 1);
      final cameraBeforeSelection = initialMap.controller.value.clone();
      expect(
        initialMap.overlayLabels,
        isNotEmpty,
        reason: 'Unselected countries need visible names',
      );
      await tester.ensureVisible(find.byKey(const Key('country-map-settings')));
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Compare countries: population and area'),
      );
      await tester.tap(find.text('Compare countries: population and area'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('country-selected-details')), findsOneWidget);
      final selectedMap = tester.widget<QuizipediaWorldMap>(
        find.byType(QuizipediaWorldMap),
      );
      expect(
        selectedMap.focusTarget,
        isNull,
        reason: 'Choosing a country is not an explicit fit request.',
      );
      expect(selectedMap.controller.value, cameraBeforeSelection);
      expect(find.byKey(const Key('country-flag-preview')), findsOneWidget);
    },
  );
  testWidgets(
    'country map uses the world aspect ratio and owns vertical drags',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      final map = find.byKey(const Key('quizipedia-viewport'));
      expect(tester.getSize(map).height, closeTo(180.5, 2));
      final before = tester.getTopLeft(map);
      final viewer = tester.widget<InteractiveViewer>(map);
      final camera = viewer.transformationController!.value.clone();
      await tester.drag(map, const Offset(0, -90));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(map), before);
      expect(viewer.transformationController!.value, isNot(camera));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expand map keeps the manual camera on a phone', (tester) async {
    tester.view.physicalSize = const Size(361, 738);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    final before =
        tester
            .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
            .controller
            .value
          ..translateByDouble(-24, -12, 0, 1);
    await tester.tap(find.byKey(const Key('country-expand-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('country-collapse-map')), findsOneWidget);
    expect(
      tester
          .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
          .controller
          .value,
      before,
    );
    await tester.tap(find.byKey(const Key('country-collapse-map')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap))
          .controller
          .value,
      before,
    );
  });

  testWidgets('country picker opens a searchable country sheet on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('country-list-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('country-list-search')), findsOneWidget);
    expect(find.text('Choose a country'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map layers can keep names, capitals and flags together', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('country-direct-layers')), findsOneWidget);
    await tester.tap(find.byKey(const Key('country-direct-layer-capital')));
    await tester.tap(find.byKey(const Key('country-direct-layer-flag')));
    QuizipediaWorldMap currentMap() =>
        tester.widget<QuizipediaWorldMap>(find.byType(QuizipediaWorldMap));
    for (
      var frame = 0;
      frame < 40 && currentMap().capitalPoints['FR'] == null;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();

    final map = currentMap();
    expect(map.showFlags, isTrue);
    expect(map.overlayLabels['FR'], contains('France'));
    expect(map.overlayLabels['FR'], contains('Paris'));
    expect(map.capitalPoints['FR'], isNotNull);
    expect(map.capitalLabels['FR'], 'Paris');
  });

  testWidgets('a country answer shows feedback on its first tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('country-start-training')));
    await tester.tap(find.byKey(const Key('country-start-training')));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quizipedia-feedback')), findsOneWidget);
    expect(find.textContaining('Your answer:'), findsOneWidget);
    expect(find.byKey(const Key('country-answer-explanation')), findsOneWidget);
    expect(find.textContaining('Review the country card'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
    expect(find.textContaining('Your answer:').hitTestable(), findsOneWidget);
    expect(find.text('Next').hitTestable(), findsOneWidget);
    expect(find.text('Check'), findsNothing);
  });

  testWidgets(
    'flag is a raised country marker without repainting the country outline',
    (tester) async {
      final controller = TransformationController(
        Matrix4.identity()..translateByDouble(-18, -12, 0, 1),
      );
      addTearDown(controller.dispose);
      const france = QuizipediaFeature(
        id: 'FR',
        nameRu: 'Франция',
        nameEn: 'France',
        polygons: [
          [
            [
              QuizipediaPoint(.2, .2),
              QuizipediaPoint(.8, .2),
              QuizipediaPoint(.8, .8),
              QuizipediaPoint(.2, .8),
              QuizipediaPoint(.2, .2),
            ],
          ],
        ],
      );
      final camera = controller.value.clone();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const Key('flag-boundary'),
              child: SizedBox(
                width: 320,
                height: 300,
                child: QuizipediaWorldMap(
                  features: const [
                    france,
                    QuizipediaFeature(
                      id: 'NE-ATA',
                      nameEn: 'Antarctica',
                      nameRu: 'Антарктида',
                      polygons: [],
                    ),
                  ],
                  controller: controller,
                  onSelect: (_) {},
                  overlayLabels: const {'FR': 'France'},
                  showFlags: true,
                ),
              ),
            ),
          ),
        ),
      );
      // Let both platform asset IO and the large-UTF8 worker finish between frames.
      for (var i = 0; i < 40; i++) {
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('flag-boundary')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        List<int> rgb(int x, int y) => [
          for (var i = 0; i < 3; i++)
            pixels.getUint8((y * image.width + x) * 4 + i),
        ];
        final land = rgb(60, 120), sea = rgb(30, 120);
        expect(
          land[1],
          greaterThan(land[2]),
          reason: 'Land keeps its map fill.',
        );
        expect(sea, rgb(20, 130));
        image.dispose();
      });
      expect(find.byKey(const Key('map-country-flag-fr')), findsOneWidget);
      expect(controller.value, camera);
    },
  );
  testWidgets('a selected small country still shows its chosen fact layer', (
    tester,
  ) async {
    final camera = TransformationController();
    addTearDown(camera.dispose);
    const country = QuizipediaFeature(
      id: 'FR',
      nameEn: 'France',
      nameRu: 'Франция',
      polygons: [
        [
          [
            QuizipediaPoint(.48, .48),
            QuizipediaPoint(.52, .48),
            QuizipediaPoint(.52, .52),
            QuizipediaPoint(.48, .52),
            QuizipediaPoint(.48, .48),
          ],
        ],
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 361,
            height: 440,
            child: QuizipediaWorldMap(
              features: const [country],
              controller: camera,
              selected: 'FR',
              showSelectionLabel: false,
              overlayLabels: const {'FR': 'Париж'},
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Париж'), findsOneWidget);
    expect(camera.value, Matrix4.identity());
  });
  testWidgets('map omits labels over polygon holes', (tester) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);
    const feature = QuizipediaFeature(
      id: 'XX',
      nameRu: 'Проверка',
      nameEn: 'Test',
      polygons: [
        [
          [
            QuizipediaPoint(.1, .1),
            QuizipediaPoint(.9, .1),
            QuizipediaPoint(.9, .9),
            QuizipediaPoint(.1, .9),
            QuizipediaPoint(.1, .1),
          ],
          [
            QuizipediaPoint(.3, .3),
            QuizipediaPoint(.7, .3),
            QuizipediaPoint(.7, .7),
            QuizipediaPoint(.3, .7),
            QuizipediaPoint(.3, .3),
          ],
        ],
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: QuizipediaWorldMap(
          features: const [feature],
          controller: controller,
          onSelect: (_) {},
          overlayLabels: const {'XX': 'Outside-land-label'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Outside-land-label'), findsNothing);
  });
}
