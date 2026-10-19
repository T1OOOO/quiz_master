import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/organ_atlas.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.text);
  final String text;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(text);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError('text only');
}

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  late String text;
  await tester.runAsync(() async {
    text = await rootBundle.loadString('assets/quizipedia/organ_atlas.json');
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.6)),
        child: child!,
      ),
      home: OrganAtlasPage(bundle: _Bundle(text)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets(
    'all shipped structures remain reachable through the accessible list and search',
    (tester) async {
      await _mount(tester);
      late Map<String, dynamic> raw;
      await tester.runAsync(() async {
        raw = jsonDecode(
          await rootBundle.loadString('assets/quizipedia/organ_atlas.json'),
        ) as Map<String, dynamic>;
      });
      final ids = (raw['organs'] as List).cast<Map>();
      expect(ids, hasLength(69));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is OutlinedButton &&
              widget.key.toString().contains('organ-list-'),
        ),
        findsNWidgets(69),
      );
      await tester.enterText(find.byKey(const Key('organ-search')), 'thyroid');
      await tester.pump();
      expect(find.byKey(const Key('organ-list-thyroid')), findsOneWidget);
      expect(find.byKey(const Key('organ-list-heart')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('touching the heart illustration opens its card at a user zoom', (
    tester,
  ) async {
    await _mount(tester);
    final map = find.byKey(const Key('organ-map'));
    final camera = tester
        .widget<InteractiveViewer>(map)
        .transformationController!;
    camera.value = Matrix4.identity()..scaleByDouble(1.2, 1.2, 1, 1);
    final before = camera.value.clone();
    await Scrollable.ensureVisible(tester.element(map), alignment: .2);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('organ-list-heart')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('organ-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('organ-list-heart')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.ensureVisible(map);
    await tester.pumpAndSettle();
    final heartMarker = find.byKey(const Key('organ-map-target-heart'));
    expect(heartMarker, findsOneWidget);
    final markerCenter = tester.getCenter(heartMarker);
    final mapOrigin = tester.getTopLeft(map);
    expect((markerCenter.dx - mapOrigin.dx) / 1.2, closeTo(162, 4));
    expect((markerCenter.dy - mapOrigin.dy) / 1.2, closeTo(189, 4));
    await tester.tap(heartMarker);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('organ-detail')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('organ-detail')),
        matching: find.text('Heart'),
      ),
      findsOneWidget,
    );
    expect(camera.value.storage, before.storage);
    expect(tester.takeException(), isNull);
  });
}
