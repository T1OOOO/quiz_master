import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('global feedback button is available on the library route', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuizApp(initialLocation: '/library', defaultLocale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Send feedback'), findsOneWidget);
  });
}
