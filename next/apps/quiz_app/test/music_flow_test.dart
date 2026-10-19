import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/music_learning.dart';

Map<String, dynamic> fixture() => {
  'schema': 'qm-music-learning/v1',
  'sources': [
    {
      'id': 's',
      'title': 'Source',
      'url': 'https://example.org/music',
      'checked_on': '2026-10-19',
    },
  ],
  'entries': [
    for (final id in ['a', 'b', 'c', 'd'])
      {
        'id': id,
        'category': id == 'b' ? 'instruments' : 'notation',
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
    for (final id in ['a', 'b'])
      {
        'id': 'q-$id',
        'stem_ru': 'Вопрос $id',
        'stem_en': 'Question $id',
        'option_ids': ['a', 'b', 'c', 'd'],
        'correct_id': id,
        'explanation_ru': 'Объяснение $id',
        'explanation_en': 'Explanation $id',
        'source_ids': ['s'],
      },
  ],
};

class Bundle extends CachingAssetBundle {
  Bundle(this.value);
  final Object value;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(jsonEncode(value));
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'country entry link immediately opens the requested sourced card',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MusicLearningPage(
            bundle: Bundle(fixture()),
            initialEntryId: 'b',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Example b'), findsOneWidget);
      expect(find.text('Source · 2026-10-19'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('two check events before a frame count the answer only once', (
    tester,
  ) async {
    final raw = fixture();
    (raw['questions'] as List).removeLast();
    await tester.pumpWidget(
      MaterialApp(home: MusicLearningPage(bundle: Bundle(raw), training: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('music-option-a')));
    await tester.pump();
    final check = tester
        .widget<FilledButton>(find.byKey(const Key('music-check')))
        .onPressed!;
    check();
    check();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('music-next')));
    await tester.tap(find.byKey(const Key('music-next')));
    await tester.pumpAndSettle();
    expect(find.text('Score 1 / 1'), findsOneWidget);
  });
  test('catalog rejects broken option and citation references', () {
    for (final field in ['source_ids', 'option_ids']) {
      final raw = fixture();
      (raw['questions'] as List).first[field] = field == 'source_ids'
          ? ['missing']
          : ['a', 'b', 'c', 'missing'];
      expect(() => MusicCatalog.fromJson(raw), throwsFormatException);
    }
    final raw = fixture();
    (raw['questions'] as List).first['option_ids'] = ['a', 'a', 'b', 'c'];
    expect(() => MusicCatalog.fromJson(raw), throwsFormatException);
  });
  test('catalog rejects invalid notation and dates rather than painting corrupt examples', () {
    final raw = fixture();
    (raw['entries'] as List).first['visual'] = {'note': 7};
    expect(() => MusicCatalog.fromJson(raw), throwsFormatException);
    final date = fixture();
    (date['sources'] as List).first['checked_on'] = '2026-02-30';
    expect(() => MusicCatalog.fromJson(date), throwsFormatException);
  });
  test('shipped questions and country cards have matching valid learning references', () {
    final music = MusicCatalog.fromJson(
      jsonDecode(
        File('assets/quizipedia/music_learning.json').readAsStringSync(),
      ),
    );
    final culture = jsonDecode(
      File('assets/quizipedia/country_culture.json').readAsStringSync(),
    ) as Map;
    for (final rows in (culture['countries'] as Map).values) {
      for (final row in rows as List) {
        expect(music.entries.containsKey(row['id']), isTrue);
        expect(music.sources.containsKey(row['source_id']), isTrue);
      }
    }
    expect(music.entries['note-0']!.visual, {'note': 0});
    expect(music.entries['note-6']!.visual, {'note': 6});
    expect(music.entries['sharp']!.visual, {'glyph': 0xE262});
  });
  testWidgets(
    'cold training starts a finite round and mistakes retain original score',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MusicLearningPage(bundle: Bundle(fixture()), training: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Check'), findsOneWidget);
      expect(find.text('Source · 2026-10-19'), findsNothing);
      for (var i = 0; i < 2; i++) {
        final correct = find.text('Question a').evaluate().isNotEmpty
            ? 'a'
            : 'b';
        await tester.tap(
          find.byKey(Key('music-option-${i == 0 ? 'd' : correct}')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('music-check')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Source · 2026-10-19'), 180);
        expect(find.text('Source · 2026-10-19'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('music-next')));
        await tester.tap(find.byKey(const Key('music-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Score 1 / 2'), findsOneWidget);
      await tester.tap(find.text('Retry mistakes'));
      await tester.pumpAndSettle();
      final correct = find.text('Question a').evaluate().isNotEmpty ? 'a' : 'b';
      await tester.tap(find.byKey(Key('music-option-$correct')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('music-check')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('music-next')));
      await tester.tap(find.byKey(const Key('music-next')));
      await tester.pumpAndSettle();
      expect(find.text('Score 1 / 2'), findsOneWidget);
      expect(find.text('Retry mistakes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('topic filtering keeps distractors outside the chosen topic', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MusicLearningPage(bundle: Bundle(fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('music-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orchestra').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('music-entry-b')), findsOneWidget);
    expect(find.byKey(const Key('music-entry-a')), findsNothing);
    await tester.tap(find.byKey(const Key('music-practice')));
    await tester.pumpAndSettle();
    for (final id in ['a', 'b', 'c', 'd']) {
      expect(find.byKey(Key('music-option-$id')), findsOneWidget);
    }
    expect(find.text('Question b'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'large-text mobile search opens sourced notation details and handles no results',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final raw = jsonDecode(
        File('assets/quizipedia/music_learning.json').readAsStringSync(),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: MusicLearningPage(bundle: Bundle(raw)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('music-search')),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(find.byKey(const Key('music-search')), 'диез');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('music-entry-sharp')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.byKey(const Key('music-entry-sharp')));
      await tester.tap(find.byKey(const Key('music-entry-sharp')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('music-detail')),
          matching: find.byType(MusicVisual),
        ),
        findsOneWidget,
      );
      expect(find.text('Диез'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('music-search')));
      await tester.enterText(
        find.byKey(const Key('music-search')),
        'zz-no-match',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing found.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
