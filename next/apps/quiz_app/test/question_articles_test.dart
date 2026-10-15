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

  testWidgets(
    'article paragraphs expose readable labels and remain selectable',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        const paragraph = 'Readable article paragraph.';
        final data = article()..['body_ru'] = paragraph;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionArticleReader(
                article: QuestionArticles.decode(catalog([data]))
                    .articles
                    .single,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.semantics.byLabel(paragraph).evaluate(), hasLength(1));
        await tester.longPress(find.text(paragraph));
        await tester.pumpAndSettle();
        expect(find.text('Copy'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('reader stays above shell feedback and restores it on close', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var feedbackOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: QuestionArticleLink(
                    domain: 'landmark',
                    targetId: 'eiffel',
                    bundle: _Bundle(catalog([article()])),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 88,
              child: FloatingActionButton.small(
                onPressed: () => feedbackOpened = true,
                child: const Icon(Icons.support_agent),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final feedback = find.byIcon(Icons.support_agent);
    expect(feedback.hitTestable(), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionArticleReader), findsOneWidget);
    expect(feedback.hitTestable(), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionArticleReader), findsNothing);
    expect(feedback.hitTestable(), findsOneWidget);
    await tester.tap(feedback);
    expect(feedbackOpened, isTrue);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QuestionArticleReader), findsNothing);
    expect(feedback.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
    'packaged articles bind People, Film Craft, Music Craft, Acting Craft, Screen Song, Mixed, LOTR repair and published Home Alone revisions',
    (tester) async {
      final articles = QuestionArticles.decode(
        (await tester.runAsync(
          () => rootBundle.loadString(questionArticlesAsset),
        ))!,
      );

      expect(articles.articles, hasLength(283));
      for (final (quizId, questionId, revision) in [
        (
          'prep-film-actors-1',
          'cinema-oct3-001',
          '85a75608861c6733833f9a0e09299ff80b726145492eddfa5d29ac420ee0b149',
        ),
        (
          'prep-film-actors-1',
          'cinema-oct3-002',
          '6301535ddb447e1e38f84cdc5ae9cc24adf48d9a4555133bb8408324f6b57d55',
        ),
        (
          'prep-film-actors-1',
          'cinema-oct3-003',
          '18627a36f2a3285754c84c7b276c8b563f1d6f75b9d97172ca5369fab7d95833',
        ),
        (
          'prep-film-actors-1',
          'cinema-oct3-004',
          '340a7b66c7b868aeac86ab3e2240b2bb50977d7a780cc847d4b92bf292e04f1f',
        ),
        (
          'prep-greek-mythology',
          'greek-002',
          '038a7a47982dd284760ac2183c58f29d6a054ad708f8139fd5e0b9f74a0e5d5d',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-001',
          'ffba665c01970729b668367173aeeee8845eb9f02e69c64e91348c360efce2cd',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-002',
          '9eaffd1c9f2c770a9715d03726cdecfded33942fca0255e0628a5defd1b8a119',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-006',
          'a030f84979262904b5bb397e627c72d9240f2b5e4354b2fd51638b1d39dda53f',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-011',
          'd7c001f99efe5b784e85f2577023973bd7d089e1441b32093e59c29cd60a2d8a',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-012',
          'ac9b02a66246a4cf541382703812e2b69a24120cc236158c2419f8b74439a862',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-016',
          '40464345526c4665cf7ef2b79adf9a19f3afc661a4bfcfd3ebe62232569befba',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-003',
          'f26602052411e5247cf6f19bb676f44162fa3ac92e4e59ff580c28e5f0a92df0',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-007',
          '7676adc903b69189ec1e9d7eeefc63150dd2ec62d0acf1ec1b8e503e8fdbef5e',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-017',
          'eedded3c69f8327f9c8b5e7f299eaa5fa6876718f39020f2a6aecdc151aa8955',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-008',
          'a1a1eca62947e3d5d3132258b27f9aa797bcd96160eb0ff3b2e3ea291685b61f',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-013',
          '99749857f6bf288bb46962b0c40d5e5264304811190e61c7d241f0e0176d88ba',
        ),
        (
          'pub-connections-20261014',
          'pub-connections-009',
          '8ab130918f1ba0f1dce1b71538c9ae8461d8fedfd0b354d0cb5481de152a37cc',
        ),
        (
          'lotr-return-king-bts-100',
          'lotr-rk-93',
          '4c90dc9b8f716e6de64e9153694ebb9576a024983cff098f8c16f4d7adf302e4',
        ),
        (
          'lotr-return-king-bts-100',
          'lotr-rk-95',
          '36e5d42e3e8a3f639c9249ede4a04fcb6186fa8e3a826325f4ec4998b20db513',
        ),
        (
          'screen-song-20261014',
          'screen-song-pilot-001',
          '150814dc4fa8b6eab222527a95bd02966a728fcfd623bbd87f45256bad48ea53',
        ),
        (
          'screen-song-20261014',
          'screen-song-pilot-002',
          '7f9acdf2804c824d19c5ce3391965d5c365baf5f8b51c8c2d4e18f43fdcba6c6',
        ),
        (
          'screen-song-20261014',
          'screen-song-pilot-003',
          '4fdb4066ef242a4c40b8d5d7ef56d136fc2a407b47a217d03ec3b03a25357593',
        ),
        (
          'screen-song-20261014',
          'screen-song-pilot-004',
          '21c67a6b079acb30dcd1830ae3654ccae0044079452af685b6bb969d3a3e80fb',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-001',
          '0b211637a8a29d0708a33567d11fafb113773ed89aef5ba8afdde46bf1c11e44',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-002',
          '14df4c16dfc105fefdea35e733bdf1389b0f91debb950d7be65bde3252d468cd',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-003',
          '0d0073db567749ebd64b1dcaf91ca62109346cb1c0d2483c858ab45945dabbb7',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-004',
          '032702e68ba38fdedc73a698e880978c5c6fcd3331777485c8ab60380d72f49b',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-005',
          '594bd4f212f5713593331b4099054fbf9439a287c44eeec4792142c1e00e038c',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-006',
          '02adc130e3f8feab6b7e0b5dd021b33c4283af25fb6025aded5ed1a7ff627773',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-007',
          '7003a49c4bf117f83cd508c7c48c064d5b26daa3322c27078d288d52d5954f2a',
        ),
        (
          'acting-craft-20261014',
          'acting-craft-pilot-008',
          'e8561876f0dcbdc06dfe68f9ee9146913dc11b13a7fd2a98f840592984ef0fc0',
        ),
        (
          'music-craft-20261013',
          'music-craft-pilot-001',
          '77da33ef926035876257a74d005499a645eca08a2cfd63376192a834a01523b0',
        ),
        (
          'music-craft-20261013',
          'music-craft-pilot-002',
          '83e6da706ac7928cfa0585909ccafa90d94700b86b2406793a2213e26469f4d2',
        ),
        (
          'music-craft-20261013',
          'music-craft-pilot-003',
          '138727d30013be9205712ed14cc43bfbd35cc04dabaf517dba29202c6b851f44',
        ),
        (
          'music-craft-20261013',
          'music-craft-pilot-004',
          '909bde5e81e0a4dc6fc9ffabab1eda9cad804d13c7e0a8153f69ed4c2c643965',
        ),
        (
          'film-craft-20261013',
          'film-craft-pilot-001',
          '33cc65a230ea288796e495d51e9d9034894711005ba822bff3999326e2d8e444',
        ),
        (
          'film-craft-20261013',
          'film-craft-pilot-002',
          'e49bcb500592de3552b2bcb4042e345d341983228d2c3b9f52be0c0733aeb4c3',
        ),
        (
          'film-craft-20261013',
          'film-craft-pilot-003',
          'c6f5e00a14e3740db81cbaff646341193a24795d48fe01f7c84f2bc56d69e674',
        ),
        (
          'film-craft-20261013',
          'film-craft-pilot-004',
          '4e4261c14d3a5e4b4e5e81a07cb5a4ff7065020059ee11ff4041fe4af967f3f0',
        ),
        (
          'cinema-people-20261011',
          'cinema-people-023',
          'c53894526896b8cffe6777777cd8be05b3bf3b2213f7d0bec18c3561cff82b77',
        ),
        (
          'cinema-people-20261011',
          'cinema-people-024',
          '78398be43b68d4c34abcc6c5331546ab91b40b785e6902ef6d7cc23e513597cd',
        ),
        (
          'music-people-20261011',
          'music-people-023',
          'f1a31357b68a88404397480179c67134bca0360f5bbf7b93d714014ca366444c',
        ),
        (
          'music-people-20261011',
          'music-people-024',
          '3a911b0bc4a22b21800832398e4516da4e99001ddad8df40e3de4077e92f134e',
        ),
        (
          'cinema-people-20261011',
          'cinema-people-025',
          '292cbc7bc5b24c9c22e54ba0cd5a07f65f73de8790db7c840c0d4516d812b122',
        ),
        (
          'cinema-people-20261011',
          'cinema-people-026',
          '46033cc1863ef688ed8c9b800562440d9f84b6b0b2d1d6ba6512ee58734720d8',
        ),
        (
          'cinema-people-20261011',
          'cinema-people-027',
          '81b4ba41f106b1657417e46a573dce23d6a25bc81271e235123e4998a700fcbc',
        ),
        (
          'cinema-people-20261011',
          'cinema-people-028',
          'f4dc2f54d3a746ba95ab87199dc453973f397becdf7c3a137194474aecf3019e',
        ),
        (
          'music-people-20261011',
          'music-people-025',
          '0430dbb8d3cf0ae89e71f0ebbacaaeb9ed18a4065bc3a24c77a2b143e2580751',
        ),
        (
          'music-people-20261011',
          'music-people-026',
          'f1d81789ae26481eb1bee36cac824bb92b80ad2d26bb6c61a6a3a8dae2ba6345',
        ),
        (
          'music-people-20261011',
          'music-people-027',
          '89a853cf96189541e18bac0b5b0fb09dd670d7bf570faa7d772297044c875276',
        ),
        (
          'music-people-20261011',
          'music-people-028',
          'bf80338f46de0a08ce331d81228a97bd873af57c750dc7295d1163bc0b9d30d7',
        ),
        (
          'home-alone-1-part-1',
          'q-ha1-p1-1',
          'b0f0047c659e193d6790f6cc209cb1135650cab8f8a2f716fda3c20d0a6e787f',
        ),
        (
          'home-alone-1-part-1',
          'q-ha1-p1-2',
          '0c4a99cddbb490c34f4918bac8f7ed1588b50acbd1ed6378fc8212ed5bf6005d',
        ),
      ]) {
        expect(articles.forQuestion(quizId, questionId, revision), isNotNull);
      }
      // Older Git metadata hashes must not bind the published question articles.
      for (final (questionId, staleRevision) in [
        (
          'q-ha1-p1-1',
          '466089300173e855d67d300e59ab9fb945eeaf0a6c54b895b6ba28386470cca1',
        ),
        (
          'q-ha1-p1-2',
          'a2f7bedd9a016ccbb8d4f71cf34ec529b5700d5d7d521b389a0e0612ad8e8b76',
        ),
      ]) {
        expect(
          articles.forQuestion(
            'home-alone-1-part-1',
            questionId,
            staleRevision,
          ),
          isNull,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}
