import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/belief_atlas.dart';
import 'package:quiz_app/brand_atlas.dart';
import 'package:quiz_app/food_atlas.dart';
import 'package:quiz_app/knowledge_atlas.dart';
import 'package:quiz_app/music_learning.dart';
import 'package:quiz_app/organ_atlas.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets(
    'global feedback has a reserved footer outside learning content',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const ProviderScope(
            child: QuizApp(
              initialLocation: '/quizipedia',
              defaultLocale: Locale('ru'),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await tester.pumpAndSettle();
      final content = find.byType(QuizipediaPage);
      final feedback = find.byTooltip('Отправить отзыв');
      expect(
        tester.getRect(content).bottom,
        lessThanOrEqualTo(tester.getRect(feedback).top),
      );
    },
  );
  final pages = <String, Widget Function()>{
    'index': () => const QuizipediaPage(),
    'food': () => const FoodAtlasPage(),
    'brands': () => const BrandAtlasPage(),
    'music': () => const MusicLearningPage(),
    'organs': () => const OrganAtlasPage(),
    'greek': () => const BeliefAtlasPage(),
    'religions': () => const BeliefAtlasPage(initialSection: 'religions'),
    'history': () => const KnowledgeAtlasPage(section: 'history'),
    'works': () => const KnowledgeAtlasPage(section: 'works'),
    'people': () => const KnowledgeAtlasPage(section: 'people'),
  };
  for (final entry in pages.entries) {
    testWidgets('${entry.key} fits a narrow phone with enlarged Russian text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: entry.value(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 3; i++) {
        final scroll = find.byType(Scrollable).hitTestable().first;
        await tester.drag(scroll, const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
