import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  testWidgets('landmark grid and picker decode for a 2.75 DPR phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1210, 2200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late String id;
    await tester.runAsync(() async {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/quizipedia/catalog.json'),
      ) as Map<String, dynamic>;
      id = (raw['landmarks'] as List).first['id'] as String;
    });
    await tester.pumpWidget(const MaterialApp(home: QuizipediaPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Landmark photographs'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();

    final gridImage = find.descendant(
      of: find.byKey(Key('landmark-catalog-$id')),
      matching: find.byType(Image),
    );
    final gridProvider = tester.widget<Image>(gridImage).image;
    expect(gridProvider, isA<ResizeImage>());
    expect((gridProvider as ResizeImage).width, greaterThanOrEqualTo(440));
    expect(gridProvider.width, lessThanOrEqualTo(512));

    await tester.tap(find.byKey(Key('landmark-catalog-$id')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('landmark-picker')));
    await tester.pump();
    final pickerImage = find.descendant(
      of: find.byKey(Key('landmark-choice-$id')),
      matching: find.byType(Image),
    );
    final pickerProvider = tester.widget<Image>(pickerImage).image;
    expect(pickerProvider, isA<ResizeImage>());
    expect((pickerProvider as ResizeImage).width, greaterThanOrEqualTo(176));
    expect(pickerProvider.width, lessThanOrEqualTo(512));
  });
}
