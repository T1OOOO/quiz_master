import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  test(
    'notation font is an on-demand asset, absent from startup fonts',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final fonts =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      expect(fonts.where((row) => row['family'] == 'Bravura'), isEmpty);
      expect(
        (await rootBundle.load('assets/fonts/Bravura.otf')).lengthInBytes,
        greaterThan(800000),
      );
    },
  );
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
      expect(find.byType(FutureBuilder<QuizipediaCatalog>), findsNothing);
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Music: notes, signs and instruments'),
      200,
    );
    expect(find.text('Music: notes, signs and instruments'), findsOneWidget);
  });
}
