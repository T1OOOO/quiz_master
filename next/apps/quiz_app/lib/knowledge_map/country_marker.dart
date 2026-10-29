import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'flag_sprite.dart';

/// Bundled text rendering keeps Cyrillic labels independent of a glyph server.
Future<Uint8List> renderCountryMarker({
  required String name,
  Uint8List? flagBytes,
  bool landmark = false,
  bool wonder = false,
  bool capital = false,
  bool compact = false,
  int? maxLines,
}) async {
  final text = TextPainter(
    text: TextSpan(
      text: name,
      style: TextStyle(
        fontSize: capital ? 11 : (compact ? 13 : 16),
        fontWeight: FontWeight.w600,
        color: Color(0xff302b24),
        height: 1.15,
        shadows: capital
            ? const [Shadow(color: Color(0xfff4efd9), blurRadius: 3)]
            : null,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: compact ? 140 : 170);
  ui.Image? flag;
  try {
    if (flagBytes != null && !capital && !landmark) {
      final codec = await ui.instantiateImageCodec(flagBytes);
      try {
        flag = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    }
    final leading = landmark
        ? 20.0
        : capital && flag != null
        ? 20.0
        : 0.0;
    final width =
        (math.max(
                  text.width + leading,
                  flag != null && !capital ? (compact ? 24 : 32) : 0,
                ) +
                (capital ? 8 : (compact ? 12 : 16)))
            .ceil()
            .clamp(24, 216);
    final height =
        (math.max(text.height, capital ? 0 : 16) +
                (capital ? 8 : (compact ? 10 : 12)) +
                (flag != null && !capital ? (compact ? 20 : 26) : 0))
            .ceil();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bounds = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(.5, .5, width - 1, height - 1),
      const ui.Radius.circular(5),
    );
    if (!capital) {
      canvas.drawRRect(bounds, ui.Paint()..color = const Color(0xeeffffff));
      canvas.drawRRect(
        bounds,
        ui.Paint()
          ..color = const Color(0x558c8475)
          ..style = ui.PaintingStyle.stroke,
      );
    }
    if (flag != null) {
      final scale = math.min(
        (capital ? 16 : (compact ? 24 : 32)) / flag.width,
        (capital ? 11 : (compact ? 16 : 22)) / flag.height,
      );
      final fw = flag.width * scale;
      final fh = flag.height * scale;
      canvas.drawImageRect(
        flag,
        ui.Rect.fromLTWH(0, 0, flag.width.toDouble(), flag.height.toDouble()),
        ui.Rect.fromLTWH(
          capital ? 4 : (width - fw) / 2,
          capital
              ? (height - fh) / 2
              : (compact ? 4 + (16 - fh) / 2 : 5 + (22 - fh) / 2),
          fw,
          fh,
        ),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    } else if (landmark) {
      // Draw the pin directly: the bundled text font lacks landmark glyphs.
      final middle = height / 2;
      final pin = ui.Path()
        ..moveTo(15, middle + 9)
        ..cubicTo(12, middle + 5, 8, middle + 1, 8, middle - 3)
        ..cubicTo(8, middle - 12, 22, middle - 12, 22, middle - 3)
        ..cubicTo(22, middle + 1, 18, middle + 5, 15, middle + 9)
        ..close();
      canvas.drawPath(
        pin,
        ui.Paint()
          ..color = wonder ? const Color(0xffbf4672) : const Color(0xff247a83),
      );
      canvas.drawCircle(
        ui.Offset(15, middle - 3),
        2.5,
        ui.Paint()..color = const Color(0xffffffff),
      );
    }
    text.paint(
      canvas,
      ui.Offset(
        (width - text.width + leading) / 2,
        flag != null && !capital
            ? (compact ? 24 : 31)
            : (height - text.height) / 2,
      ),
    );
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

Future<Uint8List> renderCapitalMarker() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final star = ui.Path();
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final radius = i.isEven ? 7.5 : 3.5;
    final point = ui.Offset(
      12 + radius * math.cos(angle),
      12 + radius * math.sin(angle),
    );
    if (i == 0) {
      star.moveTo(point.dx, point.dy);
    } else {
      star.lineTo(point.dx, point.dy);
    }
  }
  star.close();
  canvas.drawPath(star, ui.Paint()..color = const Color(0xffb74832));
  canvas.drawPath(
    star,
    ui.Paint()
      ..color = const Color(0xffffffff)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(24, 24);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Capital marker PNG encoding failed');
      return normalizeFlagSprite(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}
