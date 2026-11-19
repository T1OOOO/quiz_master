import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Web-only bridge for MapLibre's globe projection.
bool get globeProjectionSupported => kIsWeb;

Future<bool> setGlobeProjection(
  MapLibreMapController controller,
  bool enabled,
) async {
  if (!kIsWeb) return false;
  try {
    await controller.setProjection(enabled ? 'globe' : 'mercator');
    return true;
  } on UnsupportedError {
    return false;
  } on StateError {
    return false;
  }
}
