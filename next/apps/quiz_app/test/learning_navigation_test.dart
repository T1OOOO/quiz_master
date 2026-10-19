import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  testWidgets(
    'Quizipedia exposes history culture and people alongside atlases',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: QuizipediaPage()));
        await tester.pump();
        final builder = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
        );
        await builder.future!;
      });
      await tester.pumpAndSettle();
      for (final name in [
        'World history',
        'Films, books and opera',
        'People and their works',
      ]) {
        await tester.scrollUntilVisible(find.text(name), 200);
        expect(find.text(name), findsOneWidget);
      }
    },
  );
}
