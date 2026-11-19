import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_map/atlas_search_dialog.dart';

void main() {
  testWidgets(
    'search filters countries, capitals and places and closes on selection',
    (tester) async {
      AtlasSearchEntry? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showAtlasSearch(
                  context,
                  entries: const [
                    AtlasSearchEntry(
                      kind: 'country',
                      id: 'FR',
                      name: 'France',
                      detail: 'Country',
                    ),
                    AtlasSearchEntry(
                      kind: 'capital',
                      id: 'FR',
                      name: 'Paris',
                      detail: 'Capital',
                    ),
                    AtlasSearchEntry(
                      kind: 'place',
                      id: 'Eiffel',
                      name: 'Eiffel Tower',
                      detail: 'Place',
                    ),
                  ],
                  russian: false,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pari');
      await tester.pumpAndSettle();
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('France'), findsNothing);
      await tester.tap(find.text('Paris'));
      await tester.pumpAndSettle();
      expect(selected?.kind, 'capital');
      expect(find.byType(Dialog), findsNothing);
    },
  );
  testWidgets('Escape closes search', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAtlasSearch(context, entries: const [], russian: false),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
  testWidgets('empty prompt, Russian spelling and ranking', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAtlasSearch(
              context,
              russian: true,
              entries: const [
                AtlasSearchEntry(
                  kind: 'place',
                  id: '1',
                  name: 'Башня',
                  detail: 'Орёл',
                ),
                AtlasSearchEntry(
                  kind: 'country',
                  id: '2',
                  name: 'Орёл',
                  detail: 'Страна',
                ),
                AtlasSearchEntry(
                  kind: 'capital',
                  id: '3',
                  name: 'Орёл-Север',
                  detail: 'Столица',
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Начните вводить название'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'орел');
    await tester.pumpAndSettle();
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title as Text).data, 'Орёл');
    expect((tiles[1].title as Text).data, 'Орёл-Север');
    expect((tiles[2].title as Text).data, 'Башня');
    expect(tiles.every((tile) => tile.leading is Icon), isTrue);
    await tester.enterText(find.byType(TextField), 'несуществующее');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });
}
