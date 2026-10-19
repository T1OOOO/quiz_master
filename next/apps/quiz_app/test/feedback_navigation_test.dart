import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('Russian phone menu opens library and study without a drawer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryCatalogProvider.overrideWith((ref) async => []),
          studyModulesProvider.overrideWith((ref) async => []),
        ],
        child: const QuizApp(initialLocation: '/library'),
      ),
    );
    await tester.pumpAndSettle();
    final menu = find.byType(NavigationBar);
    expect(menu, findsOneWidget);
    for (final label in ['Квизипедия', 'Квизы', 'Статьи']) {
      expect(
        find.descendant(of: menu, matching: find.text(label)).hitTestable(),
        findsOneWidget,
      );
    }
    await tester.tap(find.descendant(of: menu, matching: find.text('Статьи')));
    await tester.pumpAndSettle();
    expect(find.byType(StudyLibraryPage), findsOneWidget);
    await tester.tap(find.descendant(of: menu, matching: find.text('Квизы')));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
