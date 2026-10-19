import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/country_learning.dart';
import 'package:quiz_app/quizipedia.dart';

const catalog = QuizipediaCatalog(
  countries: [],
  countryRows: [],
  mapTargetIds: [],
  anatomy: {},
  landmarks: [],
  constellations: [],
  credits: [],
);

class BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('missing asset');
}

void main() {
  testWidgets('country search also finds a sports club association', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CountryAtlasPage(catalog: catalog)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('map-country-search')),
      'Lakers',
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'United States'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'United States'));
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(find.byKey(const Key('quizipedia-viewport')));
    expect(viewer.transformationController!.value, Matrix4.identity(), reason: 'Country selection must preserve the user camera.');
    await tester.ensureVisible(find.text('Official language source'));
    expect(find.text('Official language source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('linked asset failure is visible to the loading screen', () async {
    await expectLater(
      loadCountryAssociations('missing', bundle: BrokenBundle()),
      throwsA(isA<FlutterError>()),
    );
  });
  testWidgets(
    'failed country facts have a visible retry instead of a spinner',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CountryAtlasPage(catalog: catalog, bundle: BrokenBundle()),
        ),
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'narrow scaled quiz reveals correct answer and can return to atlas',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const CountryAtlasPage(catalog: catalog),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Train 10 questions'));
      await tester.tap(find.text('Train 10 questions'));
      await tester.pumpAndSettle();
      final choices = find.byType(OutlinedButton);
      expect(choices, findsNWidgets(4));
      await tester.ensureVisible(choices.first);
      await tester.tap(choices.first);
      await tester.pump();
      await tester.ensureVisible(find.text('Check'));
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Correct answer:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Back to atlas'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map-country-search')), findsOneWidget);
    },
  );
}
