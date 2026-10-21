import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/quizipedia.dart';

void main() {
  testWidgets('flag markers load only visible individual assets', (
    tester,
  ) async {
    late ByteData manifest;
    late ByteData flag;
    await tester.runAsync(() async {
      manifest = await rootBundle.load('AssetManifest.bin');
      flag = await rootBundle.load('assets/quizipedia/flag-fr.png');
    });
    final requests = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      requests.add(key);
      if (key == 'AssetManifest.bin') return manifest;
      if (key.startsWith('assets/quizipedia/flag-')) return flag;
      return null;
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final features = <QuizipediaFeature>[
      for (var row = 0; row < 4; row++)
        for (var column = 0; column < 6; column++)
          QuizipediaFeature(
            id: 'F$row$column',
            nameEn: 'Flag $row$column',
            nameRu: 'Флаг $row$column',
            polygons: [
              [
                [
                  QuizipediaPoint(column / 6 + .01, row / 4 + .01),
                  QuizipediaPoint((column + 1) / 6 - .01, row / 4 + .01),
                  QuizipediaPoint((column + 1) / 6 - .01, (row + 1) / 4 - .01),
                  QuizipediaPoint(column / 6 + .01, (row + 1) / 4 - .01),
                  QuizipediaPoint(column / 6 + .01, row / 4 + .01),
                ],
              ],
            ],
          ),
    ];
    Widget map({required bool flags}) => MaterialApp(
      home: SizedBox(
        width: 320,
        height: 180,
        child: QuizipediaWorldMap(
          features: features,
          controller: TransformationController(),
          onSelect: (_) {},
          showFlags: flags,
          capitalPoints: {
            for (var row = 0; row < 4; row++)
              for (var column = 0; column < 6; column++)
                'F$row$column': Offset((column + .5) / 6, (row + .5) / 4),
          },
          capitalLabels: {
            for (final feature in features) feature.id: 'Capital ${feature.id}',
          },
          overlayLabels: {
            for (final feature in features) feature.id: feature.nameEn,
          },
        ),
      ),
    );

    await tester.pumpWidget(map(flags: false));
    await tester.pumpAndSettle();
    expect(
      requests.where((key) => key.startsWith('assets/quizipedia/flag-')),
      isEmpty,
    );

    requests.clear();
    await tester.pumpWidget(map(flags: true));
    await tester.pumpAndSettle();
    expect(
      requests,
      isNot(contains('assets/quizipedia/country_flag_images.json')),
    );
    final individual = requests
        .where((key) => key.startsWith('assets/quizipedia/flag-'))
        .toSet();
    expect(individual, isNotEmpty);
    expect(individual.length, lessThanOrEqualTo(8));
    final visibleFlags = [
      for (final feature in features)
        if (find
            .byKey(Key('map-country-flag-${feature.id.toLowerCase()}'))
            .evaluate()
            .isNotEmpty)
          feature.id,
    ];
    expect(
      visibleFlags,
      isNotEmpty,
      reason: 'Capital dots must not reserve every flag label at world scale.',
    );
  });
}
