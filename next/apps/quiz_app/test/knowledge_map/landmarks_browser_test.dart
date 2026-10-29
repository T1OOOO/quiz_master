import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/landmarks_browser.dart';

void main() {
  testWidgets('search filters places by name or location', (tester) async {
    final features = [
      {
        'properties': {
          'id': 'a',
          'name_ru': 'Эйфелева башня',
          'name_en': 'Eiffel Tower',
          'city_ru': 'Париж',
          'city_en': 'Paris',
        },
      },
      {
        'properties': {
          'id': 'b',
          'name_ru': 'Вади-Рам',
          'name_en': 'Wadi Rum',
          'city_ru': 'Иордания',
          'city_en': 'Jordan',
        },
      },
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandmarksBrowser(
            features: features,
            category: 'all',
            russian: true,
            onCategory: (_) {},
            onSelect: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    expect(find.text('Вади-Рам'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ПАРИЖ');
    await tester.pumpAndSettle();
    expect(find.text('Эйфелева башня'), findsOneWidget);
    expect(find.text('Вади-Рам'), findsNothing);
    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('Места не найдены'), findsOneWidget);
  });
}
