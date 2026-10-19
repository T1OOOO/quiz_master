import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_atlas.dart';

void main() {
  testWidgets('work and creator links open usable detail sheets in both directions', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: KnowledgeAtlasPage(section: 'culture')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('knowledge-search')), 'Homer');
    await tester.pumpAndSettle();
    final creator = find.widgetWithText(ActionChip, 'Homer');
    await tester.ensureVisible(creator.first);
    await tester.tap(creator.first);
    await tester.pumpAndSettle();
    expect(find.text('Homer'), findsWidgets);
    final work = find.widgetWithText(ActionChip, 'The Odyssey');
    await tester.ensureVisible(work.last);
    await tester.tap(work.last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Homer'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
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
      expect(find.byType(OutlinedButton), findsNWidgets(4));
    },
  );
}
