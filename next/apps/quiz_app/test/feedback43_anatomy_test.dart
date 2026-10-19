import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/organ_atlas.dart';
import 'package:quiz_app/organ_atlas_models.dart';

final _anatomyFixture = <String, dynamic>{
  'schema_version': 'qm-organ-atlas/v1',
  'coverage_note_ru': 'Схема.',
  'coverage_note_en': 'A schematic.',
  'sources': [
    {
      'id': 's',
      'title': 'Source',
      'url': 'https://example.org/source',
      'checked_on': '2026-10-19',
    },
  ],
  'organs': [
    for (final row in [
      ['brain', 'Brain', 'Мозг', 'head', 'organ'],
      ['heart', 'Heart', 'Сердце', 'thorax', 'organ'],
      ['liver', 'Liver', 'Печень', 'abdomen', 'organ'],
      ['kidney', 'Kidney', 'Почка', 'abdomen', 'organ'],
    ])
      {
        'id': row[0],
        'name_en': row[1],
        'name_ru': row[2],
        'system_ids': ['musculoskeletal'],
        'kind': row[4],
        'region': row[3],
        'position_en': 'Approximate position.',
        'position_ru': 'Примерное положение.',
        'function_en': 'A function.',
        'function_ru': 'Функция.',
        'secretions_en': <String>[],
        'secretions_ru': <String>[],
        'facts': [
          {
            'text_en': 'A fact.',
            'text_ru': 'Факт.',
            'source_ids': ['s'],
          },
        ],
        'note_en': '',
        'note_ru': '',
        'source_ids': ['s'],
      },
    {
      'id': 'skeleton',
      'name_en': 'Skeleton',
      'name_ru': 'Скелет',
      'name_la': 'Skeleton',
      'bone_count': 206,
      'diagram_group': 'skeleton',
      'system_ids': ['musculoskeletal'],
      'kind': 'bone_group',
      'region': 'distributed',
      'position_en': 'Whole body.',
      'position_ru': 'Всё тело.',
      'function_en': 'Support.',
      'function_ru': 'Опора.',
      'secretions_en': <String>[],
      'secretions_ru': <String>[],
      'facts': [
        {
          'text_en': 'A fact.',
          'text_ru': 'Факт.',
          'source_ids': ['s'],
        },
      ],
      'note_en': '',
      'note_ru': '',
      'source_ids': ['s'],
    },
    {
      'id': 'cerebellum',
      'name_en': 'Cerebellum',
      'name_ru': 'Мозжечок',
      'diagram_group': 'brain',
      'system_ids': ['nervous'],
      'kind': 'brain_region',
      'region': 'head',
      'position_en': 'Head.',
      'position_ru': 'Голова.',
      'function_en': 'Coordination.',
      'function_ru': 'Координация.',
      'secretions_en': <String>[],
      'secretions_ru': <String>[],
      'facts': [
        {
          'text_en': 'A fact.',
          'text_ru': 'Факт.',
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
      'id': 'q1',
      'topic': 'location',
      'stem_en': 'Which?',
      'stem_ru': 'Что?',
      'option_ids': ['brain', 'heart', 'liver', 'kidney'],
      'correct_id': 'heart',
      'explanation_en': 'Because.',
      'explanation_ru': 'Потому что.',
      'source_ids': ['s'],
    },
  ],
};

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      jsonEncode(_anatomyFixture);
}

void main() {
  test('parses optional anatomy metadata and rejects invalid bone counts', () {
    final atlas = OrganAtlas.fromJson(_anatomyFixture);
    final skeleton = atlas.organ('skeleton');
    expect(skeleton.nameLa, 'Skeleton');
    expect(skeleton.boneCount, 206);
    expect(skeleton.diagramGroup, 'skeleton');
    expect(atlas.organ('cerebellum').kind, 'brain_region');

    final invalid =
        jsonDecode(jsonEncode(_anatomyFixture)) as Map<String, dynamic>;
    (invalid['organs'] as List).last['bone_count'] = 0;
    expect(() => OrganAtlas.fromJson(invalid), throwsFormatException);
  });

  testWidgets(
    'Russian atlas labels groups, searches Latin, and keeps unanchored groups honest',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: OrganAtlasPage(bundle: _Bundle()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('organ-filters')));
      await tester.pumpAndSettle();
      expect(find.text('Группа костей'), findsOneWidget);
      expect(find.text('Отдел мозга'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('organ-search')), 'skeleton');
      await tester.pump();
      expect(find.byKey(const Key('organ-list-skeleton')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('organ-list-skeleton')));
      await tester.tap(find.byKey(const Key('organ-list-skeleton')));
      await tester.pumpAndSettle();
      expect(find.text('Костей в группе: 206'), findsOneWidget);
      expect(find.text('Латинское название'), findsOneWidget);
      expect(find.byKey(const Key('organ-map-target-skeleton')), findsNothing);
    },
  );
}
