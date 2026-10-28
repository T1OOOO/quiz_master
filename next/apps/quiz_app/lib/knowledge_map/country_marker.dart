import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'flag_sprite.dart';

/// Bundled text rendering keeps Cyrillic labels independent of a glyph server.
Future<Uint8List> renderCountryMarker({
  required String name,
  Uint8List? flagBytes,
}) async {
  final text = TextPainter(
    text: TextSpan(
      text: name,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xff302b24),
        height: 1.15,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: 170);
  ui.Image? flag;
  try {
    if (flagBytes != null) {
      final codec = await ui.instantiateImageCodec(flagBytes);
      try {
        flag = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    }
    final leading = flag == null ? 0.0 : 30.0;
    final width = (text.width + leading + 16).ceil().clamp(24, 216);
    final height = (math.max(text.height, 16) + 12).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bounds = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(.5, .5, width - 1, height - 1),
      const ui.Radius.circular(5),
    );
    canvas.drawRRect(bounds, ui.Paint()..color = const Color(0xeeffffff));
    canvas.drawRRect(
      bounds,
      ui.Paint()
        ..color = const Color(0x558c8475)
        ..style = ui.PaintingStyle.stroke,
    );
    if (flag != null) {
      final scale = math.min(24 / flag.width, 16 / flag.height);
      final fw = flag.width * scale;
      final fh = flag.height * scale;
      canvas.drawImageRect(
        flag,
        ui.Rect.fromLTWH(0, 0, flag.width.toDouble(), flag.height.toDouble()),
        ui.Rect.fromLTWH(8 + (24 - fw) / 2, (height - fh) / 2, fw, fh),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }
    text.paint(canvas, ui.Offset(8 + leading, (height - text.height) / 2));
    final picture = recorder.endRecording();
    try {
      final rendered = await picture.toImage(width, height);
      try {
        final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Country label PNG encoding failed');
        return normalizeFlagSprite(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } finally {
        rendered.dispose();
      }
    } finally {
      picture.dispose();
    }
  } finally {
    flag?.dispose();
    text.dispose();
  }
}
