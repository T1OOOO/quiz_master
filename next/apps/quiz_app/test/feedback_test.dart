import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('global feedback button is available on the library route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryCatalogProvider.overrideWith((ref) async => []),
        ],
        child: const QuizApp(
          initialLocation: '/library',
          defaultLocale: Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Send feedback'), findsOneWidget);
  });
}
