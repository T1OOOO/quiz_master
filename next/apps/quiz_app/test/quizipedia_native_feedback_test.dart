import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

Future<void> _startSkyTraining(WidgetTester tester, AssetBundle bundle) async {
  await tester.pumpWidget(MaterialApp(home: QuizipediaPage(bundle: bundle)));
  await tester.pumpAndSettle();
  final sky = find.text('J2000 constellation atlas');
  await tester.scrollUntilVisible(sky, 200);
  await tester.tap(sky);
  await tester.pumpAndSettle();
  final start = find.text('Start training');
  await tester.drag(
    find.byKey(const Key('constellation-scroll')),
    const Offset(0, -1200),
  );
  await tester.pumpAndSettle();
  await tester.tap(start);
  await tester.pump();
  await tester.pumpAndSettle();
  expect(find.text('Check'), findsOneWidget);
}

Future<void> _submitWrongSkyAnswer(WidgetTester tester) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final option = find.byType(OutlinedButton).first;
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();
    final check = find.text('Check');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();
    if (find.text('Incorrect').evaluate().isNotEmpty) return;
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
  fail('Expected a wrong answer in a ten-question round.');
}

void main() {
  testWidgets(
    'sky feedback marks all six choices and explains each loaded target',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _startSkyTraining(tester, _Bundle(_fixture()));
      await _submitWrongSkyAnswer(tester);

      expect(find.textContaining('Your answer: Name sky:'), findsOneWidget);
      expect(find.textContaining('Correct answer: Name sky:'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(4));
      final details = find.byKey(const Key('native-option-explanations'));
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: details,
          matching: find.byWidgetPredicate(
            (widget) => widget is ListTile && widget.onTap == null,
          ),
        ),
        findsNWidgets(6),
      );
      expect(find.text('Next').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Bundle extends CachingAssetBundle {
  _Bundle(this.catalog);
  final Map<String, dynamic> catalog;

  @override
  Future<ByteData> load(String key) => throw FlutterError('Unexpected $key');

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/quizipedia/catalog.json') return jsonEncode(catalog);
    throw FlutterError('Unexpected $key');
  }
}

List<List<double>> _rectangle(
  double left,
  double top,
  double right,
  double bottom,
) => [
  [left, top],
  [right, top],
  [right, bottom],
  [left, bottom],
  [left, top],
];

Map<String, dynamic> _fixture() {
  Map<String, dynamic> common(String id) => {
    'id': id,
    'name_ru': 'Название $id',
    'name_en': 'Name $id',
    'difficulty_level': 3,
    'tag_ids': ['topic:test'],
    'explanation_ru': 'Объяснение $id',
    'explanation_en': 'Explanation $id',
    'source_url': 'https://example.org/$id',
  };
  final countries = List.generate(4, (index) => 'country:$index');
  return {
    'schema_version': 'qm-quizipedia/v1',
    'credits': [
      {
        'id': 'credit',
        'attribution': 'Test author',
        'source_url': 'https://example.org',
        'license': 'CC BY',
        'license_url': 'https://example.org/license',
      },
    ],
    'countries': [
      for (var index = 0; index < countries.length; index++)
        {
          ...common(countries[index]),
          'flag': '🇦🇷',
          'polygons': [
            [_rectangle(.05 + index * .2, .2, .15 + index * .2, .4)],
          ],
        },
    ],
    'map_target_ids': countries,
    'anatomy': {
      'image_asset': 'assets/unused.png',
      'width': 200,
      'height': 300,
      'credit_id': 'credit',
      'targets': [
        for (var index = 0; index < 4; index++)
          {
            ...common('organ:$index'),
            'hotspots': [
              {'x': .2, 'y': .2, 'radius': .05},
            ],
          },
      ],
    },
    'landmarks': [
      for (var index = 0; index < 4; index++)
        {
          ...common('landmark:$index'),
          'image_asset': 'assets/unused-$index.png',
          'credit_id': 'credit',
          'country_iso2': 'FR',
          'city_ru': 'Город $index',
          'city_en': 'City $index',
        },
    ],
    'constellations': [
      for (var index = 0; index < 6; index++)
        {
          ...common('sky:$index'),
          'credit_id': 'credit',
          'stars': [
            {
              'id': 'a',
              'name': 'Alpha',
              'ra_hours': 1.0,
              'dec_degrees': 2.0,
              'magnitude': 2.0,
            },
            {
              'id': 'b',
              'name': 'Beta',
              'ra_hours': 2.0,
              'dec_degrees': 3.0,
              'magnitude': 3.0,
            },
          ],
          'lines': [
            ['a', 'b'],
          ],
        },
    ],
  };
}
