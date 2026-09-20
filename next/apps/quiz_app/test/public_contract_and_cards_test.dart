import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';
import 'package:quiz_app/l10n/app_localizations.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  final base = <String, dynamic>{
    'quiz_id': 'everyday-science',
    'question_id': 'q-test',
    'revision': {'number': 1, 'sha256': 'a' * 64},
    'stem': 'Choose a planet.',
    'options': List.generate(
      4,
      (i) => {'option_id': 'opt-${i + 1}', 'text': 'Option ${i + 1}'},
    ),
    'difficulty': 'easy',
    'source': {'uri': 'https://example.test'},
    'answer_kind': 'single_choice',
  };
  test('public contract parser rejects secret and unknown fields', () {
    expect(
      () => PublicQuestion.fromJson({...base, 'correct_option_id': 'opt-1'}),
      throwsFormatException,
    );
    expect(
      () => ApiFailure.fromJson({
        'code': 'forbidden',
        'message': 'No',
        'retryable': false,
        'details': {},
        'grading': {},
      }),
      throwsFormatException,
    );
    expect(
      () => Reveal.fromJson({
        'quiz_id': 'q',
        'question_id': 'q',
        'question_revision': {'number': 1, 'sha256': 'a' * 64},
        'correct_answer': {'text': 'A'},
        'explanation': 'Because',
        'accepted_variants': [],
      }),
      throwsFormatException,
    );
  });

  test('closed decoders reject nested secrets and non-string details', () {
    expect(
      () => PublicQuestion.fromJson({
        ...base,
        'source': {'uri': 'https://example.test', 'private_grading': 'no'},
      }),
      throwsFormatException,
    );
    expect(
      () => PublicQuestion.fromJson({
        ...base,
        'options': [
          ...base['options'] as List,
          {
            'option_id': 'opt-5',
            'text': 'Five',
            'media': {'uri': 'x', 'secret': 'no'},
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ApiFailure.fromJson({
        'code': 'forbidden',
        'message': 'No',
        'retryable': false,
        'details': {'attempt': 1},
      }),
      throwsFormatException,
    );
    expect(
      () => Reveal.fromJson({
        'quiz_id': 'quiz-test',
        'question_id': 'question-test',
        'question_revision': {'number': 1, 'sha256': 'a' * 64, 'extra': true},
        'correct_answer': {'text': 'A', 'grading': 'no'},
        'explanation': 'Because',
      }),
      throwsFormatException,
    );
  });

  test(
    'contract decoder enforces IDs revisions option uniqueness and bounds',
    () {
      expect(
        () => PublicQuestion.fromJson({...base, 'question_id': 'Bad_ID'}),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({
          ...base,
          'revision': {'number': 0, 'sha256': 'A' * 64},
        }),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({...base, 'difficulty': 'expert'}),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({
          ...base,
          'options': [
            ...base['options'] as List,
            {'option_id': 'opt-1', 'text': 'Duplicate'},
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({
          ...base,
          'options': (base['options'] as List).take(3).toList(),
        }),
        throwsFormatException,
      );
      expect(
        () => PublicQuestion.fromJson({
          ...base,
          'options': List.generate(
            7,
            (i) => {'option_id': 'opt-${i + 1}', 'text': 'Option ${i + 1}'},
          ),
        }),
        throwsFormatException,
      );
    },
  );

  test('reveal decoder accepts exactly one nonempty answer variant', () {
    final reveal = {
      'quiz_id': 'quiz-test',
      'question_id': 'question-test',
      'question_revision': {'number': 1, 'sha256': 'a' * 64},
      'explanation': 'Because',
    };
    expect(
      Reveal.fromJson({
        ...reveal,
        'correct_answer': {'option_id': 'opt-1', 'text': 'One'},
      }).answer,
      'One',
    );
    expect(
      Reveal.fromJson({
        ...reveal,
        'correct_answer': {
          'option_ids': ['opt-1', 'opt-2'],
          'text': 'One and two',
        },
      }).answer,
      'One and two',
    );
    expect(
      Reveal.fromJson({
        ...reveal,
        'correct_answer': {'text': 'Mars'},
      }).answer,
      'Mars',
    );
    for (final invalidAnswer in [
      <String, dynamic>{},
      {'text': ''},
      {
        'option_id': 'opt-1',
        'option_ids': ['opt-1'],
        'text': 'One',
      },
      {'option_ids': <String>[], 'text': 'Many'},
      {
        'option_ids': ['opt-1', 'opt-1'],
        'text': 'Many',
      },
      {
        'option_id': 'opt-1',
        'text': 'One',
        'accepted_variants': ['One'],
      },
    ]) {
      expect(
        () => Reveal.fromJson({...reveal, 'correct_answer': invalidAnswer}),
        throwsFormatException,
      );
    }
  });

  test('typed error envelope and public shape decode closed values', () {
    expect(
      ApiFailure.fromJson({
        'code': 'forbidden',
        'message': 'No',
        'retryable': false,
        'details': {'field': 'x'},
      }).details['field'],
      'x',
    );
    expect(PublicQuestion.fromJson(base).options, hasLength(4));
  });

  testWidgets('single selection returns the stable option id', (tester) async {
    Object? selected;
    await tester.pumpWidget(
      app(
        QuestionCard(
          question: PublicQuestion.fromJson(base),
          onAnswer: (value) => selected = value,
        ),
      ),
    );
    await tester.tap(find.text('Option 2'));
    expect(selected, 'opt-2');
  });

  testWidgets('multiple selection returns stable ids', (tester) async {
    Object? selected;
    final question = PublicQuestion.fromJson({
      ...base,
      'answer_kind': 'multiple_choice',
      'options': List.generate(
        5,
        (i) => {'option_id': 'opt-${i + 1}', 'text': 'Option ${i + 1}'},
      ),
    });
    await tester.pumpWidget(
      app(
        QuestionCard(question: question, onAnswer: (value) => selected = value),
      ),
    );
    await tester.tap(find.text('Option 1'));
    await tester.tap(find.text('Option 5'));
    expect(selected, {'opt-1', 'opt-5'});
  });

  testWidgets(
    'normalized text submits normalized input and reveal is explicit',
    (tester) async {
      Object? answer;
      final question = PublicQuestion.fromJson({
        ...base,
        'answer_kind': 'normalized_text',
        'options': List.generate(
          6,
          (i) => {'option_id': 'opt-${i + 1}', 'text': 'Option ${i + 1}'},
        ),
      });
      await tester.pumpWidget(
        app(
          QuestionCard(
            question: question,
            onAnswer: (value) => answer = value,
            reveal: const Reveal(answer: 'Mars', explanation: 'A planet'),
          ),
        ),
      );
      expect(find.textContaining('Answer: Mars'), findsOneWidget);
      expect(find.text('A planet'), findsOneWidget);
      expect(answer, isNull);
    },
  );

  testWidgets('normalized text submits from the visible submit control', (
    tester,
  ) async {
    Object? answer;
    final question = PublicQuestion.fromJson({
      ...base,
      'answer_kind': 'normalized_text',
    });
    await tester.pumpWidget(
      app(
        QuestionCard(question: question, onAnswer: (value) => answer = value),
      ),
    );
    await tester.enterText(find.byType(TextField), '  Mars  ');
    await tester.pump();
    await tester.tap(find.text('Submit answer'));
    expect(answer, 'mars');
  });

  testWidgets('submitting state suppresses text and choice callbacks', (
    tester,
  ) async {
    final answers = <Object>[];
    final textQuestion = PublicQuestion.fromJson({
      ...base,
      'answer_kind': 'normalized_text',
    });
    await tester.pumpWidget(
      app(
        QuestionCard(
          question: textQuestion,
          submitting: true,
          onAnswer: answers.add,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(answers, isEmpty);

    await tester.pumpWidget(
      app(
        QuestionCard(
          question: PublicQuestion.fromJson(base),
          submitting: true,
          onAnswer: answers.add,
        ),
      ),
    );
    await tester.tap(find.text('Option 1'));
    expect(answers, isEmpty);
  });

  testWidgets('single-choice control activates its stable ID with Enter', (
    tester,
  ) async {
    final answers = <Object>[];
    await tester.pumpWidget(
      app(
        QuestionCard(
          question: PublicQuestion.fromJson(base),
          onAnswer: answers.add,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(answers, ['opt-1']);
  });

  testWidgets('multiple-choice control activates its stable ID with Space', (
    tester,
  ) async {
    final answers = <Object>[];
    await tester.pumpWidget(
      app(
        QuestionCard(
          question: PublicQuestion.fromJson({
            ...base,
            'answer_kind': 'multiple_choice',
          }),
          onAnswer: answers.add,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(answers, [
      {'opt-1'},
    ]);
  });

  testWidgets('cards fit a narrow phone and large text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: QuestionCard(question: fixtures[2], onAnswer: (_) {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'submitting cards disable stable-id choices and retain semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      Object? selected;
      await tester.pumpWidget(
        app(
          QuestionCard(
            question: PublicQuestion.fromJson(base),
            submitting: true,
            onAnswer: (value) => selected = value,
          ),
        ),
      );
      final firstChoice = find.bySemanticsLabel('Option 1');
      expect(firstChoice, findsOneWidget);
      final node = tester.getSemantics(firstChoice);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isSelected, Tristate.isFalse);
      await tester.tap(find.text('Option 1'));
      expect(selected, isNull);
      semantics.dispose();
    },
  );

  testWidgets('six options fit a wide projector layout', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final question = PublicQuestion.fromJson({
      ...base,
      'options': List.generate(
        6,
        (i) => {'option_id': 'opt-${i + 1}', 'text': 'Option ${i + 1}'},
      ),
    });
    await tester.pumpWidget(
      app(QuestionCard(question: question, onAnswer: (_) {})),
    );
    expect(find.text('Option 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
