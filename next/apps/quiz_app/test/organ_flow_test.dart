import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/organ_atlas.dart';

class _Bundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(
        jsonEncode({
          'schema_version': 'qm-organ-atlas/v1',
          'coverage_note_en': 'Fixture',
          'coverage_note_ru': 'Макет',
          'sources': [
            {
              'id': 's',
              'title': 'Fixture source',
              'url': 'https://example.org/source',
              'checked_on': '2026-10-19',
            },
          ],
          'organs': [
            for (final id in ['heart', 'brain', 'thyroid', 'liver'])
              {
                'id': id,
                'name_en': id,
                'name_ru': id,
                'kind': 'organ',
                'region': 'thorax',
                'system_ids': ['endocrine'],
                'position_en': 'Position',
                'position_ru': 'Положение',
                'function_en': 'Function',
                'function_ru': 'Функция',
                'secretions_en': [],
                'secretions_ru': [],
                'facts': [
                  {
                    'text_en': 'Fact',
                    'text_ru': 'Факт',
                    'source_ids': ['s'],
                  },
                ],
                'note_en': '',
                'note_ru': '',
                'source_ids': ['s'],
              },
          ],
          'questions': [
            for (var i = 0; i < 2; i++)
              {
                'id': 'q$i',
                'topic': 'fact',
                'stem_en': 'Prompt $i',
                'stem_ru': 'Вопрос $i',
                'option_ids': ['heart', 'brain', 'thyroid', 'liver'],
                'correct_id': i == 0 ? 'heart' : 'brain',
                'explanation_en': 'Explanation',
                'explanation_ru': 'Объяснение',
                'source_ids': ['s'],
              },
          ],
        }),
      );
  @override
  Future<ByteData> load(String key) => throw UnsupportedError('text only');
}

void main() {
  testWidgets('training entry starts a real question after loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OrganAtlasPage(bundle: _Bundle(), training: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('organ-check')), findsOneWidget);
    expect(find.textContaining('1/2'), findsOneWidget);
  });
  testWidgets(
    'finite mistakes review preserves original numerator and denominator',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OrganAtlasPage(bundle: _Bundle())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      Future<void> answer(bool correct) async {
        final id = correct
            ? (find.text('Prompt 0').evaluate().isNotEmpty ? 'heart' : 'brain')
            : 'thyroid';
        await tester.tap(find.byKey(Key('organ-option-$id')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('organ-check')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('organ-next')));
        await tester.pumpAndSettle();
      }

      await answer(false);
      await answer(true);
      expect(find.text('Original score: 1/2'), findsOneWidget);
      await tester.tap(find.text('Review mistakes (1)'));
      await tester.pumpAndSettle();
      await answer(true);
      expect(find.text('Original score: 1/2'), findsOneWidget);
      expect(find.text('Review mistakes (1)'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
