import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/waterways_models.dart';
import 'package:quiz_app/quizipedia.dart';

Map<String, dynamic> shape() => {
  'id': 'lake',
  'name_ru': 'Озеро',
  'name_en': 'Lake',
  'kind': 'lake',
  'anchor': [.2, .2],
  'polygons': [
    [
      [
        [.1, .1],
        [.9, .1],
        [.9, .9],
        [.1, .9],
        [.1, .1],
      ],
      [
        [.3, .3],
        [.7, .3],
        [.7, .7],
        [.3, .7],
        [.3, .3],
      ],
    ],
  ],
  'lines': [],
};
Map<String, dynamic> atlas(List<dynamic> rows) => {
  'schema_version': 'qm-waterways/v1',
  'source_url': 'https://www.naturalearthdata.com/',
  'features': rows,
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('water polygons preserve holes and reject malformed geometry', () {
    final data = WaterAtlas.fromJson(atlas([shape()]));
    expect(data.features.single.contains(const WaterPoint(.2, .2)), isTrue);
    expect(data.features.single.contains(const WaterPoint(.5, .5)), isFalse);
    final bad = shape();
    bad['anchor'] = [double.nan, .2];
    expect(() => WaterAtlas.fromJson(atlas([bad])), throwsFormatException);
    final open = shape();
    open['polygons'] = [
      [
        [
          [.1, .1],
          [.9, .1],
          [.9, .9],
          [.1, .9],
        ],
      ],
    ];
    expect(() => WaterAtlas.fromJson(atlas([open])), throwsFormatException);
    expect(
      () => WaterAtlas.fromJson(atlas([shape(), shape()])),
      throwsFormatException,
    );
    expect(
      () => WaterAtlas.fromJson({'schema_version': 'other', 'features': []}),
      throwsFormatException,
    );
  });
  test(
    'source geometry has63 unique Russian objects and real interior labels',
    () async {
      final data = await WaterAtlas.load();
      expect(data.features, hasLength(63));
      expect(data.features.where((f) => f.kind == 'river'), hasLength(12));
      expect(data.features.where((f) => f.kind == 'lake'), hasLength(24));
      expect(data.features.where((f) => f.kind == 'marine'), hasLength(27));
      expect(data.features.map((f) => f.nameRu).toSet(), hasLength(63));
      final catalog = QuizipediaCatalog.fromJson(
        jsonDecode(
          await rootBundle.loadString('assets/quizipedia/catalog.json'),
        ) as Map<String, dynamic>,
      );
      for (final feature in data.features) {
        expect(RegExp('[А-Яа-яЁё]').hasMatch(feature.nameRu), isTrue);
        expect(
          feature.contains(feature.anchor),
          isTrue,
          reason: feature.nameRu,
        );
        if (feature.kind == 'marine') {
          expect(
            catalog.countries.any(
              (c) => c.contains(
                QuizipediaPoint(feature.anchor.x, feature.anchor.y),
              ),
            ),
            isFalse,
            reason: feature.nameRu,
          );
        }
      }
      expect(
        data.features.singleWhere((f) => f.id == 'Q5413').lines.length,
        greaterThanOrEqualTo(2),
      );
    },
  );
}
