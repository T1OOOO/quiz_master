import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/belief_atlas.dart';
import 'package:quiz_app/belief_atlas_models.dart';

void main() {
  testWidgets(
    'vertical map drag pans beliefs rather than the surrounding page',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BeliefAtlasPage(
            initialSection: 'religions',
            bundle: _Bundle(jsonEncode(_religionFixture)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final map = find.byKey(const Key('belief-graph'));
      await tester.ensureVisible(map);
      await tester.pumpAndSettle();
      final camera = tester
          .widget<InteractiveViewer>(map)
          .transformationController!;
      final before = camera.value.storage[13];
      final page = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('belief-scroll')),
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
  test('narrow geometry stacks two nodes and keeps an edge caption clear', () {
    final geometry = BeliefGraphGeometry(viewportWidth: 288, count: 2);
    final first = geometry.nodeRect(0);
    final second = geometry.nodeRect(1);
    final caption = geometry.edgeCaptionRect(0, 1, const Size(180, 16));

    expect(geometry.narrow, isTrue);
    expect(geometry.columns, 1);
    expect(geometry.sceneWidth, 288);
    expect(first.left, greaterThanOrEqualTo(0));
    expect(first.right, lessThanOrEqualTo(288));
    expect(second.top, greaterThan(first.bottom));
    expect(first.overlaps(second), isFalse);
    expect(caption.overlaps(first), isFalse);
    expect(caption.overlaps(second), isFalse);
    expect(geometry.captionFits(caption, const []), isTrue);
    expect(geometry.captionFits(caption, [caption]), isFalse);
    final three = BeliefGraphGeometry(viewportWidth: 288, count: 3);
    final acrossMiddle = three.edgeCaptionRect(0, 2, const Size(180, 20));
    expect(three.captionFits(acrossMiddle, const []), isFalse);
  });

  testWidgets(
    'religion graph uses the narrow two-node scene at 320px and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: BeliefAtlasPage(
              initialSection: 'religions',
              bundle: _Bundle(jsonEncode(_religionFixture)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scene = find.byKey(const Key('belief-scene'));
      expect(tester.getSize(scene).width, 288);
      expect(tester.getSize(scene).height, greaterThanOrEqualTo(280));
      expect(tester.takeException(), isNull);
    },
  );
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.value);
  final String value;
  @override
  Future<ByteData> load(String key) async => throw FlutterError('binary');
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      key == beliefAtlasAsset ? value : throw FlutterError('asset');
}

final _religionFixture = {
  'schema_version': 'qm-belief-atlas/v1',
  'coverage_note_ru': 'Подборка.',
  'coverage_note_en': 'Sample.',
  'sources': [
    {
      'id': 's',
      'title': 'Reference',
      'url': 'https://example.com/source',
      'checked_on': '2026-10-19',
    },
  ],
  'nodes': [
    for (final id in [
      'tradition-a',
      'tradition-b',
      'tradition-c',
      'tradition-d',
    ])
      {
        'id': id,
        'section': 'religions',
        'name_ru': id == 'tradition-a'
            ? 'Традиция А'
            : id == 'tradition-b'
            ? 'Традиция Б'
            : id,
        'name_en': id,
        'group_ru': 'Группа',
        'group_en': 'Group',
        'summary_ru': 'Кратко.',
        'summary_en': 'Summary.',
        'domains_ru': ['тема'],
        'domains_en': ['topic'],
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
      'id': 'edge',
      'from_id': 'tradition-a',
      'to_id': 'tradition-b',
      'label_ru': 'Связь',
      'label_en': 'Link',
      'scope_ru': 'Учебная',
      'scope_en': 'Learning',
      'source_ids': ['s'],
    },
  ],
  'questions': [
    {
      'id': 'q',
      'section': 'religions',
      'stem_ru': 'Кто?',
      'stem_en': 'Who?',
      'option_ids': [
        'tradition-c',
        'tradition-d',
        'tradition-a',
        'tradition-b',
      ],
      'correct_id': 'tradition-a',
      'explanation_ru': 'Пояснение.',
      'explanation_en': 'Explanation.',
      'source_ids': ['s'],
    },
  ],
};
