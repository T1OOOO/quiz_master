import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_master/screens/home_screen.dart';

void main() {
  testWidgets('Home screen displays quiz list title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Verify that we show the logo or title
    expect(find.text('Quiz Master'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
