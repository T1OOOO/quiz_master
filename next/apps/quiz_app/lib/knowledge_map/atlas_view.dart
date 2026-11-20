import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Camera zoom uses MapLibre's 512-pixel world at zoom zero.
typedef AtlasCamera = ({double longitude, double latitude, double zoom});
typedef AtlasView = ({String? country, bool globe, AtlasCamera? camera});

double atlasPixelsPerDegree(double zoom) => 512 * math.pow(2, zoom) / 360;
double atlasZoomForPixels(double pixelsPerDegree) =>
    math.log(pixelsPerDegree * 360 / 512) / math.ln2;

double _globeLatitudeScale(double latitude) =>
    math.cos(latitude * math.pi / 180).clamp(.35, 1.0);

double atlasGlobeRadius(AtlasCamera camera) =>
    atlasPixelsPerDegree(camera.zoom) *
    180 /
    math.pi *
    .87 /
    _globeLatitudeScale(camera.latitude);

AtlasCamera atlasGlobeCamera(
  double longitude,
  double latitude,
  double radius,
) => (
  longitude: longitude,
  latitude: latitude,
  zoom: atlasZoomForPixels(
    radius * math.pi / 180 * _globeLatitudeScale(latitude) / .87,
  ),
);

AtlasCamera atlasFlatCamera(
  Offset sceneCenter,
  Offset origin,
  double scale,
  double zoom,
) => (
  longitude: ((sceneCenter.dx - origin.dx) / scale - 180).clamp(-180.0, 180.0),
  latitude: (90 - (sceneCenter.dy - origin.dy) / scale).clamp(-85.0, 85.0),
  zoom: atlasZoomForPixels(scale * zoom),
);
