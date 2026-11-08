import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/periodic_elements.dart';
import 'package:quiz_app/periodic_table.dart';

Future<void> pumpTable(
  WidgetTester tester, {
  Size size = const Size(1280, 800),
  Locale locale = const Locale('en'),
  Widget home = const PeriodicTablePage(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// Centre of an element's cell in global coordinates.
Offset cellCenter(
  WidgetTester tester,
  int number, {
  Key grid = const Key('periodic-grid'),
}) {
  final rect = tester.getRect(find.byKey(grid));
  final geometry = PeriodicGridGeometry.fit(rect.size);
  final e = elementByNumber(number);
  return rect.topLeft + geometry.cellRect(e.gridRow, e.gridColumn).center;
}

Future<void> tapCell(
  WidgetTester tester,
  int number, {
  Key grid = const Key('periodic-grid'),
}) async {
  await tester.tapAt(cellCenter(tester, number, grid: grid));
  await tester.pumpAndSettle();
}

/// The semantics node of one cell, found by its label.
SemanticsNode? cellSemantics(WidgetTester tester, String label) {
  final root = tester.getSemantics(
    find.descendant(
      of: find.byKey(const Key('periodic-grid')),
      matching: find.byType(CustomPaint),
    ),
  );
  SemanticsNode? found;
  void visit(SemanticsNode node) {
    if (node.label == label) found = node;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return found;
}

void main() {
  group('element data', () {
    test('table includes 118 distinct numbered elements', () {
      expect(periodicElements.length, 118);
      expect(periodicElements.map((e) => e.number).toSet().length, 118);
    });

    test('grid positions are unique and within the 18-column layout', () {
      final cells = periodicElements.map((e) => (e.gridRow, e.gridColumn));
      expect(cells.toSet().length, 118);
      for (final e in periodicElements) {
        expect(e.gridColumn, inInclusiveRange(0, 17));
        expect(e.gridRow, inInclusiveRange(0, 8));
      }
      final iron = elementByNumber(26);
      expect((iron.period, iron.group, iron.block), (4, 8, ElementBlock.d));
      expect(elementByNumber(2).group, 18);
      expect(elementByNumber(64).group, isNull);
      expect(elementByNumber(64).period, 6);
      expect(elementByNumber(92).block, ElementBlock.f);
    });

    test('electron configurations account for every electron', () {
      const shells = {
        'He': 2,
        'Ne': 10,
        'Ar': 18,
        'Kr': 36,
        'Xe': 54,
        'Rn': 86,
      };
      for (final e in periodicElements) {
        var total = 0;
        for (final part in e.electronConfiguration.split(' ')) {
          final core = RegExp(r'^\[(\w+)\]$').firstMatch(part);
          if (core != null) {
            total += shells[core.group(1)]!;
            continue;
          }
          final orbital = RegExp(r'^\d[spdf](\d+)$').firstMatch(part);
          expect(orbital, isNotNull, reason: '${e.symbol}: $part');
          total += int.parse(orbital!.group(1)!);
        }
        expect(total, e.number, reason: e.symbol);
      }
    });

    test('states and metal kinds follow the PubChem data', () {
      expect(elementByNumber(1).state, MatterState.gas);
      expect(elementByNumber(35).state, MatterState.liquid);
      expect(elementByNumber(80).state, MatterState.liquid);
      expect(elementByNumber(26).state, MatterState.solid);
      expect(elementByNumber(118).statePredicted, isTrue);
      expect(elementByNumber(14).metalKind, MetalKind.metalloid);
      expect(elementByNumber(17).metalKind, MetalKind.nonmetal);
      expect(elementByNumber(79).metalKind, MetalKind.metal);
    });

    test('search ranks exact symbol and number matches first', () {
      expect(searchElements('Fe').first.symbol, 'Fe');
      expect(searchElements('26').first.symbol, 'Fe');
      expect(searchElements('желез').first.symbol, 'Fe');
      expect(searchElements('gold').first.symbol, 'Au');
      expect(searchElements('o').first.symbol, 'O');
      expect(searchElements('zzz'), isEmpty);
    });

    test('grid navigation skips empty cells and stops at the edges', () {
      final hydrogen = elementByNumber(1);
      expect(neighborElement(hydrogen, GridDirection.right)?.symbol, 'He');
      expect(neighborElement(hydrogen, GridDirection.left), isNull);
      expect(neighborElement(hydrogen, GridDirection.down)?.symbol, 'Li');
      expect(
        neighborElement(elementByNumber(20), GridDirection.up)?.symbol,
        'Mg',
      );
      expect(
        neighborElement(elementByNumber(56), GridDirection.right)?.symbol,
        'Hf',
      );
    });
  });

  group('table page', () {
    testWidgets('desktop shows the whole table and a side panel on selection', (
      tester,
    ) async {
      await pumpTable(tester);
      expect(find.byKey(const Key('periodic-grid')), findsOneWidget);
      expect(find.text('Select an element in the table'), findsOneWidget);
      final handle = tester.ensureSemantics();
      await tester.pump();
      final iron = cellSemantics(tester, 'Fe, iron, 26');
      expect(iron, isNotNull);
      expect(iron!.flagsCollection.isButton, isTrue);
      expect(cellSemantics(tester, 'Og, oganesson, 118'), isNotNull);
      handle.dispose();
      await tapCell(tester, 26);
      expect(find.text('Iron'), findsOneWidget);
      expect(find.text('Железо · № 26'), findsOneWidget);
      expect(find.text('[Ar] 3d6 4s2'), findsOneWidget);
      expect(find.textContaining('Period 4'), findsOneWidget);
      expect(find.textContaining('Group 8'), findsOneWidget);
    });

    testWidgets('search opens an element by symbol and shows its number', (
      tester,
    ) async {
      await pumpTable(tester);
      await tester.enterText(find.byKey(const Key('periodic-search')), 'Fe');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('match-26')));
      await tester.pumpAndSettle();
      expect(find.text('Iron'), findsOneWidget);
      expect(find.textContaining('№ 26'), findsWidgets);
    });

    testWidgets('arrow keys move the cursor and Enter opens the element', (
      tester,
    ) async {
      await pumpTable(tester);
      await tapCell(tester, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Beryllium'), findsOneWidget);
    });

    testWidgets('legend chips switch colour modes and filter', (tester) async {
      await pumpTable(tester);
      expect(find.byKey(const Key('legend-Noble gas')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mode-state')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('legend-gas')), findsOneWidget);
      await tester.tap(find.byKey(const Key('legend-gas')));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(
        find.byKey(const Key('legend-gas')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('phone opens a bottom sheet and steps between elements', (
      tester,
    ) async {
      await pumpTable(tester, size: const Size(375, 812));
      await tapCell(tester, 26);
      expect(find.byKey(const Key('selected-strip')), findsOneWidget);
      expect(find.text('Iron'), findsOneWidget);
      await tester.tap(find.byTooltip('Details'));
      await tester.pumpAndSettle();
      expect(find.text('[Ar] 3d6 4s2'), findsOneWidget);
      await tester.tap(find.byTooltip('Next element').last);
      await tester.pumpAndSettle();
      expect(find.text('[Ar] 3d7 4s2'), findsOneWidget);
    });

    testWidgets('list view shows elements and filters by search', (
      tester,
    ) async {
      await pumpTable(tester, size: const Size(375, 812));
      await tester.tap(find.byTooltip('List'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('element-tile-1')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('periodic-search')), 'xen');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('element-tile-54')), findsOneWidget);
      expect(find.byKey(const Key('element-tile-1')), findsNothing);
    });

    testWidgets('Russian labels appear on the cells and in the panel', (
      tester,
    ) async {
      await pumpTable(tester, locale: const Locale('ru'));
      await tapCell(tester, 79);
      expect(find.text('Золото'), findsOneWidget);
      expect(find.text('Gold · № 79'), findsOneWidget);
      expect(find.text('известен с древности'), findsOneWidget);
    });
  });

  group('training', () {
    testWidgets('find mode marks a wrong tap and explains the answer', (
      tester,
    ) async {
      await pumpTable(
        tester,
        home: const ElementTrainingPage(initialNumber: 26, seed: 1),
      );
      expect(find.text('Iron'), findsOneWidget);
      await tapCell(tester, 27, grid: const Key('training-grid'));
      expect(find.text('Not quite.'), findsOneWidget);
      expect(find.textContaining('Fe — Iron, № 26'), findsOneWidget);
      expect(
        find.textContaining('You chose Co — Cobalt, № 27'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('training-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('training-feedback')), findsNothing);
    });

    testWidgets('name mode offers neighbours and scores a correct answer', (
      tester,
    ) async {
      await pumpTable(
        tester,
        home: const ElementTrainingPage(
          initialNumber: 26,
          initialMode: ElementTrainingMode.name,
          seed: 1,
        ),
      );
      expect(find.byKey(const Key('option-26')), findsOneWidget);
      final options = tester
          .widgetList<FilledButton>(find.byType(FilledButton))
          .where(
            (b) =>
                (b.key as ValueKey?)?.value.toString().startsWith('option-') ??
                false,
          )
          .length;
      expect(options, 6);
      await tester.tap(find.byKey(const Key('option-26')));
      await tester.pumpAndSettle();
      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Score: 1 / 1'), findsOneWidget);
    });

    testWidgets('phone shows four options', (tester) async {
      await pumpTable(
        tester,
        size: const Size(375, 812),
        home: const ElementTrainingPage(
          initialNumber: 8,
          initialMode: ElementTrainingMode.name,
          seed: 2,
        ),
      );
      final options = tester
          .widgetList<FilledButton>(find.byType(FilledButton))
          .where(
            (b) =>
                (b.key as ValueKey?)?.value.toString().startsWith('option-') ??
                false,
          )
          .length;
      expect(options, 4);
      expect(find.byKey(const Key('option-8')), findsOneWidget);
    });
  });
}
