import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:quiz_app/knowledge_map/country_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('capital labels are compact and have transparent backgrounds', () async {
    final plain = image.decodePng(await renderCountryMarker(name: 'Vienna'))!;
    final capital = image.decodePng(
      await renderCountryMarker(name: 'Vienna', capital: true),
    )!;
    expect(capital.width, lessThan(plain.width));
    expect(capital.height, lessThan(plain.height));
    expect(capital.getPixel(0, 0).a, lessThan(5));
    expect(capital.where((p) => p.a > 0).length, greaterThan(10));
  });

  for (final landmark in [false, true]) {
    test(
      'capital and landmark labels do not render flags: landmark=$landmark',
      () async {
        final flag = image.Image(width: 12, height: 8, numChannels: 4);
        image.fill(flag, color: image.ColorRgba8(255, 0, 0, 255));
        final without = await renderCountryMarker(
          name: 'Vienna',
          capital: !landmark,
          landmark: landmark,
        );
        final withFlag = await renderCountryMarker(
          name: 'Vienna',
          capital: !landmark,
          landmark: landmark,
          flagBytes: Uint8List.fromList(image.encodePng(flag)),
        );
        expect(withFlag, orderedEquals(without));
      },
    );
  }

  test('capital marker renders a visible star without font glyphs', () async {
    final star = image.decodePng(await renderCapitalMarker())!;
    expect(star.width, 24);
    expect(star.height, 24);
    expect(
      star.where((p) => p.r > 140 && p.g < 100 && p.a > 0).length,
      greaterThan(30),
    );
  });

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

  test('long country names wrap without truncation', () async {
    final full = image.decodePng(
      await renderCountryMarker(
        name: 'Соединённое Королевство Великобритании и Северной Ирландии',
      ),
    )!;
    final truncated = image.decodePng(
      await renderCountryMarker(
        name: 'Соединённое Королевство Великобритании и Северной Ирландии',
        maxLines: 2,
      ),
    )!;
    expect(full.height, greaterThan(truncated.height));
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
      expect(withFlag.height, greaterThan(plain.height + 10));
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
        await renderCountryMarker(
          name: 'Длинное название страны ' * 12,
          maxLines: 2,
        ),
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
