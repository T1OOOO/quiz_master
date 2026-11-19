import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/country_connections.dart';
import 'package:quiz_app/knowledge_map/map_state.dart';

void main() {
  testWidgets('a neighbour shows its own area and shared river', (
    tester,
  ) async {
    const france = MapCountry(
      id: 'FR',
      nameRu: 'Франция',
      nameEn: 'France',
      neighbors: ['DE'],
    );
    const germany = MapCountry(
      id: 'DE',
      nameRu: 'Германия',
      nameEn: 'Germany',
      area: 357000,
    );
    const river = {'id': 'rhine', 'name_ru': 'Рейн', 'relation': 'flows'};
    String? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Открыть'),
              onPressed: () async {
                choice = await showCountryConnections(
                  context,
                  country: france,
                  countries: [france, germany],
                  russian: true,
                  waters: {
                    'FR': [river],
                    'DE': [river],
                  },
                  borders: {
                    'countries': {
                      'DE': {
                        'pairs': [
                          {'country_id': 'FR', 'length_km': 418},
                        ],
                      },
                    },
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.textContaining('418 км'), findsOneWidget);
    await tester.tap(find.text('Германия'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Площадь страны'), findsOneWidget);
    expect(find.text('Рейн · Река'), findsOneWidget);
    await tester.tap(find.text('Показать на карте'));
    await tester.pumpAndSettle();
    expect(choice, 'DE');
  });
}
