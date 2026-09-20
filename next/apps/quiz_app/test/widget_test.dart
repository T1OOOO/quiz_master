import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';

void main() {
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

  static Future<_QuizTestServer> start({
    bool failFirstCatalog = false,
    bool failFirstReveal = false,
    bool failFirstHistory = false,
    bool empty = false,
    bool holdFirstCatalog = false,
  }) async => _QuizTestServer._(
    failFirstCatalog: failFirstCatalog,
    failFirstReveal: failFirstReveal,
    failFirstHistory: failFirstHistory,
    empty: empty,
    holdFirstCatalog: holdFirstCatalog,
  );

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
        response = _catalogJson(empty: empty);
      }
    } else if (method == 'POST' && path == '/v1/attempts') {
      status = 201;
      response = _attemptJson;
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

Map<String, Object> _catalogJson({required bool empty}) => {
  'bundle_version': 'v25',
  'bundle_sha256': 'a' * 64,
  'quiz': {
    'quiz_id': 'quiz-many',
    'revision': {'number': 1, 'sha256': 'b' * 64},
    'locale': 'en',
    'questions': empty
        ? <Object>[]
        : [for (var index = 1; index <= 25; index++) _questionJson(index)],
  },
};

Map<String, Object> _questionJson(int index) => {
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
