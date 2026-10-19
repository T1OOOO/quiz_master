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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'all 52 shipped map callouts are reachable through finite pages',
    (tester) async {
      await _mount(tester);
      final visited = <String>{};
      for (var page = 0; page < 7; page++) {
        final targets = find.byWidgetPredicate(
          (w) =>
              w is FilledButton &&
              w.key.toString().contains('organ-map-target-'),
        );
        for (final element in targets.evaluate()) {
          visited.add(element.widget.key.toString());
        }
        if (page < 6) {
          await tester.ensureVisible(
            find.byKey(const Key('organ-callouts-next')),
          );
          await tester.tap(find.byKey(const Key('organ-callouts-next')));
          await tester.pumpAndSettle();
        }
      }
      expect(visited.length, 52);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('organ-callouts-next')))
            .onPressed,
        isNull,
      );
      final target = find
          .byWidgetPredicate(
            (w) =>
                w is FilledButton &&
                w.key.toString().contains('organ-map-target-'),
          )
          .last;
      final camera = tester
          .widget<InteractiveViewer>(find.byKey(const Key('organ-map')))
          .transformationController!;
      final before = camera.value.clone();
      await Scrollable.ensureVisible(tester.element(target), alignment: .4);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('organ-detail')), findsOneWidget);
      expect(camera.value.storage, before.storage);
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
    await tester.tapAt(
      tester.getTopLeft(map) + const Offset(169 * 1.2, 179 * 1.2),
    );
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
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getTopLeft(map) + const Offset(181 * 1.2, 320 * 1.2),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('organ-detail')),
        matching: find.text('Kidneys'),
      ),
      findsOneWidget,
    );
    expect(camera.value.storage, before.storage);
    expect(tester.takeException(), isNull);
  });
}
