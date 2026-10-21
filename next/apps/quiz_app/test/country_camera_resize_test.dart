import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
  testWidgets(
    'manual map camera keeps its geographic center through expand collapse and resize',
    (tester) async {
      tester.view.physicalSize = const Size(393, 851);
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

      var map = find.byKey(const Key('quizipedia-viewport'));
      await _pinchAndPan(tester, map);
      final controller = tester
          .widget<InteractiveViewer>(map)
          .transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
      final collapsedCenter = _worldPointAtCenter(
        controller,
        tester.getSize(map),
      );

      await tester.tap(find.byKey(const Key('country-expand-map')));
      await tester.pumpAndSettle();
      map = find.byKey(const Key('quizipedia-viewport'));
      expect(
        _worldPointAtCenter(controller, tester.getSize(map)),
        _near(collapsedCenter),
        reason: 'Expanding changes the viewport origin as well as its height.',
      );

      await _pinchAndPan(tester, map);
      final expandedCenter = _worldPointAtCenter(
        controller,
        tester.getSize(map),
      );
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byKey(const Key('country-collapse-map')));
      tester.view.physicalSize = const Size(361, 738);
      await tester.pumpAndSettle();
      map = find.byKey(const Key('quizipedia-viewport'));
      expect(
        _worldPointAtCenter(controller, tester.getSize(map)),
        _near(expandedCenter),
        reason: 'An outgoing expanded camera must not overwrite the compact resize.',
      );
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
      expect(tester.takeException(), isNull);
    },
  );
}

Offset _worldPointAtCenter(TransformationController controller, Size viewport) {
  final sceneWidth = math.min(viewport.width, viewport.height * 2);
  final sceneHeight = sceneWidth / 2;
  final local = controller.toScene(
    Offset(viewport.width / 2, viewport.height / 2),
  );
  return Offset(
    (local.dx - (viewport.width - sceneWidth) / 2) / sceneWidth,
    (local.dy - (viewport.height - sceneHeight) / 2) / sceneHeight,
  );
}

Matcher _near(Offset point) => isA<Offset>()
    .having((value) => value.dx, 'x', closeTo(point.dx, .001))
    .having((value) => value.dy, 'y', closeTo(point.dy, .001));

Future<void> _pinchAndPan(WidgetTester tester, Finder map) async {
  final center = tester.getCenter(map);
  final first = await tester.createGesture(
    pointer: 31,
    kind: PointerDeviceKind.touch,
  );
  final second = await tester.createGesture(
    pointer: 32,
    kind: PointerDeviceKind.touch,
  );
  await first.down(center - const Offset(35, 0));
  await second.down(center + const Offset(35, 0));
  await tester.pump();
  await first.moveTo(center - const Offset(95, 0));
  await second.moveTo(center + const Offset(95, 0));
  await tester.pump(const Duration(milliseconds: 30));
  await first.up();
  await second.up();
  await tester.pumpAndSettle();

  final pan = await tester.startGesture(
    center,
    pointer: 33,
    kind: PointerDeviceKind.touch,
  );
  await pan.moveBy(const Offset(-35, 35));
  await tester.pump();
  await pan.up();
  await tester.pumpAndSettle();
}
