import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/brand_atlas.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle({Map<String, dynamic>? atlas}) : _data = atlas ?? _atlas;

  final Map<String, dynamic> _data;

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(jsonEncode(_data));

  @override
  Future<ByteData> load(String key) => throw UnsupportedError('text only');
}

final _atlas = <String, dynamic>{
  'schema_version': 'qm-brand-atlas/v1',
  'coverage_note_ru': 'Учебная подборка.',
  'coverage_note_en': 'Learning sample.',
  'sources': [
    {
      'id': 'source',
      'title': 'Проверяемый источник',
      'url': 'https://example.org/source',
      'checked_on': '2026-10-21',
    },
  ],
  'owners': [
    for (final index in List<int>.generate(6, (index) => index))
      {
        'id': 'owner-$index',
        'name': 'Группа $index',
        'description_ru': 'Записанный владелец $index.',
        'description_en': 'Recorded owner $index.',
        'source_ids': ['source'],
      },
  ],
  'brands': [
    for (final index in List<int>.generate(6, (index) => index))
      {
        'id': 'brand-$index',
        'name': 'Марка $index',
        'sector_ru': 'Техника',
        'sector_en': 'Technology',
        'country_ru': 'Страна',
        'country_en': 'Country',
        'founded_year': null,
        'date_scope': 'brand',
        'date_note_ru': 'Год в этом макете не указан.',
        'date_note_en': 'No year in this fixture.',
        'owner_id': 'owner-$index',
        'ownership_note_ru': 'Записанный владелец марки $index.',
        'ownership_note_en': 'Recorded owner for brand $index.',
        'ownership_checked_on': '2026-10-21',
        'founders': [],
        'former_names': [],
        'facts': [
          {
            'text_ru': 'Записанный факт $index.',
            'text_en': 'Recorded fact $index.',
            'source_ids': ['source'],
          },
        ],
        'logo_history': [],
        'source_ids': ['source'],
      },
  ],
};

Map<String, dynamic> _atlasWithAwsFact() {
  final data = jsonDecode(jsonEncode(_atlas)) as Map<String, dynamic>;
  (data['brands'] as List).add({
    'id': 'aws',
    'name': 'AWS',
    'sector_ru': 'технологии',
    'sector_en': 'technology',
    'country_ru': 'США',
    'country_en': 'United States',
    'founded_year': 2006,
    'date_scope': 'brand',
    'date_note_ru': 'Облачные сервисы AWS запущены в 2006 году.',
    'date_note_en': 'AWS cloud services launched in 2006.',
    'owner_id': 'owner-0',
    'ownership_note_ru': 'Облачное направление Amazon.com, Inc.',
    'ownership_note_en': 'Cloud business of Amazon.com, Inc.',
    'ownership_checked_on': '2026-10-21',
    'founders': [],
    'former_names': [],
    'facts': [
      {
        'text_ru': 'AWS — сокращение от Amazon Web Services.',
        'text_en': 'AWS stands for Amazon Web Services.',
        'source_ids': ['source'],
      },
    ],
    'logo_history': [],
    'source_ids': ['source'],
  });
  return data;
}

void main() {
  testWidgets(
    'wrong brand answer names both answers and explains every locked option',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: BrandAtlasPage(bundle: _Bundle()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('brand-train')));
      await tester.pumpAndSettle();

      final questions = BrandAtlas.fromJson(_atlas).questions;
      final question = questions.firstWhere(
        (item) => find.text(item.promptRu).evaluate().isNotEmpty,
      );
      final wrongIndex = question.options.indexWhere(
        (option) => option != question.answer,
      );
      final wrong = question.options[wrongIndex];
      final selectedButton = find.ancestor(
        of: find.text(wrong),
        matching: find.byType(OutlinedButton),
      );
      final selectedKey =
          tester.widget<OutlinedButton>(selectedButton).key!
              as ValueKey<String>;
      final selectedIndex = int.parse(selectedKey.value.split('-').last);
      await tester.tap(selectedButton);
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Проверить');
      await tester.drag(
        find.byKey(const Key('brand-practice-scroll')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand-feedback-your')), findsOneWidget);
      expect(find.byKey(const Key('brand-feedback-correct')), findsOneWidget);
      expect(find.text('Ваш ответ: $wrong'), findsOneWidget);
      expect(find.text('Правильный ответ: ${question.answer}'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      final practiceScrollable = find.descendant(
        of: find.byKey(const Key('brand-practice-scroll')),
        matching: find.byType(Scrollable),
      );
      for (var index = 0; index < question.options.length; index++) {
        final option = find.byKey(Key('brand-option-$index'));
        await tester.scrollUntilVisible(
          option,
          300,
          scrollable: practiceScrollable,
        );
        expect(tester.widget<OutlinedButton>(option).onPressed, isNull);
        if (index == selectedIndex) {
          expect(
            RegExp('Ваш ответ: неверно')
                .allMatches(tester.getSemantics(option).label)
                .length,
            1,
          );
        }
      }
      semantics.dispose();

      await tester.scrollUntilVisible(
        find.byKey(const Key('brand-option-explanations')),
        300,
        scrollable: practiceScrollable,
      );
      await tester.tap(find.byKey(const Key('brand-option-explanations')));
      await tester.pumpAndSettle();
      for (var index = 0; index < question.options.length; index++) {
        expect(
          find.byKey(Key('brand-option-explanation-$index')),
          findsOneWidget,
        );
      }
      final selectedExplanation = find.byKey(
        Key('brand-option-explanation-$selectedIndex'),
      );
      expect(
        find.descendant(
          of: selectedExplanation,
          matching: find.text('Ваш ответ: неверно'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: selectedExplanation,
          matching: find.byIcon(Icons.cancel_outlined),
        ),
        findsOneWidget,
      );
      for (var index = 0; index < question.options.length; index++) {
        expect(find.text('Записанный владелец $index.'), findsOneWidget);
      }
      final next = find.byKey(const Key('brand-next'));
      await tester.scrollUntilVisible(
        next,
        300,
        scrollable: practiceScrollable,
      );
      expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'six-option brand feedback wraps on a narrow phone at text scale two',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: BrandAtlasPage(bundle: _Bundle()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('brand-scroll')),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('brand-train')));
      await tester.pumpAndSettle();

      final question = BrandAtlas.fromJson(_atlas).questions
          .firstWhere((item) => find.text(item.promptRu).evaluate().isNotEmpty);
      expect(question.options, hasLength(6));
      final wrongLabel = question.options.firstWhere(
        (option) => option != question.answer,
      );
      await tester.drag(
        find.byKey(const Key('brand-practice-scroll')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      // The production generator shuffles options for each atlas instance.
      // Select by the stable, known-wrong label rendered in this sheet, not by
      // an index from the independently constructed fixture question.
      final wrongChoice = find.widgetWithText(OutlinedButton, wrongLabel);
      await tester.ensureVisible(wrongChoice);
      await tester.tap(wrongChoice);
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Проверить');
      await tester.drag(
        find.byKey(const Key('brand-practice-scroll')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('brand-feedback-your')), findsOneWidget);
      expect(find.byKey(const Key('brand-feedback-correct')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Russian AWS fact keeps the spoken abbreviation distinct from its name',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: BrandAtlasPage(bundle: _Bundle(atlas: _atlasWithAwsFact())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('brand-search')), 'AWS');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Амазон Веб Сервисез').last);
      await tester.pumpAndSettle();

      expect(find.text('Амазон Веб Сервисез'), findsAtLeastNWidgets(1));
      final fact = tester.widget<Text>(find.textContaining('сокращение')).data;
      expect(fact, '• Эй-дабл-ю-эс — сокращение от Амазон Веб Сервисез.');
    },
  );
}
