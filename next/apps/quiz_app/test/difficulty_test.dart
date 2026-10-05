import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  final question = <String, dynamic>{
    'quiz_id': 'everyday-science',
    'question_id': 'q-test',
    'revision': {'number': 1, 'sha256': 'a' * 64},
    'stem': 'Choose a planet.',
    'options': List.generate(
      4,
      (i) => {'option_id': 'opt-${i + 1}', 'text': 'Option ${i + 1}'},
    ),
    'difficulty': 'nightmare',
    'difficulty_level': 9,
    'context_tag_ids': ['topic:astronomy'],
    'source': {'uri': 'https://example.test'},
    'answer_kind': 'single_choice',
  };

  Map<String, dynamic> serverCatalog() => {
    'bundle_version': 'source-v1',
    'bundle_sha256': 'b' * 64,
    'quiz': {
      'quiz_id': 'everyday-science',
      'revision': {'number': 1, 'sha256': 'c' * 64},
      'locale': 'en',
      'questions': [question],
    },
    // The parser also accepts full-pack counts alongside selected questions.
    'difficulty_counts': {'easy': 20, 'medium': 5, 'hard': 0, 'nightmare': 1},
  };

  test('API catalog accepts full-pack band counts with selected questions', () {
    final parsed = Catalog.fromJson(serverCatalog());
    expect(parsed.quiz.questions.single.difficulty, DifficultyBand.nightmare);
    expect(parsed.bundleVersion, 'source-v1');
  });

  test('API catalog rejects malformed band counts and private fields', () {
    for (final invalid in [
      null,
      {'easy': 0},
      {'easy': 0, 'medium': 0, 'hard': -1, 'nightmare': 1},
      {'easy': 0, 'medium': 0, 'hard': 0, 'nightmare': true},
      {'easy': 0, 'medium': 0, 'hard': 0, 'nightmare': 1, 'answer': 1},
    ]) {
      expect(
        () => Catalog.fromJson({
          ...serverCatalog(),
          'difficulty_counts': invalid,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => Catalog.fromJson({
        ...serverCatalog(),
        'private_question_metadata': {},
      }),
      throwsFormatException,
    );
    final legacy = serverCatalog()..remove('difficulty_counts');
    expect(() => Catalog.fromJson(legacy), returnsNormally);
  });

  test('empty band remains a typed non-retryable API failure', () {
    final failure = ApiFailure.fromJson({
      'code': 'no_match',
      'message': 'No questions match this difficulty.',
      'retryable': false,
      'details': <String, String>{},
    });
    expect(failure.code, 'no_match');
    expect(failure.retryable, isFalse);
  });

  test(
    'public questions accept exact difficulty and safe context metadata',
    () {
      final parsed = PublicQuestion.fromJson(question);
      expect(parsed.difficulty, DifficultyBand.nightmare);
      expect(parsed.difficultyLevel, 9);
      expect(parsed.contextTagIds, ['topic:astronomy']);

      final legacy = PublicQuestion.fromJson(
        {
            ...question,
            'difficulty': 'hard',
            'difficulty_level': null,
            'context_tag_ids': null,
          }
          ..remove('difficulty_level')
          ..remove('context_tag_ids'),
      );
      expect(legacy.difficulty, DifficultyBand.hard);
      expect(legacy.difficultyLevel, isNull);
      expect(legacy.contextTagIds, isEmpty);
    },
  );

  test(
    'public questions reject invalid difficulty mappings and private metadata',
    () {
      expect(() {
        final missingDifficulty = Map<String, dynamic>.from(question)
          ..remove('difficulty');
        PublicQuestion.fromJson(missingDifficulty);
      }, throwsFormatException);
      expect(
        () => PublicQuestion.fromJson({...question, 'difficulty': null}),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({...question, 'difficulty_level': 8}),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({...question, 'difficulty_level': 11}),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({...question, 'difficulty_level': null}),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({
          ...question,
          'difficulty': 'unknown',
          'difficulty_level': 9,
        }),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({
          ...question,
          'context_tag_ids': ['topic:astronomy', 'topic:astronomy'],
        }),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({...question, 'context_tag_ids': null}),
        throwsFormatException,
      );
      for (final privateTag in [
        'country:georgia',
        'ingredient:rice',
        'person:curie',
        'place:paris',
        'cuisine:japanese',
      ]) {
        expect(
          () => PublicQuestion.fromJson({
            ...question,
            'context_tag_ids': [privateTag],
          }),
          throwsFormatException,
        );
      }
      expect(
        () => PublicQuestion.fromJson({
          ...question,
          'editorial_tag_ids': ['answer:planet'],
        }),
        throwsFormatException,
      );
    },
  );

  test('public context tags accept only approved safe namespaces', () {
    final parsed = PublicQuestion.fromJson({
      ...question,
      'context_tag_ids': [
        'domain:science',
        'topic:astronomy',
        'franchise:star-wars',
        'medium:film',
        'era:twentieth-century',
        'skill:deduction',
      ],
    });
    expect(parsed.contextTagIds, hasLength(6));
  });

  test('local study projection can construct an unranked question', () {
    final local = PublicQuestion(
      quizId: 'study-local',
      id: 'study-question',
      revision: Revision(1, '0' * 64),
      stem: 'Study question',
      options: [PublicOption(id: 'study-option', text: 'Answer')],
      kind: AnswerKind.singleChoice,
    );
    expect(local.difficulty, isNull);
    expect(local.difficultyLevel, isNull);
  });

  test(
    'discovery accepts valid optional difficulty counts and context search',
    () {
      final pack = CatalogPack.fromJson({
        'quiz_id': 'everyday-science',
        'title': 'Everyday science',
        'description': 'Description',
        'category': 'General',
        'questions_count': 20,
        'difficulty_counts': {
          'easy': 3,
          'medium': 6,
          'hard': 8,
          'nightmare': 3,
          'unknown': 0,
        },
        'context_search_terms': ['астрономия', 'astronomy'],
      });
      expect(pack.count(DifficultyBand.easy), 3);
      expect(pack.count(DifficultyBand.nightmare), 3);
      expect(pack.searchableText, contains('астрономия'));
    },
  );

  test(
    'discovery rejects malformed difficulty counts and unsafe search terms',
    () {
      final base = <String, dynamic>{
        'quiz_id': 'everyday-science',
        'title': 'Everyday science',
        'description': 'Description',
        'category': 'General',
        'questions_count': 20,
      };
      expect(
        () => CatalogPack.fromJson({
          ...base,
          'difficulty_counts': {'easy': 1, 'medium': 2},
        }),
        throwsFormatException,
      );
      expect(
        () => CatalogPack.fromJson({
          ...base,
          'context_search_terms': ['safe', 'safe'],
        }),
        throwsFormatException,
      );
    },
  );
}
