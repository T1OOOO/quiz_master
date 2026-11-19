import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Installs a small, fully local relief underlay below the map's data layers.
///
/// The four images are deliberately coarse and contain no labels. They are
/// useful for orientation at world and regional zooms, while the normal map
/// layers remain responsible for country, river, and place detail. Calling
/// [install] is safe to fire-and-forget after the first frame. A later call
/// supersedes an earlier one, so a disposed or rapidly recreated map cannot
/// receive stale layers.
class ReliefBasemap {
  ReliefBasemap();

  int _generation = 0;

  Future<void> install(
    MapLibreMapController controller, {
    String? belowLayerId,
  }) async {
    final generation = ++_generation;
    final quadrants = <_ReliefQuadrant>[
      _ReliefQuadrant('nw', const LatLngQuad(
        topLeft: LatLng(85.0511287798, -180),
        topRight: LatLng(85.0511287798, 0),
        bottomRight: LatLng(0, 0),
        bottomLeft: LatLng(0, -180),
      )),
      _ReliefQuadrant('ne', const LatLngQuad(
        topLeft: LatLng(85.0511287798, 0),
        topRight: LatLng(85.0511287798, 180),
        bottomRight: LatLng(0, 180),
        bottomLeft: LatLng(0, 0),
      )),
      _ReliefQuadrant('sw', const LatLngQuad(
        topLeft: LatLng(0, -180),
        topRight: LatLng(0, 0),
        bottomRight: LatLng(-85.0511287798, 0),
        bottomLeft: LatLng(-85.0511287798, -180),
      )),
      _ReliefQuadrant('se', const LatLngQuad(
        topLeft: LatLng(0, 0),
        topRight: LatLng(0, 180),
        bottomRight: LatLng(-85.0511287798, 180),
        bottomLeft: LatLng(-85.0511287798, 0),
      )),
    ];
    late final List<Uint8List> bytes;
    try {
      bytes = await Future.wait(quadrants.map(_read));
    } catch (_) {
      // Relief is optional. Missing assets or a platform decoder failure
      // must never delay or break the normal vector map.
      return;
    }
    if (generation != _generation) return;

    for (var i = 0; i < quadrants.length; i++) {
      if (generation != _generation) return;
      final quadrant = quadrants[i];
      final sourceId = 'quiz-relief-${quadrant.id}';
      final layerId = 'quiz-relief-layer-${quadrant.id}';
      try {
        final imageBytes = bytes[i];
        if (kIsWeb) {
          await controller.addSource(
            sourceId,
            ImageSourceProperties(
              url: 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
              coordinates: quadrant.coordinates.toList(),
            ),
          );
        } else {
          await controller.addImageSource(
            sourceId,
            imageBytes,
            quadrant.coordinates,
          );
        }
        await controller.addRasterLayer(
          sourceId,
          layerId,
          const RasterLayerProperties(
            rasterOpacity: [
              'interpolate',
              ['linear'],
              ['zoom'],
              3.5,
              0.52,
              5.8,
              0.0,
            ],
            rasterFadeDuration: 250,
          ),
          belowLayerId: belowLayerId,
          maxzoom: 8.0,
        );
      } catch (_) {
        // A map style may already contain the source during a hot reload.
        // Keep the normal vector map usable when an optional underlay fails.
      }
    }
  }

  Future<Uint8List> _read(_ReliefQuadrant quadrant) async {
    final data = await rootBundle.load(
      'assets/quizipedia/relief/relief_${quadrant.id}.jpg',
    );
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}

class _ReliefQuadrant {
  const _ReliefQuadrant(this.id, this.coordinates);

  final String id;
  final LatLngQuad coordinates;
}
