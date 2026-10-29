import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:quiz_app/knowledge_map/knowledge_map_page.dart';
import 'package:quiz_app/quizipedia.dart';
import 'package:quiz_app/main.dart' as app;
import 'package:go_router/go_router.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('Android launches the map and its back button opens Quizipedia', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    app.main();
    await tester.pump();
    await tester.pump();
    expect(find.byType(KnowledgeMapPage), findsOneWidget);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    expect(find.byType(QuizipediaPage), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'map preview has a standalone route outside the global navigation shell',
    () {
      final router = createRouter(initialLocation: '/atlas/map-preview');
      addTearDown(router.dispose);
      expect(
        router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
        contains('/atlas/map-preview'),
      );
    },
  );
}
