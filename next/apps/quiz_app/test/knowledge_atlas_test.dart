import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_atlas.dart';

void main() {
  testWidgets('empty valid atlas disables connection practice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KnowledgeAtlasPage(
          section: 'history',
          bundle: _EmptyKnowledgeBundle(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final train = tester.widget<FilledButton>(
      find.byKey(const Key('knowledge-train')),
    );
    expect(train.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'work and creator links open usable detail sheets in both directions',
    (tester) async {
      late String source;
      await tester.runAsync(() async {
        source = await rootBundle.loadString(
          'assets/quizipedia/knowledge_atlas.json',
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeAtlasPage(
            section: 'culture',
            bundle: _LoadedKnowledgeBundle(source),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('knowledge-search')),
        'Homer',
      );
      await tester.pumpAndSettle();
      final workEntry = find.byKey(const Key('knowledge-work-odyssey'));
      await tester.ensureVisible(workEntry);
      await tester.pumpAndSettle();
      await tester.tap(workEntry);
      await tester.pumpAndSettle();
      final creator = find.widgetWithText(ActionChip, 'Homer');
      await tester.ensureVisible(creator.first);
      await tester.pumpAndSettle();
      await tester.tap(creator.first);
      await tester.pumpAndSettle();
      expect(find.text('Homer'), findsWidgets);
      final work = find.widgetWithText(ActionChip, 'The Odyssey');
      await tester.ensureVisible(work.last);
      await tester.tap(work.last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, 'Homer'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'event sheet moves through sorted visible events and honors era boundaries',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final atlas = KnowledgeAtlas.fromJson(
        jsonDecode(
          File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final all = atlas.events;
      final second = all[1];
      final third = all[2];
      await tester.pumpWidget(
        const MaterialApp(home: KnowledgeAtlasPage(section: 'history')),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      final secondEntry = find.byKey(Key('knowledge-event-${second.id}'));
      await tester.scrollUntilVisible(
        secondEntry,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(secondEntry);
      await tester.pumpAndSettle();
      await tester.tap(secondEntry);
      await tester.pumpAndSettle();
      expect(find.text(second.titleEn).hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Previous event'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byTooltip('Next event'));
      await tester.pumpAndSettle();
      expect(find.text(third.titleEn).hitTestable(), findsOneWidget);
      tester.view.physicalSize = const Size(393, 851);
      await tester.pumpAndSettle();
      expect(
        find.text(third.titleEn).hitTestable(),
        findsOneWidget,
        reason:
            'Viewport changes retain the event currently shown in the sheet.',
      );
      await tester.tap(find.byTooltip('Previous event'));
      await tester.pumpAndSettle();
      expect(find.text(second.titleEn).hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'era-filtered event sheet disables navigation at its boundaries',
    (tester) async {
      final atlas = KnowledgeAtlas.fromJson(
        jsonDecode(
          File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final medieval = atlas.events
          .where((event) => event.era == 'medieval')
          .toList();
      await tester.pumpWidget(
        const MaterialApp(home: KnowledgeAtlasPage(section: 'history')),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();
      final medievalChip = find.widgetWithText(ChoiceChip, 'Middle Ages');
      await tester.ensureVisible(medievalChip);
      await tester.tap(medievalChip);
      await tester.pumpAndSettle();
      final firstEraEntry = find.byKey(
        Key('knowledge-event-${medieval.first.id}'),
      );
      await tester.scrollUntilVisible(
        firstEraEntry,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(firstEraEntry);
      await tester.pumpAndSettle();
      await tester.tap(firstEraEntry);
      await tester.pumpAndSettle();
      expect(find.text(medieval.first.titleEn).hitTestable(), findsOneWidget);
      IconButton button(String tooltip) => tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(button('Previous event').onPressed, isNull);
      for (var i = 1; i < medieval.length; i++) {
        await tester.tap(find.byTooltip('Next event'));
        await tester.pumpAndSettle();
      }
      expect(find.text(medieval.last.titleEn).hitTestable(), findsOneWidget);
      expect(button('Next event').onPressed, isNull);
    },
  );

  test('work chronology preserves approximate composition ranges', () {
    final atlas = KnowledgeAtlas.fromJson(
      jsonDecode(
        File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
      ),
    );
    final work = atlas.works.firstWhere((w) => w.id == 'divine_comedy');
    expect(work.approximate, isTrue);
    expect(work.endYear, 1321);
  });
  test(
    'knowledge atlas snapshot keeps a chronological, linked learning graph',
    () {
      final raw = jsonDecode(
        File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final atlas = KnowledgeAtlas.fromJson(raw);

      expect(atlas.events.length, greaterThanOrEqualTo(40));
      expect(atlas.works.length, greaterThanOrEqualTo(30));
      expect(atlas.people.length, greaterThanOrEqualTo(25));
      for (var index = 1; index < atlas.events.length; index++) {
        expect(
          atlas.events[index - 1].year,
          lessThanOrEqualTo(atlas.events[index].year),
        );
      }
      expect(
        atlas.events.every((event) => event.sourceUrl.startsWith('https://')),
        isTrue,
      );
      expect(atlas.works.every((work) => work.creatorIds.isNotEmpty), isTrue);
      expect(
        atlas.people.every((person) => person.creditWorkIds.isNotEmpty),
        isTrue,
      );
    },
  );

  test('date and relation questions have one correct answer and no true alternative', () {
    final atlas = KnowledgeAtlas.fromJson(
      jsonDecode(
        File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final questions = atlas.questions;
    expect(questions, isNotEmpty);
    for (final question in questions) {
      expect(question.options, hasLength(6));
      expect(question.options.toSet().length, question.options.length);
      expect(
        question.options.where((value) => value == question.answer),
        hasLength(1),
      );
    }
    expect(
      questions.where(
        (question) => question.kind == KnowledgeQuestionKind.order,
      ),
      isNotEmpty,
    );
    expect(
      questions.where(
        (question) => question.kind == KnowledgeQuestionKind.creator,
      ),
      isNotEmpty,
    );
    expect(
      questions.where(
        (question) => question.kind == KnowledgeQuestionKind.credit,
      ),
      isNotEmpty,
    );
  });

  testWidgets(
    'history screen opens local unranked practice on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: KnowledgeAtlasPage(section: 'history')),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      final train = find.byKey(const Key('knowledge-train'));
      await tester.tap(train);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Unranked practice'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(6));
    },
  );
}

class _EmptyKnowledgeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData(0);
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      jsonEncode({
        'schema_version': 'qm-knowledge-atlas/v1',
        'events': [],
        'works': [],
        'people': [],
      });
}

// Preload the real data before fake-async pumping: a fixed wall-clock delay
// races asset decoding under the full parallel suite.
class _LoadedKnowledgeBundle extends CachingAssetBundle {
  _LoadedKnowledgeBundle(this.source);
  final String source;
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == 'assets/quizipedia/knowledge_atlas.json'
      ? Future.value(source)
      : rootBundle.loadString(key, cache: cache);
}
