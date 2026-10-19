import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  test(
    'shipped music reference includes notation and instrument learning',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final raw = jsonDecode(
        await rootBundle.loadString('assets/quizipedia/music_learning.json'),
      ) as Map;
      final entries = raw['entries'] as List;
      expect(entries.length, greaterThanOrEqualTo(70));
      expect(
        entries.map((e) => e['category']).toSet(),
        containsAll([
          'notes',
          'notation',
          'rhythm',
          'dynamics',
          'tempo',
          'technique',
          'harmony',
          'instruments',
          'world',
        ]),
      );
    },
  );
  testWidgets('music learning opens from Quizipedia', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: QuizipediaPage()));
      await tester.pump();
      final future = tester.widget<FutureBuilder<QuizipediaCatalog>>(
        find.byWidgetPredicate((w) => w is FutureBuilder<QuizipediaCatalog>),
      );
      await future.future!;
    });
    await tester.pumpAndSettle();
    expect(find.text('Music: notes, signs and instruments'), findsOneWidget);
  });
}
