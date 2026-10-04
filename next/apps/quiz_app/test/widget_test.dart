import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/main.dart';

void main() {
  for (final size in [const Size(390, 736), const Size(360, 640)]) {
    testWidgets('six phone answers are visible and tappable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = await _QuizTestServer.start();
      api.firstQuestion = {
        ..._questionJson(1),
        'stem':
            'Как называется аргентинский ритуал приготовления мяса на гриле?',
        'options': [
          for (final entry in [
            'Асадо',
            'Кебаб',
            'Барбекю',
            'Сате',
            'Шашлык',
            'Тандури',
          ].indexed)
            {'option_id': 'opt-${entry.$1 + 1}', 'text': entry.$2},
        ],
      };
      final client = QuizApiClient(baseUri: api.baseUri);
      client.dio.httpClientAdapter = _QuizTestAdapter(api);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizApiProvider.overrideWithValue(client),
            discoveryCatalogProvider.overrideWith(
              (ref) async => [
                CatalogPack(
                  'quiz-many',
                  'Гастрономический этикет',
                  '',
                  'Гастрономия',
                  20,
                ),
              ],
            ),
          ],
          child: const QuizApp(
            initialLocation: '/quiz/quiz-many',
            defaultLocale: Locale('ru'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
      for (final label in [
        'Асадо',
        'Кебаб',
        'Барбекю',
        'Сате',
        'Шашлык',
        'Тандури',
      ]) {
        expect(
          find.text(label).hitTestable(),
          findsOneWidget,
          reason: '$label is clipped',
        );
      }
      for (final label in [
        'Асадо',
        'Кебаб',
        'Барбекю',
        'Сате',
        'Шашлык',
        'Тандури',
      ]) {
        final control = find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first;
        final rect = tester.getRect(control);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.top, greaterThanOrEqualTo(viewport.top));
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
      }
      await tester.tap(find.text('Тандури'));
      await tester.pumpAndSettle();
      expect((api.answerBodies.single['answer'] as Map)['option_id'], 'opt-6');
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'long phone answers at large text scale remain reachable by scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final api = await _QuizTestServer.start();
      api.firstQuestion = {
        ..._questionJson(1),
        'stem':
            'Как называется аргентинский ритуал приготовления мяса на гриле?',
        'options': [
          for (var i = 1; i <= 6; i++)
            {
              'option_id': 'opt-$i',
              'text':
                  'Длинный вариант ответа номер $i с дополнительным пояснением',
            },
        ],
      };
      final client = QuizApiClient(baseUri: api.baseUri);
      client.dio.httpClientAdapter = _QuizTestAdapter(api);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizApiProvider.overrideWithValue(client)],
          child: const QuizApp(initialLocation: '/quiz/quiz-many'),
        ),
      );
      await tester.pumpAndSettle();
      final last = find.text(
        'Длинный вариант ответа номер 6 с дополнительным пояснением',
      );
      await tester.scrollUntilVisible(
        last,
        140,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(last), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect((api.answerBodies.single['answer'] as Map)['option_id'], 'opt-6');
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(1262, 576), const Size(390, 640)]) {
    testWidgets('library categories fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryCatalogProvider.overrideWith(
              (ref) async => [
                for (final category in [
                  'Гастрономия',
                  'Кино',
                  'Новый Год',
                  'Природа',
                  'Психология',
                  'Филии',
                  'Филология',
                ])
                  CatalogPack(category, category, 'Description', category, 20),
              ],
            ),
          ],
          child: const QuizApp(
            initialLocation: '/library',
            defaultLocale: Locale('ru'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SourceFolderCard), findsNWidgets(7));
      for (final card in find.byType(SourceFolderCard).evaluate()) {
        final rect = tester.getRect(find.byWidget(card.widget));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('library scrolls by dragging with a mouse', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryCatalogProvider.overrideWith(
            (ref) async => [
              for (var i = 0; i < 40; i++)
                CatalogPack(
                  'pack-$i',
                  'Quiz $i',
                  'Description',
                  'Folder $i',
                  20,
                ),
            ],
          ),
        ],
        child: const QuizApp(initialLocation: '/library'),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byType(ListView).first;
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.pixels, 0);
    await tester.drag(
      list,
      const Offset(0, -180),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(100));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'correct overlay advances in one second without shifting question',
    (tester) async {
      final api = await _QuizTestServer.start();
      final client = QuizApiClient(baseUri: api.baseUri);
      client.dio.httpClientAdapter = _QuizTestAdapter(api);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizApiProvider.overrideWithValue(client)],
          child: const QuizApp(initialLocation: '/quiz/quiz-many'),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byType(QuestionCard));
      await tester.tap(find.text('Option 4'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Because question 1.'), findsOneWidget);
      expect(tester.getRect(find.byType(QuestionCard)), before);
      expect(
        find.descendant(
          of: find.byType(QuestionCard),
          matching: find.text('Correct'),
        ),
        findsNothing,
      );
      // Dialog entrance has already elapsed during pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Question 1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.text('Question 2'), findsOneWidget);
      expect(api.answerBodies, hasLength(1));
    },
  );
  for (final size in [const Size(390, 640), const Size(1262, 576)]) {
    testWidgets('flag media keeps four choices stable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final url = 'https://quiz.kotopedia.org/flags/al-${size.width}.gif';
      final question = PublicQuestion.fromJson({
        ..._questionJson(1, flagMedia: true),
        'media': [
          {'uri': url, 'kind': 'image', 'alt': 'Флаг страны'},
        ],
      });
      final pending = Completer<ImageInfo>();
      final key = NetworkImage(url);
      PaintingBinding.instance.imageCache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(pending.future),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionCard(question: question, onAnswer: (_) {}),
        ),
      );
      final mediaBefore = tester.getRect(
        find.byKey(const Key('question-media')),
      );
      final choicesBefore = [
        for (var option = 1; option <= 4; option++)
          tester.getRect(find.text('Option $option')),
      ];
      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(const Key('question-media-error')), findsNothing);
      for (final bounds in choicesBefore) {
        expect(bounds.bottom, lessThanOrEqualTo(size.height));
      }

      pending.completeError(StateError('test image failure'));
      await tester.pump();
      expect(find.byKey(const Key('question-media-error')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('question-media'))),
        mediaBefore,
      );
      for (var option = 1; option <= 4; option++) {
        expect(
          tester.getRect(find.text('Option $option')),
          choicesBefore[option - 1],
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('auto advance can be paused, explained and resumed', (
    tester,
  ) async {
    final api = await _QuizTestServer.start();
    final client = QuizApiClient(baseUri: api.baseUri);
    client.dio.httpClientAdapter = _QuizTestAdapter(api);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizApiProvider.overrideWithValue(client)],
        child: const QuizApp(initialLocation: '/quiz/quiz-many'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auto-pause')));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Because question 1.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('auto-resume')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Question 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Question 2'), findsOneWidget);
  });

  testWidgets('practice tap checks once, feedback retry does not resubmit', (
    tester,
  ) async {
    final api = await _QuizTestServer.start(failFirstReveal: true);
    final client = QuizApiClient(baseUri: api.baseUri);
    client.dio.httpClientAdapter = _QuizTestAdapter(api);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizApiProvider.overrideWithValue(client)],
        child: const QuizApp(initialLocation: '/quiz/quiz-many'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option 1'));
    await tester.pumpAndSettle();
    expect(api.answerBodies, hasLength(1));
    expect(find.byKey(const Key('journey-error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(api.answerBodies, hasLength(1));
    expect(find.text('Incorrect'), findsWidgets);
    expect(find.text('Because question 1.'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const Key('auto-pause')), findsNothing);
    expect(find.text('Question 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feedback-next')));
    await tester.pumpAndSettle();
    expect(find.text('Question 2'), findsOneWidget);
    await tester.tap(find.text('Option 4'));
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsWidgets);
    expect(api.answerBodies, hasLength(2));
  });
  testWidgets('quiz controls fit a short phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = await _QuizTestServer.start();
    addTearDown(api.close);
    final client = QuizApiClient(
      baseUri: Uri.parse('https://api.example.test'),
    );
    client.dio.httpClientAdapter = _QuizTestAdapter(api);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizApiProvider.overrideWithValue(client)],
        child: const QuizApp(initialLocation: '/quiz/quiz-many'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsNothing);
    final before = tester.getRect(find.byType(QuestionCard));
    await tester.tap(find.text('Option 1'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.getRect(find.byType(QuestionCard)), before);
    expect(tester.getRect(find.byType(Dialog)).bottom, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'decoded flag media survives the shuffled quiz page and has stable failure UI',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = await _QuizTestServer.start(flagMedia: true);
      addTearDown(api.close);
      final client = QuizApiClient(baseUri: api.baseUri);
      client.dio.httpClientAdapter = _QuizTestAdapter(api);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizApiProvider.overrideWithValue(client)],
          child: const QuizApp(initialLocation: '/quiz/quiz-many'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('question-media')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Флаг страны',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('question-media-error')), findsOneWidget);
      for (var option = 1; option <= 4; option++) {
        final bounds = tester.getRect(find.text('Option $option'));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(640));
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('catalog selection uses a shareable quiz URL', (tester) async {
    final api = await _QuizTestServer.start();
    addTearDown(api.close);
    final client = QuizApiClient(
      baseUri: Uri.parse('https://api.example.test'),
    );
    client.dio.httpClientAdapter = _QuizTestAdapter(api);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizApiProvider.overrideWithValue(client),
          discoveryCatalogProvider.overrideWith(
            (ref) async => const [
              CatalogPack(
                'quiz-many',
                'Selected quiz',
                'Description',
                'General',
                25,
              ),
            ],
          ),
        ],
        child: const QuizApp(initialLocation: '/library'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pack-quiz-many')));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(CatalogPage)));
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/quiz/quiz-many',
    );
    expect(find.text('Display name'), findsNothing);
    expect(find.text('Question 1'), findsOneWidget);
  });
  testWidgets('selected quiz opens directly without asking for a name', (
    tester,
  ) async {
    final api = await _QuizTestServer.start();
    addTearDown(api.close);
    final client = QuizApiClient(
      baseUri: Uri.parse('https://api.example.test'),
    );
    final adapter = _QuizTestAdapter(api);
    client.dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizApiProvider.overrideWithValue(client)],
        child: const QuizApp(initialLocation: '/quiz/quiz-many'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Display name'), findsNothing);
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.textContaining('Unable'), findsNothing);
    expect(adapter.selectedCatalog, 'quiz-many');
    expect(adapter.selectedAttempt, 'quiz-many');
  });
  testWidgets(
    'real 25-question API journey finishes once and preserves result navigation',
    (tester) async {
      final api = await _QuizTestServer.start(failFirstReveal: true);
      addTearDown(api.close);
      await _pumpApiApp(tester, api);

      await tester.enterText(find.byType(TextField), ' Ada ');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('quiz-many'), findsOneWidget);
      expect(find.text('25 questions'), findsOneWidget);

      await tester.tap(find.text('Start quiz'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 25; index++) {
        expect(find.text('Question ${index + 1}'), findsOneWidget);
        expect(find.textContaining('Because question'), findsNothing);
        if (index == 0) {
          final visibleOptions = tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byType(QuestionCard),
                  matching: find.byType(Text),
                ),
              )
              .map((text) => text.data)
              .where((text) => text?.startsWith('Option ') ?? false)
              .toList();
          expect(visibleOptions, [
            'Option 4',
            'Option 3',
            'Option 2',
            'Option 1',
          ]);
        }
        await tester.tap(find.text('Option 4'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.tap(find.text('Continue'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(api.answerBodies, hasLength(index + 1));
        expect(find.byKey(const Key('journey-error')), findsNothing);
      }

      expect(api.answerBodies, hasLength(25));
      expect(
        api.answerBodies.map((body) => body['question_id']).toSet(),
        hasLength(25),
      );
      expect(
        api.answerBodies.every(
          (body) =>
              (body['answer'] as Map<String, dynamic>)['option_id'] == 'opt-4',
        ),
        isTrue,
      );

      await tester.tap(find.text('Finish quiz'));
      await tester.tap(find.text('Finish quiz'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(api.finishCount, 1);
      expect(find.text('Unable to load results.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(api.finishCount, 1);
      expect(api.revealCount, 2);
      expect(find.text('Score: 25'), findsOneWidget);
      expect(find.text('Because question 1.'), findsOneWidget);

      await tester.ensureVisible(find.text('History'));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Score: 25'), findsOneWidget);
      expect(api.historyCount, 1);
      await tester.tap(find.byTooltip('Русский'));
      await tester.tap(find.byTooltip('Dark theme'));
      await tester.pumpAndSettle();
      expect(find.text('История'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Счёт: 25'), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.ensureVisible(find.text('История'));
      await tester.tap(find.text('История'));
      await tester.pumpAndSettle();
      expect(api.historyCount, 2);
    },
  );

  testWidgets('catalog empty and retryable errors are localized in EN and RU', (
    tester,
  ) async {
    final api = await _QuizTestServer.start(
      failFirstCatalog: true,
      empty: true,
      holdFirstCatalog: true,
    );
    addTearDown(api.close);
    await _pumpApiApp(tester, api);

    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Loading…'), findsOneWidget);
    api.releaseCatalog();
    await tester.pumpAndSettle();
    expect(api.catalogCount, 1);
    expect(find.text('Unable to load quizzes.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить викторины.'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Доступных викторин пока нет.'), findsOneWidget);
    expect(api.catalogCount, 2);
  });

  testWidgets('history error retry resolves to localized empty state', (
    tester,
  ) async {
    final api = await _QuizTestServer.start(
      empty: true,
      failFirstHistory: true,
    );
    addTearDown(api.close);
    await _pumpApiApp(tester, api);
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load history.'), findsOneWidget);
    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить историю.'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Завершённых викторин пока нет'), findsOneWidget);
  });

  testWidgets('shows the localized quiz catalog home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));

    expect(find.text('Quiz catalog'), findsOneWidget);
  });

  testWidgets('switches catalog labels between English and Russian', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));

    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Каталог викторин'), findsOneWidget);

    await tester.tap(find.byTooltip('English'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz catalog'), findsOneWidget);
  });

  testWidgets('offers light dark and system theme controls', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));

    await tester.tap(find.byTooltip('Light theme'));
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.byTooltip('System theme'));
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('gallery route and history survive locale and theme changes', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));
    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;

    await tester.tap(find.text('Open gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Public fixture gallery'), findsOneWidget);

    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Галерея публичных примеров'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    expect(find.text('Галерея публичных примеров'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      same(router),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Каталог викторин'), findsOneWidget);
  });

  testWidgets('deep links show join admission boundary and back returns home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuizApp(
          initialLocation: '/join/0123456789abcdef0123456789abcdef',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('admission-only'), findsOneWidget);

    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('0123456789abcdef0123456789abcdef'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.light_mode));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('0123456789abcdef0123456789abcdef'),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Каталог викторин'), findsOneWidget);
  });
}

Future<void> _pumpApiApp(WidgetTester tester, _QuizTestServer api) {
  final client = QuizApiClient(baseUri: api.baseUri);
  client.dio.httpClientAdapter = _QuizTestAdapter(api);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [quizApiProvider.overrideWithValue(client)],
      child: const QuizApp(),
    ),
  );
}

class _QuizTestServer {
  _QuizTestServer._({
    required this.failFirstCatalog,
    required this.failFirstReveal,
    required this.failFirstHistory,
    required this.empty,
    required bool holdFirstCatalog,
  }) : _catalogGate = holdFirstCatalog ? Completer<void>() : null;

  final bool failFirstCatalog;
  final bool failFirstReveal;
  final bool failFirstHistory;
  final bool empty;
  final Completer<void>? _catalogGate;
  final answerBodies = <Map<String, dynamic>>[];
  var catalogCount = 0;
  var finishCount = 0;
  var revealCount = 0;
  var historyCount = 0;
  var feedbackCount = 0;
  var flagMedia = false;
  Map<String, Object>? firstQuestion;

  static Future<_QuizTestServer> start({
    bool failFirstCatalog = false,
    bool failFirstReveal = false,
    bool failFirstHistory = false,
    bool empty = false,
    bool holdFirstCatalog = false,
    bool flagMedia = false,
  }) async => _QuizTestServer._(
    failFirstCatalog: failFirstCatalog,
    failFirstReveal: failFirstReveal,
    failFirstHistory: failFirstHistory,
    empty: empty,
    holdFirstCatalog: holdFirstCatalog,
  )..flagMedia = flagMedia;

  Uri get baseUri => Uri.parse('https://quiz.test');

  Future<void> close() async {}

  void releaseCatalog() => _catalogGate?.complete();

  (int, Object) respond(String method, String path, Object? data) {
    Object response;
    var status = 200;
    if (method == 'POST' && path == '/v1/guests') {
      status = 201;
      response = _guestJson;
    } else if (method == 'GET' && path == '/v1/catalog') {
      catalogCount++;
      if (failFirstCatalog && catalogCount == 1) {
        status = 503;
        response = _retryableError;
      } else {
        response = _catalogJson(empty: empty, flagMedia: flagMedia);
        if (firstQuestion != null) {
          ((response as Map)['quiz']['questions'] as List)[0] = firstQuestion;
        }
      }
    } else if (method == 'POST' && path == '/v1/attempts') {
      status = 201;
      response = _attemptJson;
      if (firstQuestion != null) {
        final ids = (firstQuestion!['options'] as List)
            .map((o) => (o as Map)['option_id'])
            .toList();
        response = {
          ..._attemptJson,
          'question_snapshots': [
            {
              ...(_attemptJson['question_snapshots'] as List).first as Map,
              'option_order': ids,
              'position_to_option_id': {
                for (final entry in ids.indexed) '${entry.$1}': entry.$2,
              },
            },
            ...(_attemptJson['question_snapshots'] as List).skip(1),
          ],
        };
      }
    } else if (method == 'POST' && path.endsWith('/answers')) {
      final body = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : Map<String, dynamic>.from(data! as Map);
      answerBodies.add(body);
      final questionId = body['question_id'] as String;
      final index = int.parse(questionId.substring(2));
      response = _receiptJson(index);
    } else if (method == 'POST' && path.endsWith('/finish')) {
      finishCount++;
      response = _finishJson;
    } else if (method == 'GET' && path.contains('/feedback/')) {
      feedbackCount++;
      final id = path.split('/').last;
      final index = int.parse(id.substring(2));
      if (failFirstReveal && feedbackCount == 1) {
        status = 503;
        response = _retryableError;
      } else {
        response = {
          'correct':
              (answerBodies.last['answer'] as Map)['option_id'] == 'opt-4',
          'reveal': _revealsJson[index - 1],
        };
      }
    } else if (method == 'GET' && path.endsWith('/reveals')) {
      revealCount++;
      if (failFirstReveal && revealCount == 1) {
        status = 503;
        response = _retryableError;
      } else {
        response = _revealsJson;
      }
    } else if (method == 'GET' && path == '/v1/history') {
      historyCount++;
      if (failFirstHistory && historyCount == 1) {
        status = 503;
        response = _retryableError;
      } else {
        response = empty ? <Object>[] : [_finishJson];
      }
    } else {
      status = 404;
      response = _retryableError;
    }
    return (status, response);
  }
}

class _QuizTestAdapter implements HttpClientAdapter {
  _QuizTestAdapter(this.api);
  final _QuizTestServer api;
  String? selectedCatalog, selectedAttempt;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path == '/v1/catalog') {
      selectedCatalog = options.uri.queryParameters['quiz_id'];
    }
    if (options.uri.path == '/v1/attempts') {
      selectedAttempt = (options.data as Map)['quiz_id'] as String?;
    }
    final catalogGate = api._catalogGate;
    if (options.uri.path == '/v1/catalog' &&
        catalogGate != null &&
        !catalogGate.isCompleted) {
      await catalogGate.future;
    }
    final result = api.respond(options.method, options.uri.path, options.data);
    return ResponseBody.fromString(
      jsonEncode(result.$2),
      result.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _participantId = 'p-0123456789abcdef0123456789abcdef';
final _guestJson = <String, Object>{
  'participant_id': _participantId,
  'kind': 'guest',
  'display_name': 'Ada',
  'token': 'opaque-test-token',
  'expires_at': '2026-09-20T10:00:00Z',
};
const _retryableError = <String, Object>{
  'code': 'deadline_exceeded',
  'message': 'not rendered',
  'retryable': true,
  'details': <String, String>{},
};

Map<String, Object> _catalogJson({
  required bool empty,
  bool flagMedia = false,
}) => {
  'bundle_version': 'v25',
  'bundle_sha256': 'a' * 64,
  'quiz': {
    'quiz_id': 'quiz-many',
    'revision': {'number': 1, 'sha256': 'b' * 64},
    'locale': 'en',
    'questions': empty
        ? <Object>[]
        : [
            for (var index = 1; index <= 25; index++)
              _questionJson(index, flagMedia: flagMedia && index == 1),
          ],
  },
};

Map<String, Object> _questionJson(int index, {bool flagMedia = false}) => {
  'quiz_id': 'quiz-many',
  'question_id': 'q-${index.toString().padLeft(3, '0')}',
  'revision': {'number': index, 'sha256': '${index % 10}' * 64},
  'stem': 'Question $index',
  'options': [
    for (var option = 1; option <= 4; option++)
      {'option_id': 'opt-$option', 'text': 'Option $option'},
  ],
  'difficulty': 'easy',
  'source': {'uri': 'https://example.test/$index'},
  if (flagMedia)
    'media': [
      {
        'uri': 'https://quiz.kotopedia.org/flags/al.gif',
        'kind': 'image',
        'alt': 'Флаг страны',
      },
    ],
  'answer_kind': 'single_choice',
};

final _attemptJson = <String, Object>{
  'attempt_id': 'attempt-many',
  'participant_id': _participantId,
  'bundle_version': 'v25',
  'bundle_sha256': 'a' * 64,
  'scoring_policy_version': 'scoring/v1',
  'status': 'started',
  'question_snapshots': [
    for (var index = 1; index <= 25; index++)
      {
        'question_id': 'q-${index.toString().padLeft(3, '0')}',
        'question_revision': {'number': index, 'sha256': '${index % 10}' * 64},
        'option_order': ['opt-4', 'opt-3', 'opt-2', 'opt-1'],
        'position_to_option_id': {
          '0': 'opt-4',
          '1': 'opt-3',
          '2': 'opt-2',
          '3': 'opt-1',
        },
      },
  ],
};

Map<String, Object> _receiptJson(int index) => {
  'receipt_id': 'receipt-${index.toString().padLeft(3, '0')}',
  'attempt_id': 'attempt-many',
  'participant_id': _participantId,
  'question_id': 'q-${index.toString().padLeft(3, '0')}',
  'question_revision': {'number': index, 'sha256': '${index % 10}' * 64},
  'accepted_at': '2026-09-20T10:00:${index.toString().padLeft(2, '0')}Z',
};

final _finishJson = <String, Object>{
  'attempt_id': 'attempt-many',
  'participant_id': _participantId,
  'status': 'finished',
  'finished_at': '2026-09-20T10:01:00Z',
  'server_score': 25,
  'history': [
    for (var index = 1; index <= 25; index++)
      {
        'question_id': 'q-${index.toString().padLeft(3, '0')}',
        'question_revision': {'number': index, 'sha256': '${index % 10}' * 64},
        'receipt_id': 'receipt-${index.toString().padLeft(3, '0')}',
      },
  ],
};

final _revealsJson = <Map<String, Object>>[
  for (var index = 1; index <= 25; index++)
    {
      'quiz_id': 'quiz-many',
      'question_id': 'q-${index.toString().padLeft(3, '0')}',
      'question_revision': {'number': index, 'sha256': '${index % 10}' * 64},
      'correct_answer': {'option_id': 'opt-4', 'text': 'Option 4'},
      'explanation': 'Because question $index.',
    },
];
