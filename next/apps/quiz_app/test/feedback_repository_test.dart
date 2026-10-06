import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  test('report and quiz bootstrap share one in-flight participant', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = StreamIterator(server);
    final client = QuizApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
    );
    addTearDown(() async {
      client.dio.close(force: true);
      await requests.cancel();
      await server.close(force: true);
    });
    final quizSession = client.bootstrap('Ada');
    final report = client.submitReport({'request_id': 'frq_${'a' * 32}'});
    expect(await requests.moveNext(), isTrue);
    final guestRequest = requests.current;
    expect(guestRequest.uri.path, '/v1/guests');
    expect(guestRequest.headers.value('Authorization'), isNull);
    await utf8.decoder.bind(guestRequest).join();
    guestRequest.response
      ..statusCode = 201
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({
          'participant_id': 'p-${'a' * 32}',
          'kind': 'guest',
          'display_name': 'Ada',
          'token': 'same-token',
          'expires_at': '2030-01-01T00:00:00Z',
        }),
      );
    await guestRequest.response.close();
    expect((await quizSession).token, 'same-token');
    expect(await requests.moveNext(), isTrue);
    final reportRequest = requests.current;
    expect(reportRequest.uri.path, '/v1/reports');
    expect(reportRequest.headers.value('Authorization'), 'Bearer same-token');
    await utf8.decoder.bind(reportRequest).join();
    reportRequest.response
      ..statusCode = 201
      ..headers.contentType = ContentType.json
      ..write(
        jsonEncode({
          'id': 'rep_${'b' * 32}',
          'status': 'open',
          'created_at': '2026-10-06T00:00:00Z',
        }),
      );
    await reportRequest.response.close();
    await report;
    expect(
      identical(await client.bootstrap('Guest'), await quizSession),
      isTrue,
    );
  });

  test('feedback routes remove invite, query and fragment secrets', () {
    expect(
      feedbackRoute(Uri.parse('/join/secret?token=another#secret')),
      '/join/[invite]',
    );
    expect(
      feedbackRoute(Uri.parse('/quiz/lotr?answer=secret#secret')),
      '/quiz/lotr',
    );
    expect(feedbackRoute(Uri.parse('/unknown/credential')), '/');
  });
}
