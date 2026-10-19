import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';

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
  for (final retry in [false, true]) {
    testWidgets(
      'map flags use one image bundle without per-country requests (retry=$retry)',
      (tester) async {
        late ByteData manifest, png;
        await tester.runAsync(() async {
          manifest = await rootBundle.load('AssetManifest.bin');
          png = await rootBundle.load('assets/quizipedia/flag-fr.png');
        });
        var bundleCalls = 0, countryCalls = 0;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (key == 'AssetManifest.bin') return manifest;
          if (key == 'assets/quizipedia/country_flag_images.json') {
            bundleCalls++;
            if (retry && bundleCalls == 1) return null;
            return ByteData.sublistView(
              utf8.encode(
                jsonEncode({
                  'schema_version': 'qm-country-flag-images/v1',
                  'flags': {
                    'FR': base64Encode(
                      png.buffer.asUint8List(
                        png.offsetInBytes,
                        png.lengthInBytes,
                      ),
                    ),
                  },
                }),
              ),
            );
          }
          if (key.contains('/flag-')) {
            countryCalls++;
            return png;
          }
          return null;
        });
        addTearDown(
          () => messenger.setMockMessageHandler('flutter/assets', null),
        );
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
                    polygons: [],
                  ),
                ],
                controller: camera,
                onSelect: (_) {},
                showFlags: true,
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pumpAndSettle();
        if (retry) {
          expect(find.byKey(const Key('map-flags-retry')), findsOneWidget);
          await tester.tap(find.byKey(const Key('map-flags-retry')));
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          });
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('map-flags-retry')), findsNothing);
        }
        expect(countryCalls, 0);
        expect(bundleCalls, retry ? 2 : 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'country ranking replaces layers and selection returns to the map',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(home: CountryAtlasPage(catalog: _catalog)),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('country-map-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compare countries: population and area'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('country-selected-details')), findsOneWidget);
    },
  );
  testWidgets(
    'country map owns vertical drags and most of the phone viewport',
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
      expect(tester.getSize(map).height, greaterThan(400));
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

  testWidgets('a country answer shows feedback on its first tap', (
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
    expect(find.text('Check'), findsNothing);
  });

  testWidgets(
    'flag fills the country outline without leaking into the sea or moving camera',
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
        expect(land[2], greaterThan(land[0] + 60));
        expect(sea, rgb(20, 130));
        expect(sea[0], greaterThan(land[0]));
        image.dispose();
      });
      expect(find.text('France'), findsNothing);
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
