import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Natural Earth I (50m) land-cover and shaded-relief raster.
const historyReliefAsset = 'assets/knowledge_map_relief.webp';

Future<ui.Image> loadHistoryRelief() async {
  final data = await rootBundle.load(historyReliefAsset);
  final codec = await ui.instantiateImageCodec(
    Uint8List.sublistView(data),
    targetWidth: 2048,
  );
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}
