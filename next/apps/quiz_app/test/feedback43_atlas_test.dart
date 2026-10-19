import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/fact_practice.dart';

void main() {
  testWidgets('a topic offers visible direct practice on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: QuizipediaPage()));
      final builder = tester.widget<FutureBuilder<QuizipediaCatalog>>(
        find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
      );
      await builder.future!;
    });
    await tester.pumpAndSettle();
    final action = find.byKey(const Key('practice-countries'));
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<FactPracticePage>(find.byType(FactPracticePage)).scope,
      'countries',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
