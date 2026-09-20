import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  test('plain HTTP base URLs are restricted to loopback hosts', () {
    for (final allowed in [
      'https://api.example.test',
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://127.42.8.9:8080',
      'http://[::1]:8080',
    ]) {
      expect(
        () => QuizApiClient(baseUri: Uri.parse(allowed)),
        returnsNormally,
        reason: allowed,
      );
    }
    for (final rejected in [
      'http://api.example.test',
      'http://192.168.1.20:8080',
      'http://localhost.example.test',
    ]) {
      expect(
        () => QuizApiClient(baseUri: Uri.parse(rejected)),
        throwsArgumentError,
        reason: rejected,
      );
    }
  });

  test('typed staged answers serialize to the exact public wire shape', () {
    expect(
      StagedAnswer.fromInput(AnswerKind.singleChoice, 'opt-one').toJson(),
      {'option_id': 'opt-one'},
    );
    expect(
      StagedAnswer.fromInput(AnswerKind.multipleChoice, {
        'opt-three',
        'opt-one',
      }).toJson(),
      {
        'option_ids': ['opt-one', 'opt-three'],
      },
    );
    expect(StagedAnswer.fromInput(AnswerKind.normalizedText, 'mars').toJson(), {
      'text': 'mars',
    });
  });

  test('valid empty catalog remains a displayable catalog state', () {
    final catalog = Catalog.fromJson({
      'bundle_version': 'v1',
      'bundle_sha256': 'a' * 64,
      'quiz': {
        'quiz_id': 'quiz-one',
        'revision': {'number': 1, 'sha256': 'c' * 64},
        'locale': 'en',
        'questions': <Object>[],
      },
    });
    expect(catalog.quiz.questions, isEmpty);
  });

  test('security timestamps require complete UTC RFC3339 instants', () {
    for (final invalid in [
      '2026-09-20',
      '2026-09-20T10:00:00',
      '2026-09-20T13:00:00+03:00',
    ]) {
      expect(
        () => GuestSession.fromJson({...guestJson, 'expires_at': invalid}),
        throwsFormatException,
      );
      expect(
        () => Receipt.fromJson({...receiptJson, 'accepted_at': invalid}),
        throwsFormatException,
      );
      expect(
        () => Finish.fromJson({...finishJson, 'finished_at': invalid}),
        throwsFormatException,
      );
    }
  });

  test('attempt snapshots must exactly match catalog questions and option permutations', () {
    final catalog = Catalog.fromJson({
      'bundle_version': 'v1',
      'bundle_sha256': 'a' * 64,
      'quiz': {
        'quiz_id': 'quiz-one',
        'revision': {'number': 1, 'sha256': 'c' * 64},
        'locale': 'en',
        'questions': [questionJson],
      },
    });
    expect(
      () => validateAttemptCatalog(Attempt.fromJson(attemptJson), catalog),
      returnsNormally,
    );
    final wrong = Map<String, dynamic>.from(attemptJson)
      ..['bundle_sha256'] = 'd' * 64;
    expect(
      () => validateAttemptCatalog(Attempt.fromJson(wrong), catalog),
      throwsFormatException,
    );

    Map<String, dynamic> changedSnapshot(
      void Function(Map<String, dynamic>) change,
    ) {
      final value = jsonDecode(jsonEncode(attemptJson)) as Map<String, dynamic>;
      change(
        (value['question_snapshots'] as List).single as Map<String, dynamic>,
      );
      return value;
    }

    final staleRevision = changedSnapshot((snapshot) {
      snapshot['question_revision'] = {'number': 2, 'sha256': 'b' * 64};
    });
    expect(
      () => validateAttemptCatalog(Attempt.fromJson(staleRevision), catalog),
      throwsFormatException,
    );

    final unknownOption = changedSnapshot((snapshot) {
      snapshot['option_order'] = [
        'opt-one',
        'opt-two',
        'opt-three',
        'opt-unknown',
      ];
      snapshot['position_to_option_id'] = {
        '0': 'opt-one',
        '1': 'opt-two',
        '2': 'opt-three',
        '3': 'opt-unknown',
      };
    });
    expect(
      () => validateAttemptCatalog(Attempt.fromJson(unknownOption), catalog),
      throwsFormatException,
    );

    for (final invalidOrder in [
      ['opt-one', 'opt-two', 'opt-three'],
      ['opt-one', 'opt-one', 'opt-three', 'opt-four'],
    ]) {
      final invalid = changedSnapshot((snapshot) {
        snapshot['option_order'] = invalidOrder;
      });
      expect(() => Attempt.fromJson(invalid), throwsFormatException);
    }
  });

  test('finish history must exactly match accepted receipts and revisions', () {
    final finish = Finish.fromJson(finishJson);
    final receipt = Receipt.fromJson(receiptJson);
    expect(() => validateFinishReceipts(finish, [receipt]), returnsNormally);
    expect(
      () => validateFinishReceipts(finish, const []),
      throwsFormatException,
    );
    expect(
      () => validateFinishReceipts(finish, [
        Receipt.fromJson({...receiptJson, 'receipt_id': 'receipt-other'}),
      ]),
      throwsFormatException,
    );
    expect(
      () => validateFinishReceipts(finish, [
        Receipt.fromJson({
          ...receiptJson,
          'question_revision': {'number': 2, 'sha256': 'b' * 64},
        }),
      ]),
      throwsFormatException,
    );
  });

  test('reveals exactly match ordered finish history and expected quiz', () {
    final attempt = Attempt.fromJson(twoQuestionAttemptJson);
    final finish = Finish.fromJson(twoQuestionFinishJson);
    final first = Reveal.fromJson(revealJson);
    final second = Reveal.fromJson({
      ...revealJson,
      'question_id': 'q-two',
      'question_revision': {'number': 2, 'sha256': 'c' * 64},
    });

    void expectRejected(List<Reveal> reveals) {
      expect(
        () => validateReveals(
          attempt: attempt,
          finish: finish,
          expectedQuizId: 'quiz-one',
          reveals: reveals,
        ),
        throwsFormatException,
      );
    }

    expect(
      () => validateReveals(
        attempt: attempt,
        finish: finish,
        expectedQuizId: 'quiz-one',
        reveals: [first, second],
      ),
      returnsNormally,
    );
    expectRejected([first, first]);
    expectRejected([
      Reveal.fromJson({...revealJson, 'quiz_id': 'quiz-two'}),
      second,
    ]);
    expectRejected([second, first]);
    expectRejected([first]);
    expectRejected([
      Reveal.fromJson({
        ...revealJson,
        'question_revision': {'number': 2, 'sha256': 'b' * 64},
      }),
      second,
    ]);
  });

  test(
    'client rejects duplicate wrong-quiz swapped and missing reveals',
    () async {
      final second = {
        ...revealJson,
        'question_id': 'q-two',
        'question_revision': {'number': 2, 'sha256': 'c' * 64},
      };
      final invalidPayloads = <List<Map<String, dynamic>>>[
        [revealJson, revealJson],
        [
          {...revealJson, 'quiz_id': 'quiz-two'},
          second,
        ],
        [second, revealJson],
        [revealJson],
      ];

      for (final payload in invalidPayloads) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        final requests = StreamIterator(server);
        addTearDown(requests.cancel);
        final client = QuizApiClient(
          baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
        );
        final boot = client.bootstrap('Ada');
        await requests.moveNext();
        requests.current.response
          ..statusCode = 201
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(guestJson));
        await requests.current.response.close();
        await boot;

        final pending = client.reveals(
          Attempt.fromJson(twoQuestionAttemptJson),
          Finish.fromJson(twoQuestionFinishJson),
          expectedQuizId: 'quiz-one',
        );
        final rejected = expectLater(pending, throwsFormatException);
        await requests.moveNext();
        requests.current.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(payload));
        await requests.current.response.close();
        await rejected;
      }
    },
  );

  test(
    'answer digest is canonical and does not contain server-only fields',
    () {
      expect(
        answerPayloadDigest(
          attemptId: 'attempt-001',
          participantId: 'participant-001',
          questionId: 'q-sun',
          revision: const Revision(
            1,
            '2222222222222222222222222222222222222222222222222222222222222222',
          ),
          answer: const {'option_id': 'opt-sun'},
        ),
        'f752ca5613ca69ee6ac0e7717f398a8b22389c6d56503b994d9b882ec4ba7957',
      );
    },
  );

  test(
    'guest bootstrap is closed and never adds bearer to the guest request',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final request = server.first;
      final pending = QuizApiClient(
        baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
      ).bootstrap(' Ada ');
      final received = await request;
      expect(received.headers.value(HttpHeaders.authorizationHeader), isNull);
      expect(
        await utf8.decoder.bind(received).join(),
        '{"display_name":"Ada"}',
      );
      received.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'participant_id': 'p-0123456789abcdef0123456789abcdef',
            'kind': 'guest',
            'display_name': 'Ada',
            'token': 'opaque-token',
            'expires_at': '2026-09-20T10:00:00Z',
          }),
        );
      await received.response.close();
      final session = await pending;
      expect(session.participantId, 'p-0123456789abcdef0123456789abcdef');
    },
  );

  test(
    'catalog is public and rejects a secret-bearing quiz response',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final request = server.first;
      final pending = QuizApiClient(
        baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
      ).catalog();
      final received = await request;
      expect(received.method, 'GET');
      expect(received.headers.value(HttpHeaders.authorizationHeader), isNull);
      received.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'bundle_version': 'v1',
            'bundle_sha256': 'a' * 64,
            'quiz': {
              'quiz_id': 'quiz-one',
              'revision': {'number': 1, 'sha256': 'b' * 64},
              'locale': 'en',
              'questions': [],
              'grading': {'q-one': 'opt-one'},
            },
          }),
        );
      await received.response.close();
      await expectLater(pending, throwsFormatException);
    },
  );

  test(
    'authenticated attempt writes use pinned revision digest and bearer',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final client = QuizApiClient(
        baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
      );
      final requests = StreamIterator(server);
      addTearDown(requests.cancel);
      final bootstrap = client.bootstrap('Ada');
      await requests.moveNext();
      final guest = requests.current;
      guest.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(guestJson));
      await guest.response.close();
      await bootstrap;
      final startPending = client.startAttempt();
      await requests.moveNext();
      final start = requests.current;
      expect(
        start.headers.value(HttpHeaders.authorizationHeader),
        'Bearer opaque-token',
      );
      expect(await utf8.decoder.bind(start).join(), '{}');
      start.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(attemptJson));
      await start.response.close();
      final attempt = await startPending;
      final submitPending = client.submitAnswer(
        attempt,
        attempt.snapshots.single,
        const SingleChoiceAnswer('opt-one'),
        idempotencyKey: 'answer-key',
      );
      await requests.moveNext();
      final answer = requests.current;
      final body = jsonDecode(
        await utf8.decoder.bind(answer).join(),
      ) as Map<String, dynamic>;
      expect(
        answer.headers.value(HttpHeaders.authorizationHeader),
        'Bearer opaque-token',
      );
      expect(body['question_id'], 'q-one');
      expect(
        body['payload_digest'],
        answerPayloadDigest(
          attemptId: 'attempt-one',
          participantId: attempt.participantId,
          questionId: 'q-one',
          revision: attempt.snapshots.single.revision,
          answer: const {'option_id': 'opt-one'},
        ),
      );
      answer.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(receiptJson));
      await answer.response.close();
      expect((await submitPending).id, 'receipt-one');
    },
  );

  test(
    'single multi and text answers reach the wire with exact typed bodies',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final client = QuizApiClient(
        baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
      );
      final requests = StreamIterator(server);
      addTearDown(requests.cancel);
      final boot = client.bootstrap('Ada');
      await requests.moveNext();
      requests.current.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(guestJson));
      await requests.current.response.close();
      await boot;

      final attempt = Attempt.fromJson(typedAttemptJson);
      final cases = <(StagedAnswer, Map<String, Object>)>[
        (const SingleChoiceAnswer('opt-one'), {'option_id': 'opt-one'}),
        (
          MultipleChoiceAnswer({'opt-three', 'opt-one'}),
          {
            'option_ids': ['opt-one', 'opt-three'],
          },
        ),
        (const NormalizedTextAnswer('mars'), {'text': 'mars'}),
      ];
      for (var index = 0; index < cases.length; index++) {
        final pending = client.submitAnswer(
          attempt,
          attempt.snapshots[index],
          cases[index].$1,
          idempotencyKey: 'answer-key-$index',
        );
        await requests.moveNext();
        final request = requests.current;
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer opaque-token',
        );
        expect(body['answer'], cases[index].$2);
        expect(body['idempotency_key'], 'answer-key-$index');
        expect(body.keys, {
          'question_id',
          'question_revision',
          'answer',
          'idempotency_key',
          'payload_digest',
        });
        final snapshot = attempt.snapshots[index];
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              ...receiptJson,
              'receipt_id': 'receipt-${index + 1}',
              'question_id': snapshot.questionId,
              'question_revision': {
                'number': snapshot.revision.number,
                'sha256': snapshot.revision.sha256,
              },
            }),
          );
        await request.response.close();
        await pending;
      }
    },
  );
  test(
    'finish reveals and history use bearer and validate alignment',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final client = QuizApiClient(
        baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
      );
      final requests = StreamIterator(server);
      addTearDown(requests.cancel);
      final boot = client.bootstrap('Ada');
      await requests.moveNext();
      requests.current.response
        ..statusCode = 201
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(guestJson));
      await requests.current.response.close();
      await boot;
      final attempt = Attempt.fromJson(attemptJson);
      final pendingFinish = client.finish(attempt);
      await requests.moveNext();
      expect(requests.current.uri.path, '/v1/attempts/attempt-one/finish');
      expect(
        requests.current.headers.value(HttpHeaders.authorizationHeader),
        'Bearer opaque-token',
      );
      requests.current.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(finishJson));
      await requests.current.response.close();
      final finish = await pendingFinish;
      final pendingReveals = client.reveals(
        attempt,
        finish,
        expectedQuizId: 'quiz-one',
      );
      await requests.moveNext();
      expect(requests.current.uri.path, '/v1/attempts/attempt-one/reveals');
      requests.current.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode([revealJson]));
      await requests.current.response.close();
      expect((await pendingReveals).single.answer, 'One');
      final pendingHistory = client.history();
      await requests.moveNext();
      expect(requests.current.uri.path, '/v1/history');
      requests.current.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode([finishJson]));
      await requests.current.response.close();
      expect((await pendingHistory).single.score, 1);
    },
  );
}

final guestJson = <String, dynamic>{
  'participant_id': 'p-0123456789abcdef0123456789abcdef',
  'kind': 'guest',
  'display_name': 'Ada',
  'token': 'opaque-token',
  'expires_at': '2026-09-20T10:00:00Z',
};
final attemptJson = <String, dynamic>{
  'attempt_id': 'attempt-one',
  'participant_id': 'p-0123456789abcdef0123456789abcdef',
  'bundle_version': 'v1',
  'bundle_sha256': 'a' * 64,
  'scoring_policy_version': 'scoring/v1',
  'status': 'started',
  'question_snapshots': [
    {
      'question_id': 'q-one',
      'question_revision': {'number': 1, 'sha256': 'b' * 64},
      'option_order': ['opt-one', 'opt-two', 'opt-three', 'opt-four'],
      'position_to_option_id': {
        '0': 'opt-one',
        '1': 'opt-two',
        '2': 'opt-three',
        '3': 'opt-four',
      },
    },
  ],
};
final typedAttemptJson = <String, dynamic>{
  ...attemptJson,
  'question_snapshots': [
    for (final (index, id) in ['q-single', 'q-multi', 'q-text'].indexed)
      {
        'question_id': id,
        'question_revision': {
          'number': index + 1,
          'sha256': '${index + 1}' * 64,
        },
        'option_order': ['opt-one', 'opt-two', 'opt-three', 'opt-four'],
        'position_to_option_id': {
          '0': 'opt-one',
          '1': 'opt-two',
          '2': 'opt-three',
          '3': 'opt-four',
        },
      },
  ],
};
final twoQuestionAttemptJson = <String, dynamic>{
  ...attemptJson,
  'question_snapshots': [
    ...(attemptJson['question_snapshots'] as List),
    {
      'question_id': 'q-two',
      'question_revision': {'number': 2, 'sha256': 'c' * 64},
      'option_order': ['opt-one', 'opt-two', 'opt-three', 'opt-four'],
      'position_to_option_id': {
        '0': 'opt-one',
        '1': 'opt-two',
        '2': 'opt-three',
        '3': 'opt-four',
      },
    },
  ],
};
final receiptJson = <String, dynamic>{
  'receipt_id': 'receipt-one',
  'attempt_id': 'attempt-one',
  'participant_id': 'p-0123456789abcdef0123456789abcdef',
  'question_id': 'q-one',
  'question_revision': {'number': 1, 'sha256': 'b' * 64},
  'accepted_at': '2026-09-20T10:00:01Z',
};
final finishJson = <String, dynamic>{
  'attempt_id': 'attempt-one',
  'participant_id': 'p-0123456789abcdef0123456789abcdef',
  'status': 'finished',
  'finished_at': '2026-09-20T10:00:02Z',
  'server_score': 1,
  'history': [
    {
      'question_id': 'q-one',
      'question_revision': {'number': 1, 'sha256': 'b' * 64},
      'receipt_id': 'receipt-one',
    },
  ],
};
final twoQuestionFinishJson = <String, dynamic>{
  ...finishJson,
  'server_score': 2,
  'history': [
    ...(finishJson['history'] as List),
    {
      'question_id': 'q-two',
      'question_revision': {'number': 2, 'sha256': 'c' * 64},
      'receipt_id': 'receipt-two',
    },
  ],
};
final revealJson = <String, dynamic>{
  'quiz_id': 'quiz-one',
  'question_id': 'q-one',
  'question_revision': {'number': 1, 'sha256': 'b' * 64},
  'correct_answer': {'option_id': 'opt-one', 'text': 'One'},
  'explanation': 'Because.',
};
final questionJson = <String, dynamic>{
  'quiz_id': 'quiz-one',
  'question_id': 'q-one',
  'revision': {'number': 1, 'sha256': 'b' * 64},
  'stem': 'One?',
  'options': [
    {'option_id': 'opt-one', 'text': 'One'},
    {'option_id': 'opt-two', 'text': 'Two'},
    {'option_id': 'opt-three', 'text': 'Three'},
    {'option_id': 'opt-four', 'text': 'Four'},
  ],
  'difficulty': 'easy',
  'source': {'uri': 'https://example.test'},
  'answer_kind': 'single_choice',
};
