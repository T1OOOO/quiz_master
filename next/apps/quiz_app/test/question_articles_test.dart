import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/question_articles.dart';

Map<String, dynamic> article({String status = 'accepted'}) => {
  'id': 'quizipedia:landmark:eiffel',
  'status': status,
  'title_ru': 'Башня и выставка',
  'body_ru': 'Эйфелева башня находится в Париже.\n\n## Как её узнавать\nТри уровня и ажурные опоры.',
  'target_refs': [
    {'kind': 'quizipedia', 'domain': 'landmark', 'target_id': 'eiffel'},
  ],
  'question_refs': [
    {
      'quiz_id': 'quiz-test',
      'question_id': 'q-tower',
      'revision_sha256': 'a' * 64,
    },
  ],
  'source_links': [
    {
      'title': 'История',
      'url': 'https://www.toureiffel.paris/en/the-monument/history',
    },
    {'title': 'Париж', 'url': 'https://whc.unesco.org/en/list/600/'},
  ],
};

String catalog(List<Map<String, dynamic>> articles) => jsonEncode({
  'schema_version': 'qm-question-articles/v1',
  'articles': articles,
});

class _Bundle extends CachingAssetBundle {
  _Bundle(this.source);
  final String source;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
}

void main() {
  test(
    'articles match exact quiz revision, not only a reusable question ID',
    () {
      final data = QuestionArticles.decode(catalog([article()]));
      expect(data.forTarget('landmark', 'eiffel')?.title, 'Башня и выставка');
      expect(data.forTarget('anatomy', 'eiffel'), isNull);
      expect(data.forQuestion('quiz-test', 'q-tower', 'a' * 64), isNotNull);
      expect(data.forQuestion('other-quiz', 'q-tower', 'a' * 64), isNull);
      expect(data.forQuestion('quiz-test', 'q-tower', 'b' * 64), isNull);
    },
  );

  test('drafts, duplicate articles and unsafe source schemes fail closed', () {
    expect(
      () => QuestionArticles.decode(catalog([article(status: 'draft')])),
      throwsFormatException,
    );
    expect(
      () => QuestionArticles.decode(catalog([article(), article()])),
      throwsFormatException,
    );
    final unsafe = article();
    (unsafe['source_links'] as List)[0]['url'] = 'javascript:alert(1)';
    expect(
      () => QuestionArticles.decode(catalog([unsafe])),
      throwsFormatException,
    );
  });

  testWidgets(
    'mobile reader pauses before opening and puts checked links at the end',
    (tester) async {
      tester.view.physicalSize = const Size(361, 682);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var paused = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuestionArticleLink(
              domain: 'landmark',
              targetId: 'eiffel',
              bundle: _Bundle(catalog([article()])),
              onBeforeOpen: () => paused = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuestionArticleReader), findsNothing);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(paused, isTrue);
      expect(find.byType(QuestionArticleReader), findsOneWidget);
      expect(find.text('История'), findsOneWidget);
      expect(find.text('Париж'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('История')).dy,
        greaterThan(tester.getTopLeft(find.text('Как её узнавать')).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionArticleReader), findsNothing);
    },
  );

  testWidgets('missing article does not suggest an unwritten article', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionArticleLink(
            domain: 'landmark',
            targetId: 'missing',
            bundle: _Bundle(catalog([article()])),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextButton), findsNothing);
  });
}
