import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/body_atlas.dart';
import 'package:quiz_app/body_scene_geometry.dart';

Future<void> _mount(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double textScale = 1,
  Locale locale = const Locale('en'),
  Set<BodyLayer> layers = const {BodyLayer.organs, BodyLayer.endocrine},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: BodyAtlasPage(initialLayers: layers),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
  expect(find.byType(CircularProgressIndicator), findsNothing);
}

/// Screen position of a scene-space point inside the mounted body scene.
Offset _screen(WidgetTester tester, Offset scenePoint) {
  final rect = tester.getRect(find.byKey(const Key('body-scene')));
  final fit = (rect.width / bodySceneSize.width).clamp(
    0.0,
    rect.height / bodySceneSize.height,
  );
  final origin = Offset(
    (rect.width - bodySceneSize.width * fit) / 2,
    (rect.height - bodySceneSize.height * fit) / 2,
  );
  return rect.topLeft + origin + scenePoint * fit;
}

void main() {
  test('every drawn structure has a card in the shipped atlases', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final organs =
        jsonDecode(
              await rootBundle.loadString('assets/quizipedia/organ_atlas.json'),
            )['organs']
            as List;
    final vessels =
        jsonDecode(
              await rootBundle.loadString(
                'assets/quizipedia/vascular_atlas.json',
              ),
            )['organs']
            as List;
    final ids = {
      for (final row in [...organs, ...vessels]) (row as Map)['id'] as String,
    };
    for (final structure in bodyStructures) {
      expect(ids, contains(structure.id), reason: structure.id);
      expect(structure.bounds.isEmpty, isFalse, reason: structure.id);
      expect(
        (Offset.zero & bodySceneSize).inflate(1).contains(structure.anchor),
        isTrue,
        reason: structure.id,
      );
    }
    expect(
      bodyStructures.map((s) => s.id).toSet().length,
      bodyStructures.length,
    );
  });

  testWidgets('a single tap selects an organ at once and opens its card', (
    tester,
  ) async {
    await _mount(tester);
    final heart = bodyStructureById['heart']!;
    await tester.tapAt(_screen(tester, heart.anchor));
    // No double-tap delay: the card is there on the very next frame.
    await tester.pump();
    expect(find.byKey(const Key('body-sheet')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('body-panel-title'))).data,
      'Heart',
    );
    await tester.pumpAndSettle();
    // Closing clears the selection.
    await tester.tap(find.byKey(const Key('body-panel-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-sheet')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small glands win over the organ behind them', (tester) async {
    await _mount(tester);
    await tester.tapAt(_screen(tester, bodyStructureById['adrenals']!.anchor));
    await tester.pumpAndSettle();
    expect(find.text('Adrenal glands'), findsWidgets);
    await tester.tapAt(_screen(tester, bodyStructureById['pituitary']!.anchor));
    await tester.pumpAndSettle();
    expect(find.text('Pituitary gland'), findsWidgets);
  });

  testWidgets('layers toggle and a vessel is selectable over the heart', (
    tester,
  ) async {
    await _mount(tester, layers: const {BodyLayer.organs});
    final aorta = bodyStructureById['aorta']!;
    // Hidden layer: the tap lands on the heart underneath.
    await tester.tapAt(_screen(tester, const Offset(232, 262)));
    await tester.pumpAndSettle();
    expect(find.text('Heart'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('body-layer-vascular')));
    await tester.tap(find.byKey(const Key('body-layer-vascular')));
    await tester.pumpAndSettle();
    await tester.tapAt(_screen(tester, aorta.anchor));
    await tester.pumpAndSettle();
    expect(find.text('Aorta'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('body-layer-organs')));
    await tester.tap(find.byKey(const Key('body-layer-organs')));
    await tester.pumpAndSettle();
    await tester.tapAt(_screen(tester, bodyStructureById['liver']!.anchor));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-sheet')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double tap zooms in and arrow keys step through structures', (
    tester,
  ) async {
    await _mount(tester, layers: const {BodyLayer.skeleton});
    final scene = find.byKey(const Key('body-scene'));
    final viewer = tester.widget<InteractiveViewer>(scene);
    final controller = viewer.transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), 1);
    final at = _screen(tester, const Offset(200, 300));
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), closeTo(2, .01));
    // The first tap selected a bone group; Escape clears it, then arrows
    // walk the visible structures from the top of the body.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-sheet')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Skull'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Skull'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-sheet')), findsNothing);
  });

  testWidgets('search focuses the camera on the result', (tester) async {
    await _mount(tester, locale: const Locale('ru'));
    await tester.tap(find.byKey(const Key('body-search-action')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body-search')), 'щитов');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('body-result-thyroid')));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(find.byKey(const Key('body-scene')))
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.5));
    expect(find.text('Щитовидная железа'), findsWidgets);
    expect(find.byKey(const Key('body-practice')), findsOneWidget);
    // Catalogue-only entries still open a card.
    await tester.tap(find.byKey(const Key('body-search-action')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body-search')), 'кожа');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('body-result-skin')));
    await tester.pumpAndSettle();
    expect(find.text('Кожа'), findsWidgets);
    final show = tester.widget<OutlinedButton>(
      find.byKey(const Key('body-show-on-scene')),
    );
    expect(show.onPressed, isNull);
  });

  testWidgets('structures are exposed to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _mount(tester);
    expect(find.semantics.byLabel('Heart'), findsOne);
    expect(find.semantics.byLabel('Liver'), findsOne);
    handle.dispose();
  });

  testWidgets('wide screens put the card beside the scene', (tester) async {
    await _mount(tester, size: const Size(1100, 760));
    expect(find.byKey(const Key('body-search')), findsOneWidget);
    await tester.tapAt(_screen(tester, bodyStructureById['liver']!.anchor));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('body-sheet')), findsNothing);
    final panel = tester.getRect(find.byKey(const Key('body-panel')));
    final scene = tester.getRect(find.byKey(const Key('body-scene')));
    expect(panel.left, greaterThanOrEqualTo(scene.right));
    expect(find.text('Liver'), findsWidgets);
  });

  testWidgets('a resized viewport keeps the focused structure in view', (
    tester,
  ) async {
    await _mount(tester, size: const Size(1100, 760));
    tester.state<BodySceneState>(find.byType(BodyScene)).focusOn('heart');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(375, 812);
    await tester.pumpAndSettle();
    final scene = tester.getRect(find.byKey(const Key('body-scene')));
    final controller = tester
        .widget<InteractiveViewer>(find.byKey(const Key('body-scene')))
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.5));
    // The heart's screen position is derived from the new fit and camera.
    final heart = MatrixUtils.transformPoint(
      controller.value,
      _screen(tester, bodyStructureById['heart']!.anchor) - scene.topLeft,
    );
    expect(scene.contains(scene.topLeft + heart), isTrue);
  });

  testWidgets('fits a narrow phone with enlarged Russian text', (tester) async {
    await _mount(
      tester,
      size: const Size(320, 680),
      textScale: 1.5,
      locale: const Locale('ru'),
    );
    expect(tester.takeException(), isNull);
    await tester.tapAt(_screen(tester, bodyStructureById['lungs']!.anchor));
    await tester.pumpAndSettle();
    expect(find.text('Лёгкие'), findsWidgets);
    await tester.tap(find.byKey(const Key('body-zoom-in')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
