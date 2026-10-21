import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/knowledge_atlas.dart';

const _atlasKey = 'assets/quizipedia/knowledge_atlas.json';
const _mediaKey = 'assets/quizipedia/atlas_media.json';
const _firstAsset = 'assets/quizipedia/media-works-first.png';
const _secondAsset = 'assets/quizipedia/media-works-second.png';

class _WorkMediaBundle extends CachingAssetBundle {
  final requested = <String>[];
  static final _imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLQ7wAAAABJRU5ErkJggg==',
  );

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    requested.add(key);
    return switch (key) {
      _atlasKey => jsonEncode(_atlas()),
      _mediaKey => jsonEncode([
        _media('first', _firstAsset),
        _media('second', _secondAsset),
      ]),
      _ => throw StateError('Unexpected text asset: $key'),
    };
  }

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key == 'AssetManifest.bin') {
      return StandardMessageCodec().encodeMessage({
        _firstAsset: [
          {'asset': _firstAsset},
        ],
        _secondAsset: [
          {'asset': _secondAsset},
        ],
      })!;
    }
    if (key != _firstAsset && key != _secondAsset) {
      throw StateError('Unexpected binary asset: $key');
    }
    return ByteData.sublistView(_imageBytes);
  }

  @override
  Future<ImmutableBuffer> loadBuffer(String key) async {
    requested.add(key);
    if (key != _firstAsset && key != _secondAsset) {
      throw StateError('Unexpected image buffer: $key');
    }
    return ImmutableBuffer.fromUint8List(_imageBytes);
  }
}

Map<String, String> _media(String id, String asset) => {
  'scope': 'works',
  'id': id,
  'asset': asset,
  'source_url': 'https://commons.wikimedia.org/wiki/File:$id.png',
  'attribution': 'Test author',
  'license': 'Public domain',
  'license_url': 'https://commons.wikimedia.org/wiki/Commons:Public_domain',
};

Map<String, dynamic> _atlas() => {
  'schema_version': 'qm-knowledge-atlas/v1',
  'events': [],
  'works': [
    _work('first', 'First work', 'one'),
    _work('second', 'Second work', 'two'),
  ],
  'people': [_person('one', 'One', 'first'), _person('two', 'Two', 'second')],
};

Map<String, dynamic> _work(String id, String title, String creator) => {
  'id': id,
  'type': 'book',
  'year': id == 'first' ? 1900 : 1901,
  'title_ru': title,
  'title_en': title,
  'creator_ids': [creator],
  'cast': [],
  'summary_ru': 'Summary.',
  'summary_en': 'Summary.',
  'fact_ru': 'Fact.',
  'fact_en': 'Fact.',
  'source_url': 'https://example.com/$id',
};

Map<String, dynamic> _person(String id, String name, String work) => {
  'id': id,
  'name_ru': name,
  'name_en': name,
  'roles': ['writer'],
  'born': '1900',
  'bio_ru': 'Bio.',
  'bio_en': 'Bio.',
  'source_url': 'https://example.com/$id',
  'credit_work_ids': [work],
};

void main() {
  test('creator prompts keep an already quoted Russian work title single', () {
    final data = _atlas();
    data['works'] = [
      for (var index = 0; index < 6; index++)
        _work(
          'work-$index',
          index == 0 ? '«First work»' : 'Work $index',
          'person-$index',
        ),
    ];
    data['people'] = [
      for (var index = 0; index < 6; index++)
        _person('person-$index', 'Person $index', 'work-$index'),
    ];

    final question = KnowledgeAtlas.fromJson(data).questions
        .firstWhere((item) => item.workId == 'work-0');

    expect(question.promptRu, 'Кто создал произведение «First work»?');
    expect(
      question.explanationRu,
      'Person 0 связан с произведением «First work».',
    );
  });

  testWidgets('culture work media loads only after its detail is selected', (
    tester,
  ) async {
    final bundle = _WorkMediaBundle();
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: KnowledgeAtlasPage(section: 'culture', bundle: bundle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      bundle.requested.where((key) => key.contains('media-works-')),
      isEmpty,
      reason: 'The catalog list must not request work cover files.',
    );

    final firstWork = find.byKey(const Key('knowledge-work-first'));
    await tester.ensureVisible(firstWork);
    await tester.pumpAndSettle();
    await tester.tap(firstWork);
    await tester.pumpAndSettle();

    expect(find.text('First work'), findsWidgets);
    expect(bundle.requested, contains(_mediaKey));
    final cover = find.byType(Image);
    expect(cover, findsOneWidget);
    await tester.ensureVisible(cover);
    await tester.pumpAndSettle();
    expect(bundle.requested.where((key) => key == _firstAsset), hasLength(1));
    expect(bundle.requested.where((key) => key == _secondAsset), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
