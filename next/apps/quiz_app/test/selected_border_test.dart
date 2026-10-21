import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  testWidgets(
    'selected border remains visible over the adjacent country border',
    (tester) async {
      final controller = TransformationController();
      addTearDown(controller.dispose);
      QuizipediaFeature country(String id, double left, double right) =>
          QuizipediaFeature(
            id: id,
            nameRu: id,
            nameEn: id,
            polygons: [
              [
                [
                  QuizipediaPoint(left, .2),
                  QuizipediaPoint(right, .2),
                  QuizipediaPoint(right, .6),
                  QuizipediaPoint(left, .6),
                  QuizipediaPoint(left, .2),
                ],
              ],
            ],
          );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Center(
            child: RepaintBoundary(
              key: const Key('selected-border-pixels'),
              child: SizedBox(
                width: 400,
                height: 300,
                child: QuizipediaWorldMap(
                  features: [
                    country('AA', .2, .50125),
                    country('BB', .50125, .8),
                  ],
                  controller: controller,
                  onSelect: (_) {},
                  selected: 'AA',
                  neighborIds: const {'BB'},
                  showLabels: false,
                  showSelectionLabel: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('selected-border-pixels')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final blue = bytes.getUint8((130 * image.width + 200) * 4 + 2);
        expect(
          blue,
          greaterThan(240),
          reason: 'The later neighbour stroke must not cover selected blue',
        );
        var amber = 0;
        for (var i = 0; i < bytes.lengthInBytes; i += 4) {
          if (bytes.getUint8(i) > 60 &&
              bytes.getUint8(i + 1) > 70 &&
              bytes.getUint8(i + 2) < 100) {
            amber++;
          }
        }
        expect(
          amber,
          greaterThan(0),
          reason: 'Land neighbours use their own amber outline.',
        );
        image.dispose();
      });
    },
  );
}
