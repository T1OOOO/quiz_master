import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/chronology_timeline.dart';

void main() {
  testWidgets('chronology sorts dates, selects entries and zooms on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(361, 738);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ChronologyTimeline(
            showEraFilters: true,
            showPractice: true,
            entries: const [
              ChronologyEntry(
                id: 'late',
                year: 2000,
                date: '2000',
                title: 'Позднее',
              ),
              ChronologyEntry(
                id: 'early',
                year: -500,
                date: '500 до н. э.',
                title: 'Ранее',
              ),
            ],
            onSelected: (id) => chosen = id,
          ),
        ),
      ),
    );
    expect(find.text('500 до н. э.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chronology-entry-early')));
    expect(chosen, 'early');
    final before = tester
        .getSize(find.byKey(const Key('chronology-entry-early')))
        .width;
    await tester.tap(find.byTooltip('Увеличить шкалу'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('chronology-entry-early'))).width,
      greaterThan(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chronology filters an era and checks which event happened first', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ChronologyTimeline(
            showEraFilters: true,
            showPractice: true,
            entries: const [
              ChronologyEntry(
                id: 'rome',
                year: 476,
                date: '476',
                title: 'Падение Западной Римской империи',
              ),
              ChronologyEntry(
                id: 'press',
                year: 1450,
                date: 'около 1450',
                title: 'Печатный пресс Гутенберга',
              ),
            ],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Все эпохи'), findsOneWidget);
    await tester.tap(find.text('Средневековье'));
    await tester.pumpAndSettle();
    expect(find.text('Печатный пресс Гутенберга'), findsOneWidget);
    expect(find.text('Падение Западной Римской империи'), findsNothing);
    await tester.tap(find.text('Все эпохи'));
    await tester.pumpAndSettle();
    expect(find.text('Тренировка'), findsOneWidget);
    await tester.tap(find.text('Тренировка'));
    await tester.pumpAndSettle();
    expect(find.text('Что произошло раньше?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(
        OutlinedButton,
        'Падение Западной Римской империи',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Верно: 476 раньше около 1450.'), findsOneWidget);
  });

  testWidgets('English practice skips equal years and rotates eligible pairs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ChronologyTimeline(
            showEraFilters: true,
            showPractice: true,
            entries: const [
              ChronologyEntry(id: 'a', year: 1900, date: '1900', title: 'A'),
              ChronologyEntry(id: 'b', year: 1900, date: '1900', title: 'B'),
              ChronologyEntry(id: 'c', year: 1913, date: '1913', title: 'C'),
            ],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('All eras'), findsOneWidget);
    expect(find.text('Early 20th century'), findsOneWidget);
    await tester.tap(find.text('Early 20th century'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'A'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'B'), findsNothing);
    expect(
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'A')).dy,
      lessThan(tester.getTopLeft(find.widgetWithText(OutlinedButton, 'C')).dy),
    );
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'A'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'B'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'C')).dy,
      lessThan(tester.getTopLeft(find.widgetWithText(OutlinedButton, 'B')).dy),
    );
  });
}
