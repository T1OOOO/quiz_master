import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/constellation_atlas.dart';
import 'package:quiz_app/quizipedia.dart';

const _catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  credits: [],
  constellations: [
    {
      'id': 'ori',
      'name_en': 'Orion',
      'name_ru': 'Орион',
      'explanation_en': 'A bright winter constellation.',
      'explanation_ru': 'Яркое зимнее созвездие.',
      'credit_id': 'sky-modern',
      'stars': [
        {
          'id': 'betelgeuse',
          'name': 'Betelgeuse',
          'ra_hours': 5.9,
          'dec_degrees': 7.4,
          'magnitude': .5,
        },
        {
          'id': 'rigel',
          'name': 'Rigel',
          'ra_hours': 5.2,
          'dec_degrees': -8.2,
          'magnitude': .1,
        },
      ],
      'lines': [
        ['betelgeuse', 'rigel'],
      ],
    },
    {
      'id': 'uma',
      'name_en': 'Ursa Major',
      'name_ru': 'Большая Медведица',
      'explanation_en': 'The Great Bear contains the Big Dipper asterism.',
      'explanation_ru': 'В Большой Медведице находится астеризм Ковш.',
      'credit_id': 'sky-modern',
      'stars': [
        {
          'id': 'dubhe',
          'name': 'Dubhe',
          'ra_hours': 11.1,
          'dec_degrees': 61.8,
          'magnitude': 1.8,
        },
        {
          'id': 'merak',
          'name': 'Merak',
          'ra_hours': 11.0,
          'dec_degrees': 56.4,
          'magnitude': 2.3,
        },
      ],
      'lines': [
        ['dubhe', 'merak'],
      ],
    },
  ],
);

Widget _app({TextScaler? scaler}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: scaler ?? TextScaler.noScaling),
    child: child!,
  ),
  home: ConstellationAtlasPage(
    catalog: _catalog,
    trainingBuilder: (_) => const Placeholder(),
  ),
);

void main() {
  test(
    'catalogue groups are derived from plotted declination, not visibility',
    () {
      expect(
        constellationSkyGroup({
          'stars': [
            {'dec_degrees': 30},
            {'dec_degrees': 40},
          ],
        }),
        ConstellationSkyGroup.north,
      );
      expect(
        constellationSkyGroup({
          'stars': [
            {'dec_degrees': -5},
            {'dec_degrees': 8},
          ],
        }),
        ConstellationSkyGroup.equatorial,
      );
    },
  );

  testWidgets('catalogue group filters use the plotted-star category', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('constellation-choose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('constellation-picker-groups')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('constellation-picker-group-north')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('constellation-option-uma')), findsOneWidget);
    expect(find.byKey(const Key('constellation-option-ori')), findsNothing);
  });

  testWidgets(
    'pinch keeps page still until the last map contact is cancelled',
    (tester) async {
      await tester.pumpWidget(_app());
      final viewer = find.byType(InteractiveViewer);
      final camera = tester
          .widget<InteractiveViewer>(viewer)
          .transformationController!;
      final page = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('constellation-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final centre = tester.getCenter(viewer);
      final left = await tester.startGesture(
        centre - const Offset(50, 0),
        pointer: 21,
      );
      final right = await tester.startGesture(
        centre + const Offset(50, 0),
        pointer: 22,
      );
      await tester.pump();
      await left.moveBy(const Offset(-30, 0));
      await right.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(camera.value.getMaxScaleOnAxis(), greaterThan(1.2));
      await left.up();
      await tester.pump();
      await tester.dragFrom(
        const Offset(5, 300),
        const Offset(0, -90),
        pointer: 23,
      );
      await tester.pump();
      expect(page.position.pixels, 0);
      await right.cancel();
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(5, 300), const Offset(0, -90));
      await tester.pumpAndSettle();
      expect(page.position.pixels, greaterThan(0));
    },
  );
  testWidgets('vertical touch drag moves the sky rather than its page', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final viewer = find.byType(InteractiveViewer);
    final camera = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    final page = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const Key('constellation-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final finger = await tester.startGesture(tester.getCenter(viewer));
    await tester.pump();
    await finger.moveBy(const Offset(0, -35));
    await tester.pump(const Duration(milliseconds: 16));
    await finger.moveBy(const Offset(0, -45));
    await finger.up();
    await tester.pumpAndSettle();
    expect(page.position.pixels, 0);
    expect(camera.value.storage[13], lessThan(-10));
    await tester.dragFrom(const Offset(5, 300), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(page.position.pixels, greaterThan(0));
  });
  testWidgets('coordinate canvas is not a centre-tap accessibility button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app());
      final chart = find.bySemanticsLabel(RegExp('Constellation star pattern'));
      expect(
        tester
            .getSemantics(chart)
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      final star = find.widgetWithText(OutlinedButton, 'Betelgeuse');
      await tester.ensureVisible(star);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(star)
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      await tester.tap(star);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('star-details-sheet')), findsOneWidget);
      expect(find.text('Betelgeuse'), findsWidgets);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('double-tap after a pan and zoom keeps the tapped point fixed', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final controller = viewer.transformationController!;
    controller.value = Matrix4.identity()
      ..translateByDouble(18, 24, 0, 1)
      ..scaleByDouble(1.7, 1.7, 1, 1);
    await tester.pump();
    const at = Offset(130, 100);
    final before = controller.toScene(at);
    final global = tester.getTopLeft(find.byType(InteractiveViewer)) + at;
    await tester.tapAt(global);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(global);
    await tester.pumpAndSettle();
    expect((controller.toScene(at) - before).distance, lessThan(.001));
    expect(controller.value.getMaxScaleOnAxis(), closeTo(3.06, .001));
  });
  testWidgets('zoom buttons clamp to the minimum and maximum scales', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    controller.value = Matrix4.identity()..scaleByDouble(1.1, 1.1, 1, 1);
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Zoom out'));
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), 1);
    controller.value = Matrix4.identity()..scaleByDouble(7.5, 7.5, 1, 1);
    await tester.pump();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), 8);
  });
  testWidgets('the visible star label opens the same facts as its dot', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final canvas = find.byKey(const Key('constellation-canvas'));
    await tester.ensureVisible(canvas);
    final stars = (_catalog.constellations.first['stars'] as List)
        .cast<Map<String, dynamic>>();
    final dot = projectConstellation(
      stars,
      tester.getSize(canvas),
    )['betelgeuse']!;
    await tester.tapAt(tester.getTopLeft(canvas) + dot + const Offset(55, -12));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('star-details-sheet')), findsOneWidget);
    expect(find.text('Betelgeuse'), findsWidgets);
  });
  testWidgets(
    'short landscape chooser remains scrollable above a tall keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(_app(scaler: const TextScaler.linear(1.5)));
      await tester.tap(find.byKey(const Key('constellation-choose')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const Key('constellation-search')),
        'ursa',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('constellation-option-uma')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byKey(const Key('constellation-option-uma'))).dy,
        lessThan(100),
      );
      await tester.tap(find.byKey(const Key('constellation-option-uma')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('constellation-search')), findsNothing);
      expect(find.text('Ursa Major'), findsWidgets);
    },
  );
  testWidgets(
    'zoom buttons keep the actual canvas centre fixed on a wide screen',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app());
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final size = tester.getSize(
        find.byKey(const Key('constellation-canvas')),
      );
      final centre = Offset(size.width / 2, size.height / 2);
      final before = viewer.transformationController!.toScene(centre);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(
        (viewer.transformationController!.toScene(centre) - before).distance,
        lessThan(.001),
      );
    },
  );
  testWidgets(
    'star tap opens readable facts immediately without moving the camera',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app());
      final canvas = find.byKey(const Key('constellation-canvas'));
      final stars = (_catalog.constellations.first['stars'] as List)
          .cast<Map<String, dynamic>>();
      final at = projectConstellation(
        stars,
        tester.getSize(canvas),
      )['betelgeuse']!;
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final before = viewer.transformationController!.value.clone();

      await tester.tapAt(tester.getTopLeft(canvas) + at);
      // A single tap waits for the normal double-tap recognition window.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('star-details-sheet')), findsOneWidget);
      expect(find.textContaining('magnitude'), findsWidgets);
      expect(viewer.transformationController!.value, before);
      await tester.tap(find.byTooltip('Close star facts'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('star-details-sheet')), findsNothing);
      expect(
        find.byKey(const Key('constellation-selected-star')),
        findsOneWidget,
      );
    },
  );
  testWidgets('constellation search list stays above the phone keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_app(scaler: const TextScaler.linear(1.5)));
    await tester.tap(find.byKey(const Key('constellation-choose')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    final list = find.byKey(const Key('constellation-picker-scroll'));
    expect(tester.getBottomRight(list).dy, lessThanOrEqualTo(288));
    expect(tester.takeException(), isNull);
  });
  testWidgets('a visible star can be tapped on a phone width canvas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app());
    final canvas = find.byKey(const Key('constellation-canvas'));
    await tester.ensureVisible(canvas);
    final size = tester.getSize(canvas);
    final stars = (_catalog.constellations.first['stars'] as List)
        .cast<Map<String, dynamic>>();
    final at = projectConstellation(stars, size)['betelgeuse']!;
    await tester.tapAt(tester.getTopLeft(canvas) + at);
    await tester.pumpAndSettle();
    expect(find.textContaining('magnitude'), findsWidgets);
  });
  testWidgets('search selects a constellation and exposes its stars', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.byKey(const Key('constellation-search')), findsNothing);
    await tester.tap(find.byKey(const Key('constellation-choose')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('constellation-search')),
      'ursa',
    );
    await tester.pump();
    expect(find.byKey(const Key('constellation-option-uma')), findsOneWidget);
    expect(find.byKey(const Key('constellation-option-ori')), findsNothing);

    await tester.tap(find.byKey(const Key('constellation-option-uma')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('constellation-search')), findsNothing);
    expect(find.text('Dubhe'), findsOneWidget);
    expect(
      find.text('The Great Bear contains the Big Dipper asterism.'),
      findsOneWidget,
    );
  });

  testWidgets('previous and next buttons cycle through constellations', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('Orion'), findsWidgets);

    await tester.tap(find.byTooltip('Next constellation'));
    await tester.pumpAndSettle();
    expect(find.text('Ursa Major'), findsWidgets);

    await tester.tap(find.byTooltip('Previous constellation'));
    await tester.pumpAndSettle();
    expect(find.text('Orion'), findsWidgets);
  });

  testWidgets(
    'reset is available after zoom and large text keeps the controls usable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(scaler: const TextScaler.linear(1.5)));

      final pageScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byTooltip('Zoom in'),
        200,
        scrollable: pageScroll,
      );
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Reset view'),
        200,
        scrollable: pageScroll,
      );
      expect(find.byTooltip('Reset view'), findsOneWidget);
      await tester.tap(find.byTooltip('Reset view'));
      await tester.pumpAndSettle();
      expect(find.text('Start training'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
