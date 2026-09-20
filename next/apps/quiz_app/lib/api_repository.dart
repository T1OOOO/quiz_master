part of 'main.dart';

String answerPayloadDigest({
  required String attemptId,
  required String participantId,
  required String questionId,
  required Revision revision,
  required Map<String, Object> answer,
}) {
  final canonical = _canonicalJson(<String, Object>{
    'attempt_id': attemptId,
    'participant_id': participantId,
    'question_id': questionId,
    'question_revision': <String, Object>{
      'number': revision.number,
      'sha256': revision.sha256,
    },
    'answer': answer,
  });
  return sha256.convert(utf8.encode(canonical)).toString();
}

String _canonicalJson(Object value) {
  if (value is Map) {
    final entries =
        value.entries
            .map((entry) => MapEntry(entry.key as String, entry.value))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return '{${entries.map((entry) => '${jsonEncode(entry.key)}:${_canonicalJson(entry.value)}').join(',')}}';
  }
  if (value is List) {
    return '[${value.map((item) => _canonicalJson(item)).join(',')}]';
  }
  if (value is String || value is num || value is bool) {
    return jsonEncode(value);
  }
  throw ArgumentError.value(value, 'value', 'unsupported canonical JSON value');
}

void validateReveals({
  required Attempt attempt,
  required Finish finish,
  required String expectedQuizId,
  required List<Reveal> reveals,
}) {
  if (reveals.length != finish.history.length ||
      reveals.length != attempt.snapshots.length ||
      reveals.map((reveal) => reveal.questionId).toSet().length !=
          reveals.length) {
    throw const FormatException('reveal mismatch');
  }
  for (var index = 0; index < reveals.length; index++) {
    final reveal = reveals[index];
    final history = finish.history[index];
    final snapshot = attempt.snapshots[index];
    final revision = reveal.revision;
    if (reveal.quizId != expectedQuizId ||
        reveal.questionId != history.questionId ||
        reveal.questionId != snapshot.questionId ||
        revision == null ||
        !_sameRevision(revision, history.revision) ||
        !_sameRevision(revision, snapshot.revision)) {
      throw const FormatException('reveal mismatch');
    }
  }
}

class QuizApiClient {
  QuizApiClient({
    required Uri baseUri,
    Duration timeout = const Duration(seconds: 10),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: _validBaseUri(baseUri).toString(),
           connectTimeout: timeout,
           receiveTimeout: timeout,
         ),
       );
  final Dio _dio;
  GuestSession? _session;
  Dio get dio => _dio;

  /// Creates an in-memory guest session.  The bearer is deliberately not
  /// attached until this request has completed successfully.
  Future<GuestSession> bootstrap(String displayName) async {
    final cleaned = displayName.trim();
    if (cleaned.isEmpty || cleaned.length > 100) {
      throw const ApiClientException('validation_failed', retryable: false);
    }
    try {
      final response = await _dio.post<Object>(
        '/v1/guests',
        data: <String, Object>{'display_name': cleaned},
        options: Options(contentType: Headers.jsonContentType),
      );
      if (response.statusCode != 201) throw _failure(response.data);
      return _session = GuestSession.fromJson(_map(response.data));
    } on DioException catch (error) {
      if (error.response?.data != null) throw _failure(error.response!.data);
      throw const ApiClientException('network', retryable: true);
    }
  }

  Future<Catalog> catalog() async {
    try {
      final response = await _dio.get<Object>('/v1/catalog');
      if (response.statusCode != 200) throw _failure(response.data);
      return Catalog.fromJson(_map(response.data));
    } on DioException catch (error) {
      if (error.response?.data != null) throw _failure(error.response!.data);
      throw const ApiClientException('network', retryable: true);
    }
  }

  Future<Attempt> startAttempt() async {
    final response = await _authenticatedPost('/v1/attempts', const {});
    if (response.statusCode != 201) throw _failure(response.data);
    final attempt = Attempt.fromJson(_map(response.data));
    if (attempt.participantId != _requireSession().participantId) {
      throw const FormatException('attempt participant');
    }
    return attempt;
  }

  Future<Receipt> submitAnswer(
    Attempt attempt,
    AttemptSnapshot snapshot,
    StagedAnswer stagedAnswer, {
    required String idempotencyKey,
  }) async {
    if (attempt.participantId != _requireSession().participantId ||
        !attempt.snapshots.contains(snapshot) ||
        idempotencyKey.isEmpty ||
        idempotencyKey.length > 200) {
      throw const FormatException('answer request');
    }
    final answer = stagedAnswer.toJson();
    final payload = <String, Object>{
      'question_id': snapshot.questionId,
      'question_revision': <String, Object>{
        'number': snapshot.revision.number,
        'sha256': snapshot.revision.sha256,
      },
      'answer': answer,
      'idempotency_key': idempotencyKey,
      'payload_digest': answerPayloadDigest(
        attemptId: attempt.id,
        participantId: attempt.participantId,
        questionId: snapshot.questionId,
        revision: snapshot.revision,
        answer: answer,
      ),
    };
    final response = await _authenticatedPost(
      '/v1/attempts/${attempt.id}/answers',
      payload,
    );
    if (response.statusCode != 200) throw _failure(response.data);
    final receipt = Receipt.fromJson(_map(response.data));
    if (receipt.attemptId != attempt.id ||
        receipt.participantId != attempt.participantId ||
        receipt.questionId != snapshot.questionId ||
        !_sameRevision(receipt.revision, snapshot.revision)) {
      throw const FormatException('receipt mismatch');
    }
    return receipt;
  }

  Future<Finish> finish(Attempt attempt) async {
    final response = await _authenticatedPost(
      '/v1/attempts/${attempt.id}/finish',
      const {},
    );
    if (response.statusCode != 200) throw _failure(response.data);
    final finish = Finish.fromJson(_map(response.data));
    if (finish.attemptId != attempt.id ||
        finish.participantId != attempt.participantId) {
      throw const FormatException('finish mismatch');
    }
    return finish;
  }

  Future<List<Reveal>> reveals(
    Attempt attempt,
    Finish finish, {
    required String expectedQuizId,
  }) async {
    final response = await _authenticatedGet(
      '/v1/attempts/${attempt.id}/reveals',
    );
    if (response.statusCode != 200) throw _failure(response.data);
    if (response.data is! List) throw const FormatException('reveals');
    final values = (response.data as List)
        .map((item) => Reveal.fromJson(_map(item)))
        .toList(growable: false);
    validateReveals(
      attempt: attempt,
      finish: finish,
      expectedQuizId: expectedQuizId,
      reveals: values,
    );
    return values;
  }

  Future<List<Finish>> history() async {
    final response = await _authenticatedGet('/v1/history');
    if (response.statusCode != 200) throw _failure(response.data);
    if (response.data is! List) throw const FormatException('history');
    return (response.data as List)
        .map((item) => Finish.fromJson(_map(item)))
        .toList(growable: false);
  }

  GuestSession _requireSession() =>
      _session ??
      (throw const ApiClientException(
        'authentication_required',
        retryable: false,
      ));

  Future<Response<Object>> _authenticatedPost(String path, Object data) async {
    try {
      return await _dio.post<Object>(
        path,
        data: data,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: <String, Object>{
            'Authorization': 'Bearer ${_requireSession().token}',
          },
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      throw const ApiClientException('network', retryable: true);
    }
  }

  Future<Response<Object>> _authenticatedGet(String path) async {
    try {
      return await _dio.get<Object>(
        path,
        options: Options(
          headers: <String, Object>{
            'Authorization': 'Bearer ${_requireSession().token}',
          },
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      throw const ApiClientException('network', retryable: true);
    }
  }

  ApiClientException _failure(Object? data) {
    try {
      final failure = ApiFailure.fromJson(_map(data));
      return ApiClientException(failure.code, retryable: failure.retryable);
    } on FormatException {
      return const ApiClientException('invalid_response', retryable: false);
    }
  }

  static Uri _validBaseUri(Uri uri) {
    if (!uri.hasScheme ||
        !uri.hasAuthority ||
        !(uri.scheme == 'https' ||
            (uri.scheme == 'http' && _isLoopbackHost(uri.host)))) {
      throw ArgumentError.value(
        uri,
        'baseUri',
        'must use HTTPS, except for a loopback HTTP development URI',
      );
    }
    return uri;
  }

  static bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' || normalized == '::1') return true;
    final parts = normalized.split('.');
    return parts.length == 4 &&
        parts.first == '127' &&
        parts.every((part) {
          final value = int.tryParse(part);
          return value != null && value >= 0 && value <= 255;
        });
  }
}
