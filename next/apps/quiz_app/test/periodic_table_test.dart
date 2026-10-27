import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/periodic_table.dart';

void main() {
  testWidgets('search opens an element by symbol and shows its number', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PeriodicTablePage()));
    await tester.enterText(find.byType(TextField), 'Fe');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fe').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('26'), findsWidgets);
    expect(find.textContaining('Iron'), findsWidgets);
  });

  test('table includes 118 distinct numbered elements', () {
    expect(periodicElements.length, 118);
    expect(periodicElements.map((e) => e.number).toSet().length, 118);
  });

  testWidgets('practice explains a wrong answer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PeriodicTablePage()));
    await tester.tap(find.text('Practise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('He').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('H — Hydrogen'), findsOneWidget);
  });

  testWidgets('family filter limits the element list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PeriodicTablePage()));
    await tester.tap(find.text('All families'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noble gas').last);
    await tester.pumpAndSettle();
    expect(find.text('Helium'), findsOneWidget);
    expect(find.text('Hydrogen'), findsNothing);
  });

  testWidgets('colour legend can be expanded on a phone', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PeriodicTablePage()));
    expect(find.text('Colour legend'), findsOneWidget);
    expect(find.text('Nonmetal'), findsNothing);
    await tester.tap(find.text('Colour legend'));
    await tester.pumpAndSettle();
    expect(find.text('Nonmetal'), findsOneWidget);
  });
}
