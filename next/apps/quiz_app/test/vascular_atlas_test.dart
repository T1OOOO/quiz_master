import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/vascular_atlas.dart';

Map<String, dynamic> _record(
  String id,
  String name, {
  required String vesselClass,
  required String circuit,
  String region = 'thorax',
}) => {
  'id': id,
  'name_ru': name,
  'name_en': id,
  'vascular_class': vesselClass,
  'circuits': [circuit],
  'region': region,
  'position_ru': 'Расположение $name',
  'function_ru': 'Роль $name',
  'source_ids': ['openstax'],
  'facts': [
    {'text_ru': 'Факт $name'},
  ],
};

final _fixture = <String, dynamic>{
  'schema_version': 'qm-organ-atlas/v1',
  'sources': [
    {
      'id': 'openstax',
      'title': 'OpenStax',
      'url': 'https://openstax.org/example',
    },
  ],
  'organs': [
    _record('aorta', 'Аорта', vesselClass: 'artery', circuit: 'systemic'),
    _record(
      'carotid',
      'Сонные артерии',
      vesselClass: 'artery',
      circuit: 'systemic',
      region: 'neck',
    ),
    _record(
      'subclavian',
      'Подключичные артерии',
      vesselClass: 'artery',
      circuit: 'systemic',
    ),
    _record(
      'renal_arteries',
      'Почечные артерии',
      vesselClass: 'artery',
      circuit: 'systemic',
    ),
    _record(
      'pulmonary_arteries',
      'Лёгочные артерии',
      vesselClass: 'artery',
      circuit: 'pulmonary',
    ),
    _record(
      'vena_cava',
      'Верхняя полая вена',
      vesselClass: 'vein',
      circuit: 'systemic',
    ),
  ],
};

Map<String, dynamic> _copyFixture() =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(_fixture)) as Map);

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        'assets/quizipedia/vascular-display.png': [
          {'asset': 'assets/quizipedia/vascular-display.png'},
        ],
      })!;
    }
    if (key == 'assets/quizipedia/vascular-display.png') {
      return ByteData.sublistView(
        Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLwYAAAAABJRU5ErkJggg==',
          ),
        ),
      );
    }
    throw FlutterError('No binary $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key != vascularAtlasAsset) throw FlutterError('Unexpected $key');
    return jsonEncode(_fixture);
  }
}

void main() {
  test('three source-linked study fields are generated per vessel', () {
    final atlas = VascularAtlas.fromJson(_fixture);
    final facts = vascularStudyFacts(atlas.records, atlas.sources);
    expect(facts, hasLength(18));
    expect(facts.map((fact) => fact.fieldPath).toSet(), {
      'position',
      'function',
      'fact',
    });
    expect(facts.map((fact) => fact.nameRu).toSet(), hasLength(6));
    expect(facts.first.id, 'vascular:aorta:position');
    expect(
      facts.every((fact) => fact.sources.single.url.startsWith('https://')),
      isTrue,
    );
  });

  test('rejects invalid source data before a vessel page is shown', () {
    final malformedUrl = _copyFixture();
    (malformedUrl['sources'] as List).first['url'] = 'http://example.test';
    expect(() => VascularAtlas.fromJson(malformedUrl), throwsFormatException);

    final duplicateRecord = _copyFixture();
    (duplicateRecord['organs'] as List).add(
      Map<String, dynamic>.from((duplicateRecord['organs'] as List).first),
    );
    expect(
      () => VascularAtlas.fromJson(duplicateRecord),
      throwsFormatException,
    );

    final unresolvedSource = _copyFixture();
    (unresolvedSource['organs'] as List).first['source_ids'] = ['missing'];
    expect(
      () => VascularAtlas.fromJson(unresolvedSource),
      throwsFormatException,
    );
  });

  testWidgets('filters a finite vascular list and opens Russian details', (
    tester,
  ) async {
    final bundle = _Bundle();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: MaterialApp(home: VascularAtlasPage(bundle: bundle)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('не полный перечень'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    final veins = find.byKey(const Key('vascular-route-systemic-veins'));
    await tester.ensureVisible(veins);
    await tester.tap(veins);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Найдено: 1'), findsOneWidget);
    expect(find.byKey(const Key('vascular-vena_cava')), findsOneWidget);
    expect(find.byKey(const Key('vascular-aorta')), findsNothing);

    final venaCava = find.byKey(const Key('vascular-vena_cava'));
    await tester.ensureVisible(venaCava);
    await tester.tap(venaCava);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vascular-details')), findsOneWidget);
    expect(find.text('Расположение Верхняя полая вена'), findsOneWidget);
    expect(find.text('Факт Верхняя полая вена'), findsOneWidget);
  });

  testWidgets('body-region marker filters only records assigned to that area', (
    tester,
  ) async {
    final bundle = _Bundle();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: MaterialApp(home: VascularAtlasPage(bundle: bundle)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('схема упрощена'), findsOneWidget);
    final neck = find.byKey(const Key('anatomy-marker-neck'));
    await tester.ensureVisible(neck);
    await tester.tap(neck);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Найдено: 1'), findsOneWidget);
    expect(find.byKey(const Key('vascular-carotid')), findsOneWidget);
    expect(find.byKey(const Key('vascular-aorta')), findsNothing);
  });
}
