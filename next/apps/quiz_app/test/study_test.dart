import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/l10n/app_localizations.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('study card uses its own illustrated cover', (tester) async {
    await _pump(tester, const StudyLibraryPage());
    final image = tester.widget<Image>(find.byType(Image).last);
    expect(
      (image.image as ResizeImage).imageProvider,
      const AssetImage('assets/study/history-hero.png'),
    );
  });
  testWidgets('feedback blocks background answers and focuses pause', (
    tester,
  ) async {
    await _pump(tester, const StudyPracticePage(moduleId: 'history'));
    await tester.tap(find.text('Choice C').first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<QuestionCard>(find.byType(QuestionCard)).submitting,
      isTrue,
    );
    expect(find.byKey(const Key('study-feedback-barrier')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Reason from the source.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1 / 20'), findsOneWidget);
  });

  testWidgets('backgrounding pauses the correct-answer timer', (tester) async {
    await _pump(tester, const StudyPracticePage(moduleId: 'history'));
    await tester.tap(find.text('Choice C').first);
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('1 / 20'), findsOneWidget);
    expect(find.text('Reason from the source.'), findsOneWidget);
  });

  testWidgets('catalog refresh pauses feedback until manual continuation', (
    tester,
  ) async {
    await _pump(tester, const StudyPracticePage(moduleId: 'history'));
    await tester.tap(find.text('Choice C').first);
    await tester.pump(const Duration(milliseconds: 100));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StudyPracticePage)),
    );
    container.invalidate(studyModulesProvider);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('1 / 20'), findsOneWidget);
    expect(find.text('Reason from the source.'), findsOneWidget);
  });

  testWidgets(
    'bundled library loads six real chapters and 120 sourced questions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final modules = await tester.runAsync(
        () => container.read(studyModulesProvider.future),
      );
      expect(modules, hasLength(6));
      expect(modules!.map((module) => module.id).toSet(), {
        'nature',
        'geography-countries',
        'history',
        'greek-mythology',
        'nature-evolution',
        'geography-maps',
      });
      for (final module in modules) {
        expect(module.questions, hasLength(20));
        expect(module.articleMarkdown, contains('resource:assets/study/'));
        expect(
          module.questions.every(
            (q) =>
                q.correctAnswer >= 0 &&
                q.correctAnswer < q.options.length &&
                q.sourceRefs.isNotEmpty,
          ),
          isTrue,
        );
        final image = await tester.runAsync(
          () => rootBundle.load('assets/study/${module.id}-hero.png'),
        );
        expect(image!.lengthInBytes, greaterThan(0));
      }
    },
  );

  testWidgets(
    'twenty answers finish once with exact score and retry resets state',
    (tester) async {
      await _pump(tester, const StudyPracticePage(moduleId: 'history'));
      final answered = <String>{};
      for (var i = 0; i < 20; i++) {
        expect(answered.add(_currentQuestion(tester)), isTrue);
        final card = tester.widget<QuestionCard>(find.byType(QuestionCard));
        final correctId = card.question.options
            .singleWhere((option) => option.text == 'Choice C')
            .id;
        card.onAnswer(correctId);
        card.onAnswer(correctId);
        await tester.pump();
        await tester.tap(find.byKey(const Key('study-continue')));
        await tester.pump();
      }
      expect(find.text('Self-check complete\n20 of 20'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('1 / 20'), findsOneWidget);
      expect(find.byKey(const Key('study-feedback-overlay')), findsNothing);
    },
  );

  testWidgets(
    'study deep link has article back navigation and shared home menu',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studyModulesProvider.overrideWith((ref) async => [moduleFixture]),
            _quizCatalogOverride,
          ],
          child: const QuizApp(
            initialLocation: '/study/history/practice',
            defaultLocale: Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-back')));
      await tester.pumpAndSettle();
      expect(find.byType(StudyArticlePage), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-back')));
      await tester.pumpAndSettle();
      expect(find.byType(StudyLibraryPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoveryPage), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Study library'));
      await tester.pumpAndSettle();
      expect(find.byType(StudyLibraryPage), findsOneWidget);
    },
  );
  testWidgets('article prose uses dark ink on parchment surfaces', (
    tester,
  ) async {
    await _pump(tester, const StudyArticlePage(moduleId: 'history'));
    final context = tester.element(find.text('A short lesson'));
    expect(DefaultTextStyle.of(context).style.color, const Color(0xff3f2f23));
    final heading = tester.widget<Text>(find.text(moduleFixture.title).first);
    expect(heading.style!.color, const Color(0xff655444));
  });
  testWidgets(
    'correct choice uses stable option ID and advances after one second',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await _pump(tester, const StudyPracticePage(moduleId: 'history'));
      expect(find.text('1 / 20'), findsOneWidget);
      final firstQuestion = _currentQuestion(tester);
      await tester.tap(find.text('Choice C').first);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('study-feedback-overlay')), findsOneWidget);
      expect(find.text('Reason from the source.'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(_currentQuestion(tester), isNot(firstQuestion));
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'pause reveals source-backed explanation and prevents timed advance',
    (tester) async {
      await _pump(tester, const StudyPracticePage(moduleId: 'history'));
      final firstQuestion = _currentQuestion(tester);
      await tester.tap(find.text('Choice C').first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('study-pause')));
      await tester.pump();
      expect(find.text('Reason from the source.'), findsOneWidget);
      expect(find.text('A primary source'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(_currentQuestion(tester), firstQuestion);
    },
  );

  testWidgets(
    'wrong answer shows centered explanation and waits for manual continue',
    (tester) async {
      await _pump(tester, const StudyPracticePage(moduleId: 'history'));
      final firstQuestion = _currentQuestion(tester);
      await tester.tap(find.text('Choice A').first);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('study-feedback-overlay')), findsOneWidget);
      expect(find.text('Reason from the source.'), findsOneWidget);
      expect(find.byKey(const Key('study-continue')), findsOneWidget);
      expect(_currentQuestion(tester), firstQuestion);
      await tester.tap(find.byKey(const Key('study-continue')));
      await tester.pump();
      expect(_currentQuestion(tester), isNot(firstQuestion));
    },
  );

  testWidgets('repeated taps cannot score the same question twice', (
    tester,
  ) async {
    await _pump(tester, const StudyPracticePage(moduleId: 'history'));
    await tester.tap(find.text('Choice C').first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Choice A').first, warnIfMissed: false);
    await tester.pump();
    expect(find.byKey(const Key('study-feedback-overlay')), findsOneWidget);
  });

  testWidgets(
    'article shows contents, readable quiz title, sources and handles missing image',
    (tester) async {
      await _pump(tester, const StudyArticlePage(moduleId: 'history'));
      expect(find.byKey(const Key('study-contents')), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(find.text('A primary source'), findsOneWidget);
      expect(find.text('World History'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('article keeps paper text and tables readable in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(361, 682);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(361, 682));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyModulesProvider.overrideWith((ref) async => [moduleFixture]),
          _quizCatalogOverride,
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const StudyArticlePage(moduleId: 'history'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final markdown = tester.widget<MarkdownBody>(
      find.byType(MarkdownBody).first,
    );
    final style = markdown.styleSheet!;
    expect(style.p!.color, const Color(0xff3f2f23));
    expect(style.a!.color, const Color(0xff005f52));
    expect(style.tableBody!.color, const Color(0xff3f2f23));
    final paper = tester.widget<Card>(find.byType(Card).first).color!;
    final contrast =
        (paper.computeLuminance() + .05) /
        (style.p!.color!.computeLuminance() + .05);
    expect(contrast, greaterThan(4.5));
    expect(find.byKey(const Key('study-mobile-table')), findsOneWidget);
    expect(find.text('Heading'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(
      find.text(
        'A longer detail that remains visible in a labeled card on a narrow screen.',
      ),
      findsOneWidget,
    );
    expect(find.byType(Table), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article keeps its Markdown table on desktop widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 682));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(tester, const StudyArticlePage(moduleId: 'history'));

    expect(find.byKey(const Key('study-mobile-table')), findsNothing);
    expect(find.byType(Table), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile table cards preserve escaped pipes and backslashes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(361, 682);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(361, 682));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpStudyArticle(
      tester,
      _moduleWithMarkdown(
        '# Lesson\n\n| Label | Detail |\n|---|---|\n| Path | C:\\path \\| before |',
      ),
    );

    expect(find.byKey(const Key('study-mobile-table')), findsOneWidget);
    expect(find.text('C:\\path | before'), findsOneWidget);
  });

  testWidgets('mobile leaves fenced and formatted tables to Markdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(361, 682);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(361, 682));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpStudyArticle(
      tester,
      _moduleWithMarkdown(
        '# Lesson\n\n```text\n| Header | Detail |\n|---|---|\n| A | B |\n```\n\n| Header | Detail |\n|---|---|\n| <em>A</em> | ~~B~~ |',
      ),
    );

    expect(find.byKey(const Key('study-mobile-table')), findsNothing);
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets(
    'library cards avoid overflow on narrow screens at large text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studyModulesProvider.overrideWith((ref) async => [moduleFixture]),
            _quizCatalogOverride,
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const StudyLibraryPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studyModulesProvider.overrideWith((ref) async => [moduleFixture]),
        _quizCatalogOverride,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpStudyArticle(WidgetTester tester, StudyModule module) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studyModulesProvider.overrideWith((ref) async => [module]),
        _quizCatalogOverride,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const StudyArticlePage(moduleId: 'history'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _quizCatalogOverride = discoveryCatalogProvider.overrideWith(
  (ref) async => [
    const CatalogPack(
      'history-quiz',
      'World History',
      'A history pack',
      'History',
      20,
    ),
  ],
);

String _currentQuestion(WidgetTester tester) =>
    tester.widget<QuestionCard>(find.byType(QuestionCard)).question.id;

final moduleFixture = StudyModule(
  id: 'history',
  title: 'History',
  description: 'A short lesson',
  category: 'History',
  readingMinutesEstimate: 3,
  articleMarkdown: '# A lesson\n\nA paragraph.\n\n![Missing illustration](resource:assets/study/does-not-exist.png)\n\n| Heading | Detail |\n|---|---|\n| One | A longer detail that remains visible in a labeled card on a narrow screen. |\n\n## Sources\n\nA sourced section.',
  objectives: const ['Learn one thing'],
  sourceQuizIds: const ['history-quiz'],
  sources: const [
    StudySource(
      id: 'src',
      title: 'A primary source',
      url: 'https://example.org',
    ),
  ],
  questions: [
    for (var i = 0; i < 20; i++)
      StudyQuestion(
        id: 'q-${i.toString().padLeft(2, '0')}',
        text: 'Question $i: which choice is correct?',
        options: const ['Choice A', 'Choice B', 'Choice C', 'Choice D'],
        correctAnswer: 2,
        explanation: 'Reason from the source.',
        sourceRefs: const ['src'],
      ),
  ],
);

StudyModule _moduleWithMarkdown(String articleMarkdown) => StudyModule(
  id: moduleFixture.id,
  title: moduleFixture.title,
  description: moduleFixture.description,
  category: moduleFixture.category,
  readingMinutesEstimate: moduleFixture.readingMinutesEstimate,
  articleMarkdown: articleMarkdown,
  objectives: moduleFixture.objectives,
  sourceQuizIds: moduleFixture.sourceQuizIds,
  sources: moduleFixture.sources,
  questions: moduleFixture.questions,
);
