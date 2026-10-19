import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    'Russian 320x568 atlas keeps manual zoom above the shell navigation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('ru')],
            home: Scaffold(
              body: const CountryAtlasPage(catalog: _catalog),
              bottomNavigationBar: const SizedBox(height: 64),
            ),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      final zoomIn = find.byTooltip('Увеличить');
      expect(zoomIn, findsOneWidget);
      expect(
        tester.getRect(zoomIn).bottom,
        lessThanOrEqualTo(504),
        reason: 'The map consumes drag gestures, so zoom must be reachable before scrolling it.',
      );
      for (final label in [
        'Увеличить',
        'Уменьшить',
        'Весь мир',
        'Показать выбранную страну',
      ]) {
        final rect = tester.getRect(find.byTooltip(label));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.bottom, lessThanOrEqualTo(504));
      }
      final hint = find.text(
        'Перетаскивайте · сближайте пальцы · двойное касание для зума',
      );
      expect(tester.getRect(hint).bottom, lessThanOrEqualTo(504));
      final map = tester.widget<QuizipediaWorldMap>(
        find.byType(QuizipediaWorldMap),
      );
      await tester.tap(zoomIn);
      await tester.pumpAndSettle();
      expect(map.controller.value.getMaxScaleOnAxis(), greaterThan(1));
      await tester.tap(find.byTooltip('Весь мир'));
      await tester.pumpAndSettle();
      expect(map.controller.value, Matrix4.identity());
      expect(tester.takeException(), isNull);
    },
  );
}
