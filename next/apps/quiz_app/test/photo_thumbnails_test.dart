import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/photo_thumbnails.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('thumbnail parser rejects invalid payloads', () {
    for (final value in [
      <String, dynamic>{},
      {
        'schema_version': 'qm-landmark-thumbnails/v1',
        'photos': {'x': '!!!'},
      },
      {
        'schema_version': 'qm-landmark-thumbnails/v1',
        'photos': {'x': ''},
      },
    ]) {
      expect(() => PhotoThumbnails.fromJson(value), throwsFormatException);
    }
  });
  test('all36 photos have small decodable local previews', () async {
    final text = await rootBundle.loadString(
      'assets/quizipedia/landmark_thumbnails.json',
    );
    expect(utf8.encode(text).length, lessThan(500000));
    final thumbs = PhotoThumbnails.fromJson(jsonDecode(text));
    final data = jsonDecode(
      await rootBundle.loadString('assets/quizipedia/catalog.json'),
    ) as Map;
    final ids = (data['landmarks'] as List).map((r) => r['id']).toSet();
    expect(thumbs.photos.keys.toSet(), ids);
    for (final bytes in thumbs.photos.values) {
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final image = (await codec.getNextFrame()).image;
        expect(image.width, lessThanOrEqualTo(160));
        expect(image.height, lessThanOrEqualTo(160));
        image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });
}
