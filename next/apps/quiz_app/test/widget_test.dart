import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('shows the localized quiz catalog home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));

    expect(find.text('Quiz catalog'), findsOneWidget);
  });

  testWidgets('switches catalog labels between English and Russian', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));

    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Каталог викторин'), findsOneWidget);

    await tester.tap(find.byTooltip('English'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz catalog'), findsOneWidget);
  });

  testWidgets('offers light dark and system theme controls', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));

    await tester.tap(find.byTooltip('Light theme'));
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.byTooltip('System theme'));
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('gallery route and history survive locale and theme changes', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: QuizApp()));
    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;

    await tester.tap(find.text('Open gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Public fixture gallery'), findsOneWidget);

    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Галерея публичных примеров'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    expect(find.text('Галерея публичных примеров'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      same(router),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Каталог викторин'), findsOneWidget);
  });

  testWidgets('deep links show join admission boundary and back returns home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuizApp(
          initialLocation: '/join/0123456789abcdef0123456789abcdef',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('admission-only'), findsOneWidget);

    await tester.tap(find.byTooltip('Русский'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('0123456789abcdef0123456789abcdef'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.light_mode));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('0123456789abcdef0123456789abcdef'),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Каталог викторин'), findsOneWidget);
  });
}
