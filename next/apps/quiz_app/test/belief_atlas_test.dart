import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/belief_atlas.dart';
import 'package:quiz_app/belief_atlas_models.dart';

void main() {
  test('parser enforces frozen references, https dates and four answers', () {
    expect(
      () => BeliefAtlas.fromJson({..._fixture(), 'schema_version': 'bad'}),
      throwsFormatException,
    );
    final bad = _fixture();
    (bad['questions'] as List).first['option_ids'] = ['zeus', 'hera'];
    expect(() => BeliefAtlas.fromJson(bad), throwsFormatException);
    expect(
      BeliefAtlas.fromJson(_fixture()).round('greek', seed: 1),
      hasLength(6),
    );
    final noHost = _fixture();
    (noHost['sources'] as List).first['url'] = 'https:///missing-host';
    expect(() => BeliefAtlas.fromJson(noHost), throwsFormatException);
    final noRefs = _fixture();
    (noRefs['nodes'] as List).first['source_ids'] = <String>[];
    expect(() => BeliefAtlas.fromJson(noRefs), throwsFormatException);
  });

  testWidgets(
    'graph selection preserves a manual transform and deep list selection is visible',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(scaler: const TextScaler.linear(1.5)));
      await tester.pumpAndSettle();
      final before = tester
          .widget<InteractiveViewer>(find.byKey(const Key('belief-graph')))
          .transformationController!
          .value
          .clone();
      // Zoom controls sit below the graph and scroll the surrounding map into
      // view. Return to the graph before tapping a real transformed node.
      final graph = find.byKey(const Key('belief-graph'));
      await tester.ensureVisible(graph);
      await tester.pumpAndSettle();
      final hera = find.byKey(const Key('belief-node-hera'));
      expect(tester.getRect(graph).overlaps(tester.getRect(hera)), isTrue);
      await tester.tap(hera);
      await tester.pump();
      final after = tester
          .widget<InteractiveViewer>(find.byKey(const Key('belief-graph')))
          .transformationController!
          .value;
      expect(after.storage, before.storage);
      expect(find.byKey(const Key('belief-detail')), findsOneWidget);
      final heraButton = tester.widget<FilledButton>(hera);
      expect(
        heraButton.style!.backgroundColor!.resolve(<WidgetState>{}),
        Theme.of(tester.element(hera)).colorScheme.primary,
      );
      await tester.enterText(find.byKey(const Key('belief-search')), 'Hera');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('belief-list-hera')));
      await tester.tap(find.byKey(const Key('belief-list-hera')));
      await tester.pumpAndSettle();
      expect(find.text('Hera'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'initial overview fits several Greek nodes and relations without moving on selection',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('belief-node-zeus')), findsOneWidget);
      expect(find.byKey(const Key('belief-node-hera')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Zeus → Athena: Father')),
        findsOneWidget,
      );
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('belief-graph')),
      );
      final initial = viewer.transformationController!.value.clone();
      expect(initial.entry(0, 0), lessThanOrEqualTo(1));
      await tester.tap(find.byKey(const Key('belief-node-hera')));
      await tester.pump();
      expect(
        tester
            .widget<InteractiveViewer>(find.byKey(const Key('belief-graph')))
            .transformationController!
            .value
            .storage,
        initial.storage,
      );
    },
  );

  testWidgets(
    'full 21-node graph has a reachable scene and fit changes scale',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: BeliefAtlasPage(bundle: _Bundle(jsonEncode(_largeFixture()))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('belief-node-zeus')), findsOneWidget);
      expect(find.byKey(const Key('belief-node-node-20')), findsNothing);
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Full graph'));
      await tester.tap(find.widgetWithText(FilterChip, 'Full graph'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('belief-scene'))).height,
        greaterThan(500),
      );
      expect(find.bySemanticsLabel('Node 20'), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('belief-fit')));
      await tester.tap(find.byKey(const Key('belief-fit')));
      await tester.pump();
      expect(
        tester
            .widget<InteractiveViewer>(find.byKey(const Key('belief-graph')))
            .transformationController!
            .value
            .entry(0, 0),
        lessThan(1),
      );
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('belief-graph')),
      );
      final scale = viewer.transformationController!.value.entry(0, 0);
      expect(
        tester.getSize(find.byKey(const Key('belief-scene'))).height * scale,
        lessThanOrEqualTo(280.01),
      );
    },
  );

  testWidgets('switching to religions fits its overview once', (tester) async {
    final data = _fixture();
    final religions = <Map<String, Object>>[
      for (final id in ['tradition-a', 'tradition-b'])
        {
          ...Map<String, Object>.from((data['nodes'] as List).first),
          'id': id,
          'section': 'religions',
          'name_en': id,
          'name_ru': id,
        },
    ];
    (data['nodes'] as List).addAll(religions);
    (data['edges'] as List).add({
      'id': 'religion-edge',
      'from_id': 'tradition-a',
      'to_id': 'tradition-b',
      'label_ru': 'Связь',
      'label_en': 'Relation',
      'scope_ru': 'Традиция',
      'scope_en': 'Tradition',
      'source_ids': ['s'],
    });
    await tester.pumpWidget(
      MaterialApp(home: BeliefAtlasPage(bundle: _Bundle(jsonEncode(data)))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Religions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('belief-node-tradition-a')), findsOneWidget);
    expect(
      tester
          .widget<InteractiveViewer>(find.byKey(const Key('belief-graph')))
          .transformationController!
          .value
          .entry(0, 0),
      lessThanOrEqualTo(1),
    );
  });

  testWidgets(
    'checked quiz completes finite mistakes review and retry is asynchronous',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('belief-quiz')));
      await tester.tap(find.byKey(const Key('belief-quiz')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        final wrong = find.widgetWithText(OutlinedButton, 'Hera');
        await tester.ensureVisible(wrong);
        await tester.tap(wrong);
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('belief-check')));
        await tester.tap(find.byKey(const Key('belief-check')));
        await tester.pump();
        expect(find.textContaining('Source:'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('belief-next')));
        await tester.tap(find.byKey(const Key('belief-next')));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Original score:'), findsOneWidget);
      await tester.tap(find.text('Retry missed'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app({TextScaler? scaler}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: scaler ?? TextScaler.noScaling),
    child: BeliefAtlasPage(bundle: _Bundle(jsonEncode(_fixture()))),
  ),
);

class _Bundle extends CachingAssetBundle {
  _Bundle(this.value);
  final String value;
  @override
  Future<ByteData> load(String key) async => throw FlutterError('binary');
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      key == beliefAtlasAsset ? value : throw FlutterError('asset');
}

Map<String, dynamic> _fixture() => {
  'schema_version': 'qm-belief-atlas/v1',
  'coverage_note_ru': 'Учебная подборка.',
  'coverage_note_en': 'Learning sample.',
  'sources': [
    {
      'id': 's',
      'title': 'Reference',
      'url': 'https://example.com/source',
      'checked_on': '2026-10-19',
    },
  ],
  'nodes': [
    for (final n in ['zeus', 'hera', 'athena', 'ares', 'apollo', 'artemis'])
      {
        'id': n,
        'section': 'greek',
        'name_ru': n,
        'name_en': n[0].toUpperCase() + n.substring(1),
        'group_ru': 'Олимпийцы',
        'group_en': 'Olympians',
        'summary_ru': 'Кратко.',
        'summary_en': 'Summary.',
        'domains_ru': ['роль'],
        'domains_en': ['role'],
        'symbols_ru': ['символ'],
        'symbols_en': ['symbol'],
        'facts': [
          {
            'text_ru': 'Факт.',
            'text_en': 'Fact.',
            'source_ids': ['s'],
          },
        ],
        'variant_note_ru': '',
        'variant_note_en': '',
        'source_ids': ['s'],
      },
  ],
  'edges': [
    {
      'id': 'e1',
      'from_id': 'zeus',
      'to_id': 'athena',
      'label_ru': 'Отец',
      'label_en': 'Father',
      'scope_ru': 'Tradition',
      'scope_en': 'Tradition',
      'source_ids': ['s'],
    },
    {
      'id': 'e2',
      'from_id': 'zeus',
      'to_id': 'hera',
      'label_ru': 'Супруги',
      'label_en': 'Spouses',
      'scope_ru': 'Tradition',
      'scope_en': 'Tradition',
      'source_ids': ['s'],
    },
  ],
  'questions': [
    for (var i = 0; i < 6; i++)
      {
        'id': 'q$i',
        'section': 'greek',
        'stem_ru': 'Кто $i?',
        'stem_en': 'Who is $i?',
        'option_ids': ['zeus', 'hera', 'athena', 'ares'],
        'correct_id': 'zeus',
        'explanation_ru': 'Объяснение.',
        'explanation_en': 'Explanation.',
        'source_ids': ['s'],
      },
  ],
};

Map<String, dynamic> _largeFixture() {
  final data = _fixture();
  final rows = List<dynamic>.from(data['nodes'] as List);
  data['nodes'] = rows;
  final template = Map<String, dynamic>.from(rows.first as Map);
  for (var i = 6; i <= 20; i++) {
    rows.add({
      ...template,
      'id': 'node-$i',
      'name_en': 'Node $i',
      'name_ru': 'Узел $i',
    });
  }
  return data;
}
