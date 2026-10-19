import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/brand_atlas.dart';

void main() {
  test('brand atlas validates links and makes safe foundation questions', () {
    final atlas = BrandAtlas.fromJson(_fixture());

    expect(atlas.brands, hasLength(4));
    expect(atlas.owners.single.id, 'owner-a');
    expect(atlas.questions, isNotEmpty);
    for (final question in atlas.questions) {
      expect(question.options, hasLength(4));
      expect(question.options.toSet(), hasLength(4));
      expect(
        question.options.where((item) => item == question.answer),
        hasLength(1),
      );
    }
  });

  test('brand atlas rejects unresolved owner and source references', () {
    final invalidOwner = _fixture()
      ..['brands'] = [
        {
          ...(_fixture()['brands'] as List).first as Map<String, dynamic>,
          'owner_id': 'missing',
        },
      ];
    expect(() => BrandAtlas.fromJson(invalidOwner), throwsFormatException);

    final invalidSource = _fixture()
      ..['brands'] = [
        {
          ...(_fixture()['brands'] as List).first as Map<String, dynamic>,
          'source_ids': ['missing'],
        },
      ];
    expect(() => BrandAtlas.fromJson(invalidSource), throwsFormatException);
  });

  test('brand atlas rejects impossible checked dates and URL without host', () {
    final invalidDate = _fixture()
      ..['sources'] = [
        {
          ...((_fixture()['sources'] as List).single as Map<String, dynamic>),
          'checked_on': '2026-99-99',
        },
      ];
    expect(() => BrandAtlas.fromJson(invalidDate), throwsFormatException);

    final invalidUrl = _fixture()
      ..['sources'] = [
        {
          ...((_fixture()['sources'] as List).single as Map<String, dynamic>),
          'url': 'https:///missing-host',
        },
      ];
    expect(() => BrandAtlas.fromJson(invalidUrl), throwsFormatException);
  });

  test(
    'a seeded round changes question order without changing answer integrity',
    () {
      final atlas = BrandAtlas.fromJson(_fixture());
      final first = atlas.questionsFor(seed: 1);
      final second = atlas.questionsFor(seed: 2);
      expect(
        first.map((item) => item.promptEn).take(10).toList(),
        isNot(equals(second.map((item) => item.promptEn).take(10).toList())),
      );
      expect(first.every((item) => item.options.contains(item.answer)), isTrue);
    },
  );

  testWidgets('a retry round is finite and preserves the first-round score', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: BrandAtlasPage(bundle: _Bundle(jsonEncode(_fixture()))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('brand-train')));
    await tester.pumpAndSettle();

    final atlas = BrandAtlas.fromJson(_fixture());
    for (var index = 0; index < 10; index++) {
      if (find.text('Check').evaluate().isEmpty) break;
      final question = atlas.questions.firstWhere(
        (item) => find.text(item.promptEn).evaluate().isNotEmpty,
      );
      final wrong = question.options.firstWhere(
        (item) => item != question.answer,
      );
      await tester.tap(find.text(wrong));
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Check');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
      final next = find.widgetWithText(FilledButton, 'Next');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      if (find.textContaining('Practice complete:').evaluate().isNotEmpty) {
        break;
      }
    }
    final scoreFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          ((widget.data ?? '').contains('correct') ||
              (widget.data ?? '').contains('верных')),
    );
    final firstScore = tester.widget<Text>(scoreFinder).data!;
    final retry = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          ((widget.data ?? '').contains('Retry missed') ||
              (widget.data ?? '').contains('Повторить ошибки')),
    );
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    for (var index = 0; index < 10; index++) {
      if (find.text('Check').evaluate().isEmpty) break;
      final question = atlas.questions.firstWhere(
        (item) => find.text(item.promptEn).evaluate().isNotEmpty,
      );
      final wrong = question.options.firstWhere(
        (item) => item != question.answer,
      );
      await tester.tap(find.text(wrong));
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Check');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pump();
      final next = find.widgetWithText(FilledButton, 'Next');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      if (find.text(firstScore).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text(firstScore), findsOneWidget);
  });

  testWidgets('narrow large-text view links brand to owner and back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: BrandAtlasPage(bundle: _Bundle(jsonEncode(_fixture()))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('brand-search')), 'Alpha');
    await tester.drag(
      find.byKey(const Key('brand-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('brand-a')));
    await tester.tap(find.byKey(const Key('brand-a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-detail')), findsOneWidget);
    final openOwner = find.widgetWithText(TextButton, 'Open owner card');
    await tester.drag(
      find.byKey(const Key('brand-scroll')),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();
    await tester.tap(openOwner);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-owner-detail')), findsOneWidget);
    final brandLink = find.widgetWithText(ActionChip, 'Beta');
    await tester.ensureVisible(brandLink);
    await tester.tap(brandLink);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-detail')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.value);
  final String value;
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('Unexpected binary asset $key');

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/quizipedia/brands.json') return value;
    throw FlutterError('Unexpected asset $key');
  }
}

Map<String, dynamic> _fixture() => {
  'schema_version': 'qm-brand-atlas/v1',
  'coverage_note_ru': 'Учебная подборка.',
  'coverage_note_en': 'Learning sample.',
  'sources': [
    {
      'id': 's1',
      'title': 'Primary source',
      'url': 'https://example.com/a',
      'checked_on': '2026-10-19',
    },
  ],
  'owners': [
    {
      'id': 'owner-a',
      'name': 'Group A',
      'description_ru': 'Владелец.',
      'description_en': 'Owner.',
      'source_ids': ['s1'],
    },
  ],
  'brands': [
    for (final row in [
      ['a', 'Alpha', 1901, 'Ada'],
      ['b', 'Beta', 1902, 'Bea'],
      ['c', 'Gamma', 1903, 'Cid'],
      ['d', 'Delta', 1904, 'Dee'],
    ])
      {
        'id': row[0],
        'name': row[1],
        'sector_ru': 'Техника',
        'sector_en': 'Technology',
        'country_ru': 'Страна',
        'country_en': 'Country',
        'founded_year': row[2],
        'date_note_ru': 'Основан.',
        'date_note_en': 'Founded.',
        'owner_id': 'owner-a',
        'ownership_note_ru': 'Владелец подтверждён.',
        'ownership_note_en': 'Ownership confirmed.',
        'ownership_checked_on': '2026-10-19',
        'founders': [row[3]],
        'former_names': [],
        'facts': [
          {
            'text_ru': 'Факт.',
            'text_en': 'Fact.',
            'source_ids': ['s1'],
          },
        ],
        'logo_history': [
          {
            'year': row[2],
            'text_ru': 'Первый знак.',
            'text_en': 'First mark.',
            'source_ids': ['s1'],
          },
        ],
        'source_ids': ['s1'],
      },
  ],
};
