import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/music_learning.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.data);
  final Map<String, dynamic> data;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(jsonEncode(data));
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

Map<String, dynamic> _fixture() => {
  'schema': 'qm-music-learning/v1',
  'sources': [
    {
      'id': 's',
      'title': 'Reference',
      'url': 'https://example.com/music',
      'checked_on': '2026-10-19',
    },
  ],
  'entries': [
    for (final id in ['a', 'b', 'c', 'd', 'e', 'f'])
      {
        'id': id,
        'category': 'notation',
        'name_ru': 'Название $id',
        'name_en': 'Name $id',
        'description_ru': 'Описание $id',
        'description_en': 'Description $id',
        'example_ru': 'Пример $id',
        'example_en': 'Example $id',
        'source_ids': ['s'],
      },
  ],
  'questions': [
    {
      'id': 'q-a',
      'stem_ru': 'Вопрос a',
      'stem_en': 'Question a',
      'option_ids': ['a', 'b', 'c', 'd'],
      'correct_id': 'a',
      'explanation_ru': 'Объяснение a',
      'explanation_en': 'Explanation a',
      'source_ids': ['s'],
    },
  ],
};

void main() {
  testWidgets(
    'wrong music choice reveals six expandable sourced explanations',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MusicLearningPage(bundle: _Bundle(_fixture()), training: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('music-choice-explanations')), findsNothing);

      await tester.tap(find.byKey(const Key('music-option-b')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('music-check')));
      await tester.pumpAndSettle();

      expect(find.text('Your choice was incorrect.'), findsOneWidget);
      expect(find.text('Correct answer.'), findsOneWidget);
      final explanations = find.byKey(const Key('music-choice-explanations'));
      await tester.scrollUntilVisible(explanations, 160);
      await tester.tap(explanations);
      await tester.pumpAndSettle();
      for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) {
        expect(find.byKey(Key('music-choice-explanation-$id')), findsOneWidget);
      }
      expect(find.text('Description b'), findsOneWidget);
      expect(find.text('Example b'), findsOneWidget);
    },
  );

  testWidgets('correct music choice stays explicit until manual next', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MusicLearningPage(bundle: _Bundle(_fixture()), training: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('music-option-a')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('music-check')));
    await tester.pumpAndSettle();
    expect(find.text('Correct answer.'), findsOneWidget);
    expect(find.text('Your choice was incorrect.'), findsNothing);
    final next = find.byKey(const Key('music-next'));
    await tester.scrollUntilVisible(next, 160);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Score 1 / 1'), findsOneWidget);
  });
}
