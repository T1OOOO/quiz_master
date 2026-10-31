import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/atlas_media.dart';

class _MediaBundle extends CachingAssetBundle {
  final requested = <String>[];
  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    if (key.endsWith('atlas_media.json')) {
      return ByteData.sublistView(
        Uint8List.fromList(
          utf8.encode(
            '['
            '{"scope":"people","id":"one","asset":"assets/quizipedia/media-one.png","source_url":"https://commons.wikimedia.org/wiki/File:One.png","attribution":"Author","license":"Public domain","license_url":"https://creativecommons.org/publicdomain/mark/1.0/"},'
            '{"scope":"countries","id":"RU","field":"capital_ru","asset":"assets/quizipedia/media-atlas-capitals-01.jpg","thumb_asset":"assets/quizipedia/media-thumb-atlas-capitals-01.jpg","atlas_asset":"assets/quizipedia/media-atlas-capitals-01.jpg","atlas_title_ru":"Столицы мира — лист 1","cell":[1,2,4,4],"source_url":"https://commons.wikimedia.org","attribution":"Quizipedia Visual Atlas","license":"CC0 1.0","license_url":"https://creativecommons.org/publicdomain/zero/1.0/"}'
            ']',
          ),
        ),
      );
    }
    throw StateError('Image deliberately unavailable');
  }
}

void main() {
  testWidgets('media metadata is shared, missing image has a usable fallback', (
    tester,
  ) async {
    final bundle = _MediaBundle();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AtlasMedia(scope: 'people', entityId: 'one', compact: true),
                AtlasMedia(scope: 'people', entityId: 'absent', compact: true),
                AtlasMedia(
                  scope: 'countries',
                  entityId: 'RU',
                  fieldPath: 'capital_ru',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      bundle.requested.where((p) => p.endsWith('atlas_media.json')),
      hasLength(1),
    );
    expect(find.byIcon(Icons.image_outlined), findsWidgets);
    expect(find.text('Визуальный атлас'), findsOneWidget);
    await tester.tap(find.text('Визуальный атлас'));
    await tester.pumpAndSettle();
    expect(find.text('Столицы мира — лист 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
