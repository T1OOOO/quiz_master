/// Geometry helpers for keeping country labels visible when their centroid is
/// outside the viewport. Coordinates are GeoJSON [longitude, latitude].
class GeoViewport {
  const GeoViewport({
    required this.west,
    required this.east,
    required this.south,
    required this.north,
  });
  final double west, east, south, north;
  bool contains(double lon, double lat) =>
      lat >= south && lat <= north && _x(lon) >= 0 && _x(lon) <= _width;
  double get _width => east >= west ? east - west : east + 360 - west;
  double _x(double lon) {
    var x = lon;
    while (x < west) {
      x += 360;
    }
    while (x > west + 360) {
      x -= 360;
    }
    return x - west;
  }
}

/// Finds a point inside the visible portion of a GeoJSON Polygon/MultiPolygon.
/// Returns null for malformed or non-polygon geometry.
({double longitude, double latitude})? countryLabelAnchor(
  Map feature,
  GeoViewport viewport,
) {
  final geometry = feature['geometry'];
  if (geometry is! Map) return null;
  final type = geometry['type'];
  final raw = geometry['coordinates'];
  if (raw is! List) return null;
  final polygons = type == 'Polygon'
      ? [raw]
      : type == 'MultiPolygon'
      ? raw
      : const [];
  final candidates = <({double longitude, double latitude})>[];
  for (final polygon in polygons) {
    if (polygon is! List || polygon.isEmpty) continue;
    final rings = polygon.whereType<List>().toList();
    if (rings.isEmpty) continue;
    final outer = _points(rings.first);
    if (outer.length < 3) continue;
    final centerLon = viewport.west + viewport._width / 2;
    final centerLat = (viewport.south + viewport.north) / 2;
    final inHole = rings
        .skip(1)
        .map(_points)
        .any(
          (hole) =>
              hole.length >= 3 && _inside(centerLon, centerLat, hole, viewport),
        );
    if (_inside(centerLon, centerLat, outer, viewport) && !inHole) {
      candidates.add((longitude: _normalize(centerLon), latitude: centerLat));
      return candidates.first;
    }
    for (final point in outer) {
      if (viewport.contains(point.$1, point.$2)) {
        candidates.add((longitude: point.$1, latitude: point.$2));
      }
    }
    for (var i = 0; i < outer.length; i++) {
      final a = outer[i], b = outer[(i + 1) % outer.length];
      final ax = viewport._x(a.$1),
          bx = _unwrapX(viewport._x(b.$1), ax, viewport._width);
      final ay = a.$2, by = b.$2;
      final clipped = _clip(
        ax,
        ay,
        bx,
        by,
        0,
        viewport._width,
        viewport.south,
        viewport.north,
      );
      if (clipped != null) {
        candidates.add((
          longitude: _normalize(viewport.west + clipped.$1),
          latitude: clipped.$2,
        ));
      }
    }
    // Return a point from this connected component. Averaging points from
    // separate islands can place a label in the ocean between them.
    if (candidates.isNotEmpty) return candidates.first;
  }
  if (candidates.isEmpty) return null;
  return candidates.first;
}

List<(double, double)> _points(List ring) => ring
    .map<(double, double)>((p) {
      if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
        return (p[0].toDouble(), p[1].toDouble());
      }
      return (double.nan, double.nan);
    })
    .where((p) => p.$1.isFinite && p.$2.isFinite)
    .toList();

bool _inside(
  double lon,
  double lat,
  List<(double, double)> ring,
  GeoViewport v,
) {
  final x = v._x(lon);
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final xi = _continuousX(v._x(ring[i].$1), x),
        xj = _continuousX(v._x(ring[j].$1), x);
    if (((ring[i].$2 > lat) != (ring[j].$2 > lat)) &&
        x < (xj - xi) * (lat - ring[i].$2) / (ring[j].$2 - ring[i].$2) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

double _continuousX(double value, double reference) {
  var x = value;
  while (x - reference > 180) {
    x -= 360;
  }
  while (reference - x > 180) {
    x += 360;
  }
  return x;
}

double _unwrapX(double x, double previous, double width) {
  if (x - previous > 180) return x - 360;
  if (previous - x > 180) return x + 360;
  return x;
}

double _normalize(double lon) => ((lon + 180) % 360 + 360) % 360 - 180;

(double, double)? _clip(
  double x0,
  double y0,
  double x1,
  double y1,
  double minX,
  double maxX,
  double minY,
  double maxY,
) {
  final dx = x1 - x0, dy = y1 - y0;
  var t0 = 0.0, t1 = 1.0;
  for (final pair in <(double, double)>[
    (-dx, x0 - minX),
    (dx, maxX - x0),
    (-dy, y0 - minY),
    (dy, maxY - y0),
  ]) {
    if (pair.$1 == 0) {
      if (pair.$2 < 0) return null;
    } else {
      final t = pair.$2 / pair.$1;
      if (pair.$1 < 0) {
        if (t > t1) return null;
        if (t > t0) t0 = t;
      } else {
        if (t < t0) return null;
        if (t < t1) t1 = t;
      }
    }
  }
  return (x0 + t0 * dx, y0 + t0 * dy);
}

Map<String, (double, double)> visibleCountryLabelAnchors(
  List<dynamic> labels,
  List<dynamic> visible,
  GeoViewport viewport,
) {
  final outlines = <String, Map>{};
  for (final item in visible) {
    if (item is! Map || item['properties'] is! Map) continue;
    final id = (item['properties'] as Map)['country_id'];
    if (id is String) outlines.putIfAbsent(id, () => item);
  }
  final result = <String, (double, double)>{};
  for (final item in labels) {
    if (item is! Map || item['properties'] is! Map || item['geometry'] is! Map) {
      continue;
    }
    final id = (item['properties'] as Map)['country_id'];
    final coords = (item['geometry'] as Map)['coordinates'];
    if (id is! String ||
        coords is! List ||
        coords.length < 2 ||
        coords[0] is! num ||
        coords[1] is! num ||
        !outlines.containsKey(id)) {
      continue;
    }
    if (viewport.contains(
      (coords[0] as num).toDouble(),
      (coords[1] as num).toDouble(),
    )) {
      continue;
    }
    final point = countryLabelAnchor(outlines[id]!, viewport);
    if (point != null) result[id] = (point.longitude, point.latitude);
  }
  return result;
}
