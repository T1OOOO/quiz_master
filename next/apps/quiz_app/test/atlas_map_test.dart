import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

const country = QuizipediaFeature(
  id: 'test',
  nameRu: 'Тест',
  nameEn: 'Test',
  polygons: [
    [
      [
        QuizipediaPoint(.2, .2),
        QuizipediaPoint(.6, .2),
        QuizipediaPoint(.6, .8),
        QuizipediaPoint(.2, .8),
      ],
    ],
  ],
);

void main() {
  testWidgets('map fact labels are visible without changing the camera', (
    tester,
  ) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizipediaWorldMap(
            features: const [country],
            controller: controller,
            selected: 'test',
            overlayLabels: const {'test': 'Capital: Example'},
            onSelect: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Capital: Example'), findsOneWidget);
    expect(controller.value, Matrix4.identity());
  });
  Future<TransformationController> mount(WidgetTester tester) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizipediaWorldMap(
            features: const [country],
            controller: controller,
            selected: 'test',
            onSelect: (_) {},
            showLabels: false,
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('selected border stays thin at high zoom', (tester) async {
    final controller = await mount(tester);
    controller.value = Matrix4.diagonal3Values(8, 8, 1);
    await tester.pump();
    final finder = find.byKey(const Key('quizipedia-map'));
    final paint = tester.widget<CustomPaint>(finder);
    final size = tester.getSize(finder);
    final pixels = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..translate(60, 40)
        ..scale(8)
        ..translate(-size.width * .6, -size.height * .5);
      paint.painter!.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(120, 80);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var dark = 0;
      for (var i = 0; i < data.lengthInBytes; i += 4) {
        if (data.getUint8(i) < 130 &&
            data.getUint8(i + 1) < 130 &&
            data.getUint8(i + 2) < 130) {
          dark++;
        }
      }
      image.dispose();
      picture.dispose();
      return dark;
    });
    expect(
      pixels,
      lessThanOrEqualTo(160),
      reason: 'A selected border must stay under two screen pixels.',
    );
  });

  testWidgets('double tap zooms around tapped point', (tester) async {
    final controller = await mount(tester);
    final at =
        tester.getCenter(find.byKey(const Key('quizipedia-map'))) +
        const Offset(-70, 0);
    final before = controller.toScene(at);
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 70));
    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    expect((controller.toScene(at) - before).distance, lessThan(1));
  });

  testWidgets('zoom reaches small countries and reset returns world', (
    tester,
  ) async {
    final controller = await mount(tester);
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
    }
    expect(controller.value.getMaxScaleOnAxis(), 16);
    await tester.tap(find.byTooltip('Reset view'));
    await tester.pumpAndSettle();
    expect(controller.value, Matrix4.identity());
  });

  testWidgets('pinch scales around fingers without selecting a country', (
    tester,
  ) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);
    var selections = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizipediaWorldMap(
            features: const [country],
            controller: controller,
            onSelect: (_) => selections++,
          ),
        ),
      ),
    );
    final center = tester.getCenter(find.byKey(const Key('quizipedia-map')));
    final a = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final b = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await a.moveBy(const Offset(-20, 0));
    await b.moveBy(const Offset(20, 0));
    await tester.pump();
    await a.moveBy(const Offset(-30, 0));
    await b.moveBy(const Offset(30, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.5));
    expect(selections, 0);
  });
}
