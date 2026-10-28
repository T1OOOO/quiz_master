import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:quiz_app/knowledge_map/country_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('landmark pin renders without relying on a font glyph', () async {
    final plain = image.decodePng(await renderCountryMarker(name: 'Памятник'))!;
    final pinned = image.decodePng(
      await renderCountryMarker(name: 'Памятник', landmark: true),
    )!;
    expect(pinned.width, greaterThan(plain.width));
    expect(
      pinned
          .where(
            (p) => p.r < 60 && p.g > 90 && p.g < 150 && p.b > 90 && p.b < 160,
          )
          .length,
      greaterThan(15),
    );
  });

  test('country names render as an RGBA PNG, including Cyrillic', () async {
    final bytes = await renderCountryMarker(name: 'Франция');
    final decoded = image.decodePng(bytes)!;
    expect(decoded.numChannels, 4);
    expect(decoded.format, image.Format.uint8);
    expect(decoded.width, greaterThan(30));
    expect(decoded.height, greaterThanOrEqualTo(24));
  });

  test(
    'flag retains its colors and adds room beside the country name',
    () async {
      final flag = image.Image(width: 12, height: 8, numChannels: 4);
      image.fill(flag, color: image.ColorRgba8(255, 0, 0, 255));
      final plain = image.decodePng(await renderCountryMarker(name: 'France'))!;
      final withFlag = image.decodePng(
        await renderCountryMarker(
          name: 'France',
          flagBytes: Uint8List.fromList(image.encodePng(flag)),
        ),
      )!;
      expect(withFlag.width, greaterThan(plain.width));
      expect(
        withFlag.any((pixel) => pixel.r > 220 && pixel.g < 30 && pixel.b < 30),
        isTrue,
      );
    },
  );

  test(
    'long country names stay bounded and invalid flags fail explicitly',
    () async {
      final decoded = image.decodePng(
        await renderCountryMarker(name: 'Длинное название страны ' * 12),
      )!;
      expect(decoded.width, lessThanOrEqualTo(240));
      expect(decoded.height, lessThanOrEqualTo(64));
      await expectLater(
        renderCountryMarker(
          name: 'France',
          flagBytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<Exception>()),
      );
    },
  );
}
