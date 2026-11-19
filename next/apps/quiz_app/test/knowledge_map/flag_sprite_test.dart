import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:quiz_app/knowledge_map/flag_sprite.dart';

void main() {
  test('palette flag becomes 8-bit RGBA with four bytes per pixel', () {
    final flags =
        jsonDecode(
              File('assets/quizipedia/country_flag_images.json')
                  .readAsStringSync(),
            )['flags']
            as Map<String, dynamic>;
    final bytes = normalizeFlagSprite(base64Decode(flags['AE'] as String));
    final decoded = image.decodePng(bytes)!;
    expect(decoded.format, image.Format.uint8);
    expect(decoded.numChannels, 4);
    expect(decoded.getBytes().length, decoded.width * decoded.height * 4);
    expect(decoded.width, 160);
    expect(decoded.height, 80);
  });
}
