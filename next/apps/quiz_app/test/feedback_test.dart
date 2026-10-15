import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('map footer stays clear of feedback at ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(right: 24, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const ProviderScope(
            child: QuizApp(
              initialLocation: '/quizipedia',
              defaultLocale: Locale('ru'),
            ),
          ),
        );
        final builder = tester.widget<FutureBuilder<QuizipediaCatalog>>(
          find.byWidgetPredicate(
            (widget) => widget is FutureBuilder<QuizipediaCatalog>,
          ),
        );
        await builder.future!.timeout(const Duration(seconds: 5));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Карта и флаги'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('map-country-search')));
      await tester.tap(find.byKey(const Key('map-country-search')));
      await tester.pumpAndSettle();
      const name = 'Французские Южные и Антарктические территории';
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, name));
      await tester.pumpAndSettle();
      final footerName = find.descendant(
        of: find.byKey(const Key('map-details')),
        matching: find.text(name),
      );
      await tester.ensureVisible(footerName);
      await tester.pumpAndSettle();
      final feedback = find.byType(FloatingActionButton);
      expect(feedback, findsOneWidget);
      expect(
        tester.getRect(footerName).overlaps(tester.getRect(feedback)),
        isFalse,
        reason: 'The selected country must remain readable beside feedback.',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('global feedback button is available on the library route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [discoveryCatalogProvider.overrideWith((ref) async => [])],
        child: const QuizApp(
          initialLocation: '/library',
          defaultLocale: Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Send feedback'), findsOneWidget);
    // Root-builder overlays can trigger Web focus traversal before layout.
    expect(
      tester
          .element(find.byTooltip('Send feedback'))
          .findAncestorWidgetOfExactType<Navigator>(),
      isNotNull,
    );
    await tester.tap(find.byTooltip('Send feedback'));
    // Exercise the bounded screenshot timeout in the test clock.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Feedback'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback'), findsNothing);
  });

  testWidgets('operator page has no feedback capture button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuizApp(
          initialLocation: '/feedback',
          defaultLocale: Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Send feedback'), findsNothing);
    expect(find.text('Operator token'), findsOneWidget);
  });

  testWidgets('failed send keeps text and reuses request id on retry', (
    tester,
  ) async {
    final api = _RetryFeedbackApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizApiProvider.overrideWithValue(api),
          discoveryCatalogProvider.overrideWith((ref) async => []),
        ],
        child: const QuizApp(
          initialLocation: '/library?secret=hidden',
          defaultLocale: Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send feedback'));
    // Exercise the bounded screenshot timeout in the test clock.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'A question has a typo');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not send'), findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      'A question has a typo',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(api.payloads.length, 2);
    expect(api.payloads[0]['request_id'], api.payloads[1]['request_id']);
    expect((api.payloads[0]['context'] as Map)['route'], '/library');
    expect(api.payloads[0].containsKey('screenshot'), isFalse);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Thank you for your feedback'), findsOneWidget);
  });
}

class _RetryFeedbackApi extends QuizApiClient {
  _RetryFeedbackApi() : super(baseUri: Uri.parse('http://127.0.0.1:8080'));
  final payloads = <Map<String, Object>>[];
  @override
  Future<void> submitReport(Map<String, Object> payload) async {
    payloads.add(Map.of(payload));
    if (payloads.length == 1) {
      throw const ApiClientException('network', retryable: true);
    }
  }
}
