// Inspect the RadioListTile selection used by the current question controls.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';
import 'package:quiz_app/l10n/app_localizations.dart';

void main() {
  for (final kind in AnswerKind.values) {
    testWidgets('saved ${kind.name} answer remains visible when revisited', (
      tester,
    ) async {
      final answer = switch (kind) {
        AnswerKind.singleChoice => const SingleChoiceAnswer('b'),
        AnswerKind.multipleChoice => MultipleChoiceAnswer({'b', 'c'}),
        AnswerKind.normalizedText => const NormalizedTextAnswer(
          'сохранённый ответ',
        ),
      };
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuestionCard(
              question: PublicQuestion(
                quizId: 'quiz-review',
                id: 'question-review',
                revision: Revision(1, 'a' * 64),
                stem: 'Вопрос',
                kind: kind,
                options: [
                  for (final id in ['a', 'b', 'c', 'd'])
                    PublicOption(id: id, text: id),
                ],
              ),
              initialAnswer: answer,
              submitting: true,
              onAnswer: (_) => fail('a reviewed answer must remain read-only'),
            ),
          ),
        ),
      );
      switch (kind) {
        case AnswerKind.singleChoice:
          expect(
            tester
                .widgetList<RadioListTile<String>>(
                  find.byType(RadioListTile<String>),
                )
                .every((w) => w.groupValue == 'b'),
            isTrue,
          );
        case AnswerKind.multipleChoice:
          expect(
            tester
                .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
                .where((w) => w.value == true)
                .length,
            2,
          );
        case AnswerKind.normalizedText:
          expect(find.text('сохранённый ответ'), findsOneWidget);
      }
    });
  }
}
