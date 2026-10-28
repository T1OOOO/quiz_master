import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quiz_app/knowledge_map/countries_browser.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
  testWidgets('searches all countries and selects an unmapped country', (
    tester,
  ) async {
    MapCountry? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountriesBrowser(
            countries: const [
              MapCountry(
                id: 'FR',
                nameRu: 'Франция',
                nameEn: 'France',
                capital: 'Paris',
                population: 10,
                area: 20,
              ),
              MapCountry(id: 'XX', nameRu: 'Другая', nameEn: 'Other'),
            ],
            mappedIds: const {'FR'},
            onSelect: (country) => selected = country,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'other');
    await tester.pump();
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Not on map'), findsOneWidget);
    await tester.tap(find.text('Other'));
    expect(selected?.id, 'XX');
  });
  testWidgets('table shows fields and missing data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountriesBrowser(
            countries: const [
              MapCountry(id: 'XX', nameRu: 'Другая', nameEn: 'Other'),
            ],
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.text('Capital'), findsOneWidget);
    expect(find.text('Population'), findsOneWidget);
    expect(find.text('Area, km²'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
  });
  testWidgets(
    'compact table scrolls both ways and selects an unmapped country',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MapCountry? selected;
      final countries = List.generate(
        20,
        (i) => MapCountry(
          id: '$i',
          nameRu: 'Страна $i',
          nameEn: 'Country ${i.toString().padLeft(2, '0')}',
          capital: 'Capital',
          area: 42,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: CountriesBrowser(
                countries: countries,
                mappedIds: const {},
                onSelect: (c) => selected = c,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Table'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Swipe sideways to see the table'), findsOneWidget);
      final horizontal = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      await tester.drag(horizontal, const Offset(-1200, 0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Area, km²')).dx, lessThan(320));
      await tester.drag(horizontal, const Offset(1200, 0));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(160, 400), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Country 19'));
      expect(selected?.id, '19');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Russian capital, close control and table without checkboxes', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: CountriesBrowser(
            countries: const [
              MapCountry(
                id: 'AT',
                nameRu: 'Австрия',
                nameEn: 'Austria',
                capital: 'Vienna',
              ),
            ],
            onSelect: (_) {},
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    expect(find.textContaining('Вена'), findsOneWidget);
    await tester.tap(find.text('Таблица'));
    await tester.pumpAndSettle();
    expect(find.text('Вена'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Прокрутите таблицу в сторону'), findsOneWidget);
    await tester.tap(find.byTooltip('Закрыть'));
    expect(closed, isTrue);
  });
}
