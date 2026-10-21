import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quiz_app/organ_atlas.dart';

class _Bundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(jsonEncode(_atlas));

  @override
  Future<ByteData> load(String key) => throw UnsupportedError('text only');
}

final _atlas = <String, dynamic>{
  'schema_version': 'qm-organ-atlas/v1',
  'coverage_note_en': 'Fixture',
  'coverage_note_ru': 'Макет',
  'sources': [
    {
      'id': 's',
      'title': 'Fixture source',
      'url': 'https://example.org/source',
      'checked_on': '2026-10-21',
    },
  ],
  'organs': [
    for (final item in const [
      ('sublingual', 'Sublingual glands', 'Подъязычные железы'),
      ('submandibular', 'Submandibular glands', 'Поднижнечелюстные железы'),
      ('parotid', 'Parotid glands', 'Околоушные железы'),
      ('thyroid', 'Thyroid gland', 'Щитовидная железа'),
      ('pituitary', 'Pituitary gland', 'Гипофиз'),
      ('adrenal', 'Adrenal glands', 'Надпочечники'),
    ])
      {
        'id': item.$1,
        'name_en': item.$2,
        'name_ru': item.$3,
        'kind': 'endocrine_gland',
        'region': 'head',
        'system_ids': ['endocrine'],
        'position_en': 'Recorded position for ${item.$2}.',
        'position_ru': 'Записанное положение: ${item.$3}.',
        'function_en': 'Recorded function for ${item.$2}.',
        'function_ru': 'Записанная функция: ${item.$3}.',
        'secretions_en': [],
        'secretions_ru': [],
        'facts': [
          {
            'text_en': 'Fixture fact.',
            'text_ru': 'Факт макета.',
            'source_ids': ['s'],
          },
        ],
        'note_en': '',
        'note_ru': '',
        'source_ids': ['s'],
      },
  ],
  'questions': [
    {
      'id': 'under-tongue',
      'topic': 'location',
      'stem_en': 'Which glands are under the tongue?',
      'stem_ru': 'Какие железы под языком?',
      'option_ids': [
        'sublingual',
        'submandibular',
        'parotid',
        'thyroid',
        'pituitary',
        'adrenal',
      ],
      'correct_id': 'sublingual',
      'explanation_en': 'The atlas identifies the sublingual glands.',
      'explanation_ru': 'Атлас указывает на подъязычные железы.',
      'source_ids': ['s'],
    },
  ],
};

void main() {
  testWidgets(
    'wrong organ answer names both answers and distinguishes every checked option',
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
          home: OrganAtlasPage(bundle: _Bundle(), training: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('organ-feedback-your')), findsNothing);
      await tester.tap(find.byKey(const Key('organ-option-submandibular')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('organ-check')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('organ-feedback-your')), findsOneWidget);
      expect(find.byKey(const Key('organ-feedback-correct')), findsOneWidget);
      expect(find.text('Ваш ответ: Поднижнечелюстные железы'), findsOneWidget);
      expect(find.text('Правильный ответ: Подъязычные железы'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsAtLeastNWidgets(2));
      expect(find.byIcon(Icons.check_circle_outline), findsAtLeastNWidgets(2));
      final explanations = find.byKey(const Key('organ-option-explanations'));
      await tester.ensureVisible(explanations);
      await tester.tap(explanations);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('organ-option-explanation-sublingual')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('organ-option-explanation-sublingual')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Положение: Записанное положение: Подъязычные железы.',
        ),
        findsOneWidget,
      );
      for (final id in const [
        'sublingual',
        'submandibular',
        'parotid',
        'thyroid',
        'pituitary',
        'adrenal',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(find.byKey(Key('organ-option-$id')))
              .onPressed,
          isNull,
        );
      }
      expect(find.byKey(const Key('organ-next')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
