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
  test('all46 photos have crisp individually bounded local previews', () async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/quizipedia/catalog.json'),
    ) as Map;
    final rows = data['landmarks'] as List;
    expect(rows, hasLength(46));
    var totalBytes = 0;
    var initialGridBytes = 0;
    for (final row in rows) {
      final bytes = await rootBundle.load(row['thumbnail_asset'] as String);
      totalBytes += bytes.lengthInBytes;
      if (rows.indexOf(row) < 4) initialGridBytes += bytes.lengthInBytes;
      expect(bytes.lengthInBytes, lessThan(64 * 1024));
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final image = (await codec.getNextFrame()).image;
      expect(image.width, inInclusiveRange(240, 512));
      expect(image.height, inInclusiveRange(240, 512));
      image.dispose();
      codec.dispose();
    }
    expect(totalBytes, lessThan(1536 * 1024));
    expect(initialGridBytes, lessThan(128 * 1024));
  });
  test('legacy preview bundle remains decodable', () async {
    final text = await rootBundle.loadString(
      'assets/quizipedia/landmark_thumbnails.json',
    );
    expect(utf8.encode(text).length, lessThan(500000));
    final thumbs = PhotoThumbnails.fromJson(jsonDecode(text));
    final data = jsonDecode(
      await rootBundle.loadString('assets/quizipedia/catalog.json'),
    ) as Map;
    final ids = (data['landmarks'] as List).map((r) => r['id']).toSet();
    expect(ids, containsAll(thumbs.photos.keys));
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
