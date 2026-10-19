import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/l10n/app_localizations.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('mobile contents removes technical section numbers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpArticle(
      tester,
      _module(
        articleMarkdown: '# Урок\n\n## 1. Главный факт\n\nТекст.\n\n## Проверьте себя\n\nВопросы.',
      ),
    );

    final contents = find.byKey(const Key('study-contents'));
    expect(
      find.descendant(of: contents, matching: find.text('Главный факт')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: contents, matching: find.text('1. Главный факт')),
      findsNothing,
    );
  });

  testWidgets('article identifies quizzes that check the material', (
    tester,
  ) async {
    await _pumpArticle(tester, _module());

    expect(find.text('Викторины по материалу'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Проверка по теме'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Проверка по теме'), findsOneWidget);
  });

  testWidgets('missing study image keeps an accessible article fallback', (
    tester,
  ) async {
    await _pumpArticle(
      tester,
      _module(
        articleMarkdown: '# Урок\n\n![Схема для запоминания](resource:assets/study/missing.png)',
      ),
    );

    expect(find.byKey(const Key('study-image-fallback')), findsOneWidget);
    expect(find.text('Схема для запоминания'), findsOneWidget);
  });
}

Future<void> _pumpArticle(WidgetTester tester, StudyModule module) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studyModulesProvider.overrideWith((ref) async => [module]),
        discoveryCatalogProvider.overrideWith(
          (ref) async => [
            const CatalogPack(
              'material-check',
              'Проверка по теме',
              'Вопросы, связанные с материалом',
              'Тема',
              20,
            ),
          ],
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: const StudyArticlePage(moduleId: 'lesson'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

StudyModule _module({String? articleMarkdown}) => StudyModule(
  id: 'lesson',
  title: 'Учебный материал',
  description: 'Короткое объяснение.',
  category: 'Тема',
  readingMinutesEstimate: 2,
  articleMarkdown: articleMarkdown ?? '# Урок\n\n## Основной факт\n\nТекст.',
  objectives: const [],
  sourceQuizIds: const ['material-check'],
  sources: const [],
  questions: const [],
);
