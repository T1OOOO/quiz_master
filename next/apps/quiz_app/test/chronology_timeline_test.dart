import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/chronology_timeline.dart';

void main() {
  testWidgets('chronology sorts dates, selects entries and zooms on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(361, 738);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChronologyTimeline(
            entries: const [
              ChronologyEntry(
                id: 'late',
                year: 2000,
                date: '2000',
                title: 'Позднее',
              ),
              ChronologyEntry(
                id: 'early',
                year: -500,
                date: '500 до н. э.',
                title: 'Ранее',
              ),
            ],
            onSelected: (id) => chosen = id,
          ),
        ),
      ),
    );
    expect(find.text('500 до н. э.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chronology-entry-early')));
    expect(chosen, 'early');
    final before = tester
        .getSize(find.byKey(const Key('chronology-entry-early')))
        .width;
    await tester.tap(find.byTooltip('Увеличить шкалу'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('chronology-entry-early'))).width,
      greaterThan(before),
    );
    expect(tester.takeException(), isNull);
  });
}
