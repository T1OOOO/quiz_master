part of 'main.dart';

enum AnswerKind { singleChoice, multipleChoice, normalizedText }

sealed class StagedAnswer {
  const StagedAnswer();

  factory StagedAnswer.fromInput(AnswerKind kind, Object value) => switch ((
    kind,
    value,
  )) {
    (AnswerKind.singleChoice, String id) => SingleChoiceAnswer(id),
    (AnswerKind.multipleChoice, Set<String> ids) => MultipleChoiceAnswer(ids),
    (AnswerKind.normalizedText, String text) => NormalizedTextAnswer(text),
    _ => throw const FormatException('staged answer'),
  };

  Map<String, Object> toJson();
}

class SingleChoiceAnswer extends StagedAnswer {
  const SingleChoiceAnswer(this.optionId);
  final String optionId;

  @override
  Map<String, Object> toJson() => {'option_id': optionId};
}

class MultipleChoiceAnswer extends StagedAnswer {
  MultipleChoiceAnswer(Set<String> optionIds)
    : optionIds = (optionIds.toList()..sort());
  final List<String> optionIds;

  @override
  Map<String, Object> toJson() => {'option_ids': optionIds};
}

class NormalizedTextAnswer extends StagedAnswer {
  const NormalizedTextAnswer(this.text);
  final String text;

  @override
  Map<String, Object> toJson() => {'text': text};
}

class Revision {
  const Revision(this.number, this.sha256);
  final int number;
  final String sha256;
  factory Revision.fromJson(Map<String, dynamic> json) {
    _closed(json, {'number', 'sha256'});
    if (json['number'] is! int ||
        (json['number'] as int) < 1 ||
        json['sha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(json['sha256'] as String)) {
      throw const FormatException('revision');
    }
    return Revision(json['number'] as int, json['sha256'] as String);
  }
}

class PublicOption {
  const PublicOption({required this.id, required this.text});
  final String id;
  final String text;
  factory PublicOption.fromJson(Map<String, dynamic> json) {
    _closed(json, {'option_id', 'text', 'media'});
    if (json['option_id'] is! String ||
        !_validId(json['option_id'] as String) ||
        json['text'] is! String ||
        (json['text'] as String).isEmpty) {
      throw const FormatException('option');
    }
    if (json['media'] != null) Media.fromJson(_map(json['media']));
    return PublicOption(
      id: json['option_id'] as String,
      text: json['text'] as String,
    );
  }
}

class Source {
  const Source();
  factory Source.fromJson(Map<String, dynamic> json) {
    _closed(json, {'uri', 'title'});
    if (json['uri'] is! String ||
        (json['uri'] as String).isEmpty ||
        (json['title'] != null && json['title'] is! String)) {
      throw const FormatException('source');
    }
    return const Source();
  }
}

class Media {
  const Media();
  factory Media.fromJson(Map<String, dynamic> json) {
    _closed(json, {'uri', 'kind', 'alt'});
    if (json['uri'] is! String ||
        (json['uri'] as String).isEmpty ||
        (json['kind'] != null && json['kind'] is! String) ||
        (json['alt'] != null && json['alt'] is! String)) {
      throw const FormatException('media');
    }
    return const Media();
  }
}

class PublicQuestion {
  const PublicQuestion({
    required this.quizId,
    required this.id,
    required this.revision,
    required this.stem,
    required this.options,
    required this.kind,
  });
  final String quizId;
  final String id;
  final Revision revision;
  final String stem;
  final List<PublicOption> options;
  final AnswerKind kind;
  factory PublicQuestion.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'quiz_id',
      'question_id',
      'revision',
      'stem',
      'options',
      'difficulty',
      'source',
      'media',
      'answer_kind',
    });
    final options = json['options'];
    final kind = switch (json['answer_kind']) {
      'single_choice' => AnswerKind.singleChoice,
      'multiple_choice' => AnswerKind.multipleChoice,
      'normalized_text' => AnswerKind.normalizedText,
      _ => throw const FormatException('answer_kind'),
    };
    const difficulties = {'unknown', 'easy', 'medium', 'hard'};
    if (json['quiz_id'] is! String ||
        !_validId(json['quiz_id'] as String) ||
        json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['stem'] is! String ||
        (json['stem'] as String).isEmpty ||
        !difficulties.contains(json['difficulty']) ||
        options is! List ||
        options.length < 4 ||
        options.length > 6) {
      throw const FormatException('public question');
    }
    final media = json['media'];
    if (media != null && media is! List) throw const FormatException('media');
    Source.fromJson(_map(json['source']));
    if (media != null) {
      for (final item in media) {
        Media.fromJson(_map(item));
      }
    }
    final parsedOptions = options
        .map((e) => PublicOption.fromJson(_map(e)))
        .toList(growable: false);
    if (parsedOptions.map((option) => option.id).toSet().length !=
        parsedOptions.length) {
      throw const FormatException('duplicate option');
    }
    return PublicQuestion(
      quizId: json['quiz_id'] as String,
      id: json['question_id'] as String,
      revision: Revision.fromJson(_map(json['revision'])),
      stem: json['stem'] as String,
      options: parsedOptions,
      kind: kind,
    );
  }
}

class Reveal {
  const Reveal({
    required this.answer,
    required this.explanation,
    this.quizId,
    this.questionId,
    this.revision,
  });
  final String answer;
  final String explanation;
  final String? quizId;
  final String? questionId;
  final Revision? revision;
  factory Reveal.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'quiz_id',
      'question_id',
      'question_revision',
      'correct_answer',
      'explanation',
    });
    if (json['quiz_id'] is! String ||
        !_validId(json['quiz_id'] as String) ||
        json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['explanation'] is! String ||
        (json['explanation'] as String).isEmpty) {
      throw const FormatException('reveal');
    }
    Revision.fromJson(_map(json['question_revision']));
    final answer = _map(json['correct_answer']);
    _closed(answer, {'option_id', 'option_ids', 'text'});
    final keys = answer.keys.toSet();
    final single =
        keys.length == 2 &&
        keys.containsAll({'option_id', 'text'}) &&
        answer['option_id'] is String &&
        _validId(answer['option_id'] as String);
    final optionIds = answer['option_ids'];
    final multiple =
        keys.length == 2 &&
        keys.containsAll({'option_ids', 'text'}) &&
        optionIds is List &&
        optionIds.isNotEmpty &&
        optionIds.every((id) => id is String && _validId(id)) &&
        optionIds.toSet().length == optionIds.length;
    final text = keys.length == 1 && keys.contains('text');
    if (answer['text'] is! String ||
        (answer['text'] as String).isEmpty ||
        (!single && !multiple && !text)) {
      throw const FormatException('reveal');
    }
    return Reveal(
      answer: answer['text'] as String,
      explanation: json['explanation'] as String,
      quizId: json['quiz_id'] as String,
      questionId: json['question_id'] as String,
      revision: Revision.fromJson(_map(json['question_revision'])),
    );
  }
}

class ApiFailure {
  const ApiFailure({
    required this.code,
    required this.message,
    required this.retryable,
    required this.details,
  });
  final String code;
  final String message;
  final bool retryable;
  final Map<String, String> details;
  factory ApiFailure.fromJson(Map<String, dynamic> json) {
    _closed(json, {'code', 'message', 'retryable', 'details'});
    const codes = {
      'deadline_exceeded',
      'stale_revision',
      'stale_round',
      'forbidden',
      'validation_failed',
      'idempotency_conflict',
    };
    if (!codes.contains(json['code']) ||
        json['message'] is! String ||
        json['retryable'] is! bool ||
        json['details'] is! Map ||
        (json['details'] as Map).entries.any(
          (entry) => entry.key is! String || entry.value is! String,
        )) {
      throw const FormatException('error envelope');
    }
    final details = Map<String, String>.from(json['details'] as Map);
    return ApiFailure(
      code: json['code'] as String,
      message: json['message'] as String,
      retryable: json['retryable'] as bool,
      details: details,
    );
  }
}

void _closed(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('unknown or private field');
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('object required');
  }
  return value;
}

bool _validId(String value) =>
    RegExp(r'^[a-z][a-z0-9-]{2,63}$').hasMatch(value);

DateTime _utcInstant(Object? value) {
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|\+00:00)$')
          .hasMatch(value)) {
    throw const FormatException('UTC RFC3339 instant required');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw const FormatException('UTC RFC3339 instant required');
  }
  return parsed;
}

class ApiClientException implements Exception {
  const ApiClientException(this.code, {required this.retryable});
  final String code;
  final bool retryable;
  @override
  String toString() => 'ApiClientException($code)';
}

class GuestSession {
  const GuestSession({
    required this.participantId,
    required this.displayName,
    required this.token,
    required this.expiresAt,
  });
  final String participantId;
  final String displayName;
  final String token;
  final DateTime expiresAt;

  factory GuestSession.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'participant_id',
      'kind',
      'display_name',
      'token',
      'expires_at',
    });
    DateTime? expiresAt;
    try {
      expiresAt = _utcInstant(json['expires_at']);
    } on FormatException {
      expiresAt = null;
    }
    if (json['participant_id'] is! String ||
        !RegExp(r'^p-[0-9a-f]{32}$')
            .hasMatch(json['participant_id'] as String) ||
        json['kind'] != 'guest' ||
        json['display_name'] is! String ||
        (json['display_name'] as String).trim().isEmpty ||
        json['token'] is! String ||
        (json['token'] as String).isEmpty ||
        expiresAt == null) {
      throw const FormatException('guest session');
    }
    return GuestSession(
      participantId: json['participant_id'] as String,
      displayName: json['display_name'] as String,
      token: json['token'] as String,
      expiresAt: expiresAt,
    );
  }
}

class PublicQuiz {
  const PublicQuiz({required this.id, required this.questions});
  final String id;
  final List<PublicQuestion> questions;

  factory PublicQuiz.fromJson(Map<String, dynamic> json) {
    _closed(json, {'quiz_id', 'revision', 'locale', 'questions'});
    if (json['quiz_id'] is! String ||
        !_validId(json['quiz_id'] as String) ||
        json['locale'] is! String ||
        (json['locale'] as String).isEmpty ||
        json['questions'] is! List) {
      throw const FormatException('public quiz');
    }
    Revision.fromJson(_map(json['revision']));
    final questions = (json['questions'] as List)
        .map((item) => PublicQuestion.fromJson(_map(item)))
        .toList(growable: false);
    if (questions.any((question) => question.quizId != json['quiz_id']) ||
        questions.map((question) => question.id).toSet().length !=
            questions.length) {
      throw const FormatException('public quiz');
    }
    return PublicQuiz(id: json['quiz_id'] as String, questions: questions);
  }
}

class Catalog {
  const Catalog({
    required this.bundleVersion,
    required this.bundleSha256,
    required this.quiz,
  });
  final String bundleVersion;
  final String bundleSha256;
  final PublicQuiz quiz;

  factory Catalog.fromJson(Map<String, dynamic> json) {
    _closed(json, {'bundle_version', 'bundle_sha256', 'quiz'});
    if (json['bundle_version'] is! String ||
        (json['bundle_version'] as String).isEmpty ||
        json['bundle_sha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(json['bundle_sha256'] as String)) {
      throw const FormatException('catalog');
    }
    return Catalog(
      bundleVersion: json['bundle_version'] as String,
      bundleSha256: json['bundle_sha256'] as String,
      quiz: PublicQuiz.fromJson(_map(json['quiz'])),
    );
  }
}

bool _sameRevision(Revision a, Revision b) =>
    a.number == b.number && a.sha256 == b.sha256;

class AttemptSnapshot {
  const AttemptSnapshot({
    required this.questionId,
    required this.revision,
    required this.optionOrder,
  });
  final String questionId;
  final Revision revision;
  final List<String> optionOrder;
  factory AttemptSnapshot.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'question_id',
      'question_revision',
      'option_order',
      'position_to_option_id',
    });
    if (json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['option_order'] is! List) {
      throw const FormatException('snapshot');
    }
    final order = (json['option_order'] as List)
        .map(
          (item) => item is String && _validId(item)
              ? item
              : throw const FormatException('snapshot'),
        )
        .toList(growable: false);
    final positions = _map(json['position_to_option_id']);
    if (order.length < 4 ||
        order.length > 6 ||
        order.toSet().length != order.length ||
        positions.length != order.length ||
        !Iterable.generate(order.length)
            .every((index) => positions['$index'] == order[index]) ||
        positions.entries.any(
          (entry) => entry.value is! String || !_validId(entry.value as String),
        )) {
      throw const FormatException('snapshot');
    }
    return AttemptSnapshot(
      questionId: json['question_id'] as String,
      revision: Revision.fromJson(_map(json['question_revision'])),
      optionOrder: order,
    );
  }
}

class Attempt {
  const Attempt({
    required this.id,
    required this.participantId,
    required this.bundleVersion,
    required this.bundleSha256,
    required this.snapshots,
  });
  final String id;
  final String participantId;
  final String bundleVersion;
  final String bundleSha256;
  final List<AttemptSnapshot> snapshots;
  factory Attempt.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'attempt_id',
      'participant_id',
      'bundle_version',
      'bundle_sha256',
      'scoring_policy_version',
      'question_snapshots',
      'status',
    });
    if (json['attempt_id'] is! String ||
        !_validId(json['attempt_id'] as String) ||
        json['participant_id'] is! String ||
        !RegExp(r'^p-[0-9a-f]{32}$')
            .hasMatch(json['participant_id'] as String) ||
        json['bundle_version'] is! String ||
        (json['bundle_version'] as String).isEmpty ||
        json['bundle_sha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(json['bundle_sha256'] as String) ||
        json['scoring_policy_version'] != 'scoring/v1' ||
        json['status'] != 'started' ||
        json['question_snapshots'] is! List) {
      throw const FormatException('attempt');
    }
    final snapshots = (json['question_snapshots'] as List)
        .map((item) => AttemptSnapshot.fromJson(_map(item)))
        .toList(growable: false);
    if (snapshots.isEmpty ||
        snapshots.map((snapshot) => snapshot.questionId).toSet().length !=
            snapshots.length) {
      throw const FormatException('attempt');
    }
    return Attempt(
      id: json['attempt_id'] as String,
      participantId: json['participant_id'] as String,
      bundleVersion: json['bundle_version'] as String,
      bundleSha256: json['bundle_sha256'] as String,
      snapshots: snapshots,
    );
  }
}

void validateAttemptCatalog(Attempt attempt, Catalog catalog) {
  if (attempt.bundleVersion != catalog.bundleVersion ||
      attempt.bundleSha256 != catalog.bundleSha256 ||
      attempt.snapshots.length != catalog.quiz.questions.length) {
    throw const FormatException('attempt catalog mismatch');
  }
  for (var index = 0; index < attempt.snapshots.length; index++) {
    final snapshot = attempt.snapshots[index];
    final question = catalog.quiz.questions[index];
    if (snapshot.questionId != question.id ||
        !_sameRevision(snapshot.revision, question.revision) ||
        snapshot.optionOrder.length != question.options.length ||
        snapshot.optionOrder.toSet().length != question.options.length ||
        !snapshot.optionOrder.toSet().containsAll(
          question.options.map((option) => option.id),
        )) {
      throw const FormatException('attempt catalog mismatch');
    }
  }
}

class Receipt {
  const Receipt({
    required this.id,
    required this.attemptId,
    required this.participantId,
    required this.questionId,
    required this.revision,
  });
  final String id;
  final String attemptId;
  final String participantId;
  final String questionId;
  final Revision revision;
  factory Receipt.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'receipt_id',
      'attempt_id',
      'participant_id',
      'question_id',
      'question_revision',
      'accepted_at',
    });
    if (json['receipt_id'] is! String ||
        !_validId(json['receipt_id'] as String) ||
        json['attempt_id'] is! String ||
        !_validId(json['attempt_id'] as String) ||
        json['participant_id'] is! String ||
        !RegExp(r'^p-[0-9a-f]{32}$')
            .hasMatch(json['participant_id'] as String) ||
        json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['accepted_at'] is! String) {
      throw const FormatException('receipt');
    }
    _utcInstant(json['accepted_at']);
    return Receipt(
      id: json['receipt_id'] as String,
      attemptId: json['attempt_id'] as String,
      participantId: json['participant_id'] as String,
      questionId: json['question_id'] as String,
      revision: Revision.fromJson(_map(json['question_revision'])),
    );
  }
}

class HistoryEntry {
  const HistoryEntry({
    required this.questionId,
    required this.revision,
    required this.receiptId,
  });
  final String questionId;
  final Revision revision;
  final String receiptId;
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    _closed(json, {'question_id', 'question_revision', 'receipt_id'});
    if (json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['receipt_id'] is! String ||
        !_validId(json['receipt_id'] as String)) {
      throw const FormatException('history entry');
    }
    return HistoryEntry(
      questionId: json['question_id'] as String,
      revision: Revision.fromJson(_map(json['question_revision'])),
      receiptId: json['receipt_id'] as String,
    );
  }
}

class Finish {
  const Finish({
    required this.attemptId,
    required this.participantId,
    required this.score,
    required this.history,
  });
  final String attemptId;
  final String participantId;
  final int score;
  final List<HistoryEntry> history;
  factory Finish.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'attempt_id',
      'participant_id',
      'status',
      'finished_at',
      'server_score',
      'history',
    });
    if (json['attempt_id'] is! String ||
        !_validId(json['attempt_id'] as String) ||
        json['participant_id'] is! String ||
        !RegExp(r'^p-[0-9a-f]{32}$')
            .hasMatch(json['participant_id'] as String) ||
        json['status'] != 'finished' ||
        json['finished_at'] is! String ||
        json['server_score'] is! int ||
        (json['server_score'] as int) < 0 ||
        json['history'] is! List) {
      throw const FormatException('finish');
    }
    _utcInstant(json['finished_at']);
    final history = (json['history'] as List)
        .map((item) => HistoryEntry.fromJson(_map(item)))
        .toList(growable: false);
    if (history.isEmpty ||
        history.map((entry) => entry.questionId).toSet().length !=
            history.length ||
        history.map((entry) => entry.receiptId).toSet().length !=
            history.length) {
      throw const FormatException('finish');
    }
    return Finish(
      attemptId: json['attempt_id'] as String,
      participantId: json['participant_id'] as String,
      score: json['server_score'] as int,
      history: history,
    );
  }
}

void validateFinishReceipts(Finish finish, List<Receipt> receipts) {
  if (finish.history.length != receipts.length) {
    throw const FormatException('finish receipt mismatch');
  }
  final byQuestion = {
    for (final receipt in receipts) receipt.questionId: receipt,
  };
  if (byQuestion.length != receipts.length ||
      finish.history.any((entry) {
        final receipt = byQuestion[entry.questionId];
        return receipt == null ||
            receipt.id != entry.receiptId ||
            !_sameRevision(receipt.revision, entry.revision);
      })) {
    throw const FormatException('finish receipt mismatch');
  }
}
