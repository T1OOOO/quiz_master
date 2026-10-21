import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/brand_atlas.dart';

class _Bundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(jsonEncode(_atlas));

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

void main() {
  testWidgets(
    'wrong brand answer names both answers and explains every locked option',
    (tester) async {
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
      }

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
      await tester.drag(
        find.byKey(const Key('brand-practice-scroll')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      final wrongIndex = question.options.indexWhere(
        (option) =>
            option != question.answer &&
            find
                .byKey(Key('brand-option-${question.options.indexOf(option)}'))
                .evaluate()
                .isNotEmpty,
      );
      expect(wrongIndex, isNonNegative);
      await tester.tap(find.byKey(Key('brand-option-$wrongIndex')));
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
}
