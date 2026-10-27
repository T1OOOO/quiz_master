import 'dart:typed_data';

import 'package:image/image.dart' as image;

/// MapLibre's image decoder retains indexed PNG bit depth unless normalized.
Uint8List normalizeFlagSprite(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Invalid flag image');
  final rgba = decoded.convert(format: image.Format.uint8, numChannels: 4);
  return image.encodePng(rgba);
}
