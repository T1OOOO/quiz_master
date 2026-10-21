import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/chronology_timeline.dart';

void main() {
  for (final textScale in [1.0, 1.6]) {
    testWidgets('dates keep one continuous timeline at text scale $textScale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ChronologyTimeline(
                  selectedId: 'odyssey',
                  entries: const [
                    ChronologyEntry(
                      id: 'odyssey',
                      year: -800,
                      date: 'около 800 до н. э.–700 до н. э.',
                      title: '«Одиссея»',
                    ),
                    ChronologyEntry(
                      id: 'comedy',
                      year: 1308,
                      date: 'около 1308–1321',
                      title: '«Божественная комедия»',
                    ),
                  ],
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      void checkLine() {
        final selected = tester.getCenter(
          find.byIcon(Icons.radio_button_checked),
        );
        final other = tester.getCenter(find.byIcon(Icons.circle));
        expect(
          selected.dy,
          closeTo(other.dy, .1),
          reason: 'Wrapping dates and selection must not shift the time axis.',
        );
        expect(tester.takeException(), isNull);
      }

      checkLine();
      await tester.tap(find.byTooltip('Уменьшить шкалу'));
      await tester.pumpAndSettle();
      checkLine();
      await tester.tap(find.byTooltip('Увеличить шкалу'));
      await tester.pumpAndSettle();
      checkLine();
    });
  }
}
