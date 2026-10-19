import 'dart:convert';

import 'package:flutter/services.dart';

class PhotoThumbnails {
  PhotoThumbnails._(this.photos);
  final Map<String, Uint8List> photos;
  factory PhotoThumbnails.fromJson(Object? value) {
    if (value is! Map ||
        value['schema_version'] != 'qm-landmark-thumbnails/v1' ||
        value['photos'] is! Map) {
      throw const FormatException('Invalid photograph previews');
    }
    final raw = value['photos'] as Map;
    if (raw.isEmpty || raw.length > 500) {
      throw const FormatException('Invalid preview count');
    }
    final photos = <String, Uint8List>{};
    for (final entry in raw.entries) {
      if (entry.key is! String ||
          (entry.key as String).isEmpty ||
          entry.value is! String) {
        throw const FormatException('Invalid preview entry');
      }
      final bytes = base64Decode(entry.value as String);
      if (bytes.length < 12 || bytes.length > 100000) {
        throw const FormatException('Invalid preview size');
      }
      photos[entry.key as String] = bytes;
    }
    return PhotoThumbnails._(Map.unmodifiable(photos));
  }
  static Future<PhotoThumbnails> load(AssetBundle? bundle) async {
    final text = await (bundle ?? rootBundle).loadString(
      'assets/quizipedia/landmark_thumbnails.json',
      cache: false,
    );
    if (text.length > 600000) {
      throw const FormatException('Preview bundle too large');
    }
    return PhotoThumbnails.fromJson(jsonDecode(text));
  }
}
