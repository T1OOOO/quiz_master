import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/organ_atlas.dart';
import 'package:quiz_app/organ_atlas_models.dart';

final _atlas = <String, dynamic>{
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
      ['thyroid', 'Thyroid', 'Щитовидная железа', 'neck', 'endocrine_gland'],
      ['heart', 'Heart', 'Сердце', 'thorax', 'organ'],
      ['liver', 'Liver', 'Печень', 'abdomen', 'exocrine_gland'],
    ])
      {
        'id': row[0],
        'name_en': row[1],
        'name_ru': row[2],
        'system_ids': ['endocrine'],
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
  ],
  'questions': [
    {
      'id': 'q1',
      'topic': 'location',
      'stem_en': 'Which?',
      'stem_ru': 'Что?',
      'option_ids': ['brain', 'thyroid', 'heart', 'liver'],
      'correct_id': 'heart',
      'explanation_en': 'Because.',
      'explanation_ru': 'Потому что.',
      'source_ids': ['s'],
    },
  ],
};

class _AtlasBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      jsonEncode(_atlas);
}

void main() {
  testWidgets(
    'vertical map drag pans organs rather than the surrounding page',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OrganAtlasPage(bundle: _AtlasBundle())),
      );
      await tester.pumpAndSettle();
      final map = find.byKey(const Key('organ-map'));
      final camera = tester
          .widget<InteractiveViewer>(map)
          .transformationController!;
      final before = camera.value.storage[13];
      final page = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('organ-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final top = page.position.pixels;
      final finger = await tester.startGesture(tester.getCenter(map));
      await tester.pump();
      await finger.moveBy(const Offset(0, -35));
      await tester.pump(const Duration(milliseconds: 16));
      await finger.moveBy(const Offset(0, -45));
      await finger.up();
      await tester.pumpAndSettle();
      expect(page.position.pixels, top);
      expect((camera.value.storage[13] - before).abs(), greaterThan(10));
    },
  );
  test('parses immutable atlas data and creates a finite fair round', () {
    final atlas = OrganAtlas.fromJson(_atlas);
    expect(atlas.organs, hasLength(4));
    expect(atlas.round(seed: 4, count: 1).single.correctId, 'heart');
    expect(() => atlas.organs.add(atlas.organs.first), throwsUnsupportedError);
  });

  test('rejects bad source references and ambiguous question options', () {
    final badSource = Map<String, dynamic>.from(_atlas)
      ..['organs'] = [
        Map<String, dynamic>.from((_atlas['organs'] as List).first)
          ..['source_ids'] = ['missing'],
      ];
    expect(() => OrganAtlas.fromJson(badSource), throwsFormatException);

    final badQuestion = Map<String, dynamic>.from(_atlas)
      ..['questions'] = [
        Map<String, dynamic>.from((_atlas['questions'] as List).first)
          ..['option_ids'] = ['brain', 'brain', 'heart', 'liver'],
      ];
    expect(() => OrganAtlas.fromJson(badQuestion), throwsFormatException);
  });

  test('camera scale uses the visible x/y basis rather than the z basis', () {
    final zoomedOut = Matrix4.identity()..scaleByDouble(.8, .8, 1, 1);
    expect(organAtlasCameraScale(zoomedOut), closeTo(.8, .0001));
  });

  testWidgets(
    'map callout selects detail without changing camera on a narrow large-text view',
    (tester) async {
      tester.view.physicalSize = const Size(360, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: OrganAtlasPage(bundle: _AtlasBundle()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final map = find.byKey(const Key('organ-map'));
      final viewer = tester.widget<InteractiveViewer>(map);
      final before = viewer.transformationController!.value.storage[0];
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('organ-map-target-brain'))),
        alignment: .3,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('organ-map-target-brain')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('organ-detail')), findsOneWidget);
      expect(
        tester
            .widget<InteractiveViewer>(map)
            .transformationController!
            .value
            .storage[0],
        before,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('organ-search')));
      await tester.enterText(find.byKey(const Key('organ-search')), 'thyroid');
      await tester.pump();
      expect(find.byKey(const Key('organ-list-thyroid')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('organ-filters')));
      await tester.tap(find.byKey(const Key('organ-filters')));
      await tester.pumpAndSettle();
      expect(find.text('Endocrine system'), findsOneWidget);
    },
  );
}
