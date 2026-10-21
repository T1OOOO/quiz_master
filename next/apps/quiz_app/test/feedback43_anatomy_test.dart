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
        'system_ids': [row[0] == 'kidney' ? 'endocrine' : 'musculoskeletal'],
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

  testWidgets('initial scoped training does not load questions outside bones', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: OrganAtlasPage(
          bundle: _Bundle(),
          initialScope: OrganAtlasScope.bones,
          training: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The fixture question only names four organs; it must not appear in the
    // bone route merely because training started before the atlas UI did.
    expect(
      find.text('Нет подходящих вопросов для этих фильтров.'),
      findsOneWidget,
    );
    expect(find.text('Что?'), findsNothing);
  });

  testWidgets(
    'major illustrated organs are all selectable before browsing the directory',
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
      expect(find.byKey(const Key('organ-map-target-brain')), findsOneWidget);
      expect(find.byKey(const Key('organ-map-target-heart')), findsOneWidget);
      expect(find.byKey(const Key('organ-map-target-liver')), findsOneWidget);
      expect(find.byKey(const Key('organ-directory')), findsOneWidget);
      expect(find.byKey(const Key('organ-list-skeleton')), findsNothing);
      await tester.tap(find.byKey(const Key('organ-map-target-heart')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('organ-detail')), findsOneWidget);
      expect(find.text('Сердце'), findsOneWidget);
    },
  );

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

      await tester.ensureVisible(find.byKey(const Key('organ-filters')));
      await tester.tap(find.byKey(const Key('organ-filters')));
      await tester.pumpAndSettle();
      expect(find.text('Группа костей'), findsOneWidget);
      expect(find.text('Отдел мозга'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('organ-search')));
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

  testWidgets('bones open as a separate named catalogue', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: OrganAtlasPage(
          bundle: _Bundle(),
          initialScope: OrganAtlasScope.bones,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Каталог костей'), findsOneWidget);
    expect(find.byKey(const Key('organ-directory-bones')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('organ-directory-bones')));
    await tester.tap(find.byKey(const Key('organ-directory-bones')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('organ-list-skeleton')), findsOneWidget);
    expect(find.byKey(const Key('organ-list-heart')), findsNothing);
    expect(find.byKey(const Key('anatomy-scene')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('anatomy-marker-skull')));
    await tester.tap(find.byKey(const Key('anatomy-marker-skull')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('anatomy-show-all')), findsOneWidget);
  });

  for (final size in [const Size(361, 738), const Size(393, 851)]) {
    testWidgets('systems exposes groups and kidney card immediately at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: OrganAtlasPage(
            bundle: _Bundle(),
            initialScope: OrganAtlasScope.systems,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Системы организма'), findsOneWidget);
      expect(find.byKey(const Key('organ-map')), findsNothing);
      final endocrine = find.byKey(const Key('organ-system-endocrine'));
      expect(endocrine, findsOneWidget);
      final bounds = tester.getRect(endocrine);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      await tester.tap(endocrine);
      await tester.pumpAndSettle();
      final kidney = find.byKey(const Key('organ-list-kidney'));
      await tester.ensureVisible(kidney);
      await tester.tap(kidney);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('organ-detail')), findsOneWidget);
      expect(find.text('Почка'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('brain scene selects only a visibly labelled brain card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: OrganAtlasPage(
          bundle: _Bundle(),
          initialScope: OrganAtlasScope.brain,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('anatomy-scene')), findsOneWidget);
    await tester.tap(find.byKey(const Key('anatomy-marker-cerebellum')));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('organ-list-cerebellum'))),
    );
    expect(find.byKey(const Key('organ-list-cerebellum')), findsOneWidget);
    expect(find.byKey(const Key('anatomy-show-all')), findsOneWidget);
  });

  testWidgets('bone illustration exposes working manual zoom controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrganAtlasPage(
          bundle: _Bundle(),
          initialScope: OrganAtlasScope.bones,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scene = find.byKey(const Key('anatomy-scene'));
    final viewer = tester.widget<InteractiveViewer>(scene);
    final before = viewer.transformationController!.value.storage[0];
    expect(viewer.scaleEnabled, isTrue);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<InteractiveViewer>(scene)
          .transformationController!
          .value
          .storage[0],
      greaterThan(before),
    );
  });

  for (final size in [const Size(361, 738), const Size(393, 851)]) {
    testWidgets('bone catalogue remains usable at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: OrganAtlasPage(
            bundle: _Bundle(),
            initialScope: OrganAtlasScope.bones,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Каталог костей'), findsOneWidget);
      final directory = find.byKey(const Key('organ-directory-bones'));
      await tester.ensureVisible(directory);
      await tester.tap(directory);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('organ-list-skeleton')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
