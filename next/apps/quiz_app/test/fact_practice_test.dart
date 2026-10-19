import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice.dart';
import 'package:quiz_app/fact_practice_models.dart';

void main() {
  testWidgets(
    'phone fact practice checks canonical choices and retries a mistake',
    (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final facts = [
        for (var i = 0; i < 4; i++)
          StudyFact(
            id: 'fact-$i',
            scope: 'music',
            entityId: 'entity-$i',
            nameRu: 'Инструмент $i',
            nameEn: 'Instrument $i',
            fieldPath: 'description',
            fieldRu: 'Описание',
            fieldEn: 'Description',
            valueRu: 'Описание инструмента $i',
            valueEn: 'Description of instrument $i',
            sources: const [],
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: FactPracticePage(scope: 'music', facts: facts),
        ),
      );
      await tester.pumpAndSettle();
      final question = find.byKey(const Key('fact-open-fact-0'));
      await tester.ensureVisible(question);
      await tester.tap(question);
      await tester.pumpAndSettle();
      final wrong = find.widgetWithText(
        OutlinedButton,
        'Описание инструмента 1',
      );
      await tester.ensureVisible(wrong);
      await tester.tap(wrong);
      await tester.pump();
      expect(find.text('Проверить'), findsNothing);
      expect(find.text('Пока неверно'), findsOneWidget);
      expect(
        find.textContaining('Правильный ответ: Описание инструмента 0'),
        findsOneWidget,
      );
      final finish = find.widgetWithText(FilledButton, 'Завершить');
      await tester.scrollUntilVisible(finish, 200);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(find.text('Верных ответов: 0 из 1'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Повторить ошибки'));
      await tester.pumpAndSettle();
      final correct = find.widgetWithText(
        OutlinedButton,
        'Описание инструмента 0',
      );
      await tester.ensureVisible(correct);
      await tester.tap(correct);
      await tester.pump();
      expect(find.text('Верно'), findsOneWidget);
      final done = find.widgetWithText(FilledButton, 'Завершить');
      await tester.scrollUntilVisible(done, 200);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.text('Верных ответов: 1 из 1'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Следующий раунд'));
      await tester.pumpAndSettle();
      expect(
        find.text('Что указано в разделе «Описание» для «Инструмент 0»?'),
        findsNothing,
      );
      expect(find.text('Без рейтинга · вопрос 1 из 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
