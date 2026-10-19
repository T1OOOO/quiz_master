import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flag bundle preserves every original PNG byte', () {
    final dir = Directory('assets/quizipedia');
    final doc = jsonDecode(
      File('${dir.path}/country_flag_images.json').readAsStringSync(),
    ) as Map;
    expect(doc['schema_version'], 'qm-country-flag-images/v1');
    final flags = Map<String, String>.from(doc['flags'] as Map);
    final files = dir
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              RegExp(r'^flag-[a-z]{2}\.png$').hasMatch(f.uri.pathSegments.last),
        )
        .toList();
    expect(flags.length, 250);
    expect(files.length, flags.length);
    for (final f in files) {
      final id = f.uri.pathSegments.last.substring(5, 7).toUpperCase();
      expect(base64Decode(flags[id]!), f.readAsBytesSync(), reason: id);
    }
  });
}
