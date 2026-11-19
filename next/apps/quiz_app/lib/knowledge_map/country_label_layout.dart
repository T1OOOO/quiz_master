/// Geometry helpers for placing country labels in the visible outline.
/// Coordinates are GeoJSON [longitude, latitude].
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

/// Reuse anchors while their label has room on screen.
Map<String, (double, double)> stableCountryLabelAnchors(
  Map<String, (double, double)> previous,
  Map<String, (double, double)> proposed,
  GeoViewport safeViewport,
) => {
  for (final entry in proposed.entries)
    entry.key:
        previous[entry.key] != null &&
            safeViewport.contains(
              previous[entry.key]!.$1,
              previous[entry.key]!.$2,
            )
        ? previous[entry.key]!
        : entry.value,
};

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
  ({double longitude, double latitude})? best;
  var bestArea = -1.0;
  for (final polygon in polygons) {
    if (polygon is! List || polygon.isEmpty) continue;
    final rings = polygon.whereType<List>().map(_points).toList();
    if (rings.isEmpty || rings.first.length < 3) continue;
    final projected = <List<(double, double)>>[];
    for (final ring in rings) {
      if (ring.isEmpty) continue;
      final points = <(double, double)>[];
      var previous = viewport._x(ring.first.$1);
      if (projected.isNotEmpty) {
        previous = _continuousX(previous, projected.first.first.$1);
      }
      for (final p in ring) {
        final x = _continuousX(viewport._x(p.$1), previous);
        points.add((x, p.$2));
        previous = x;
      }
      projected.add(points);
    }
    for (final shift in [-360.0, 0.0, 360.0]) {
      var clipped = projected.first.map((p) => (p.$1 + shift, p.$2)).toList();
      for (var edge = 0; edge < 4; edge++) {
        clipped = _clipPolygon(clipped, edge, viewport);
      }
      if (clipped.isEmpty) continue;
      var area = 0.0, cx = 0.0, cy = 0.0;
      for (var i = 0; i < clipped.length; i++) {
        final a = clipped[i], b = clipped[(i + 1) % clipped.length];
        final cross = a.$1 * b.$2 - b.$1 * a.$2;
        area += cross;
        cx += (a.$1 + b.$1) * cross;
        cy += (a.$2 + b.$2) * cross;
      }
      final size = area.abs();
      if (size <= bestArea) continue;
      final minX = clipped.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
      final maxX = clipped.map((p) => p.$1).reduce((a, b) => a > b ? a : b);
      final minY = clipped.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
      final maxY = clipped.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
      final targetX = area.abs() > 1e-12 ? cx / (3 * area) : (minX + maxX) / 2;
      final targetY = area.abs() > 1e-12 ? cy / (3 * area) : (minY + maxY) / 2;
      bool inside(double x, double y) {
        if (!_insideXY(x, y, clipped)) return false;
        for (final hole in projected.skip(1)) {
          final shifted = hole.map((p) => (p.$1 + shift, p.$2)).toList();
          if (_insideXY(x, y, shifted)) return false;
        }
        return true;
      }

      double? x, y;
      if (inside(targetX, targetY)) {
        x = targetX;
        y = targetY;
      } else {
        var distance = double.infinity;
        for (var iy = 0; iy < 9; iy++) {
          for (var ix = 0; ix < 9; ix++) {
            final px = minX + (maxX - minX) * (ix + .5) / 9;
            final py = minY + (maxY - minY) * (iy + .5) / 9;
            final d =
                (px - targetX) * (px - targetX) +
                (py - targetY) * (py - targetY);
            if (d < distance && inside(px, py)) {
              x = px;
              y = py;
              distance = d;
            }
          }
        }
      }
      if (x != null && y != null) {
        bestArea = size;
        best = (longitude: _normalize(viewport.west + x), latitude: y);
      }
    }
  }
  return best;
}

List<(double, double)> _clipPolygon(
  List<(double, double)> input,
  int edge,
  GeoViewport v,
) {
  if (input.isEmpty) return input;
  bool inside((double, double) p) => switch (edge) {
    0 => p.$1 >= 0,
    1 => p.$1 <= v._width,
    2 => p.$2 >= v.south,
    _ => p.$2 <= v.north,
  };
  (double, double) intersect((double, double) a, (double, double) b) {
    if (edge < 2) {
      final x = edge == 0 ? 0.0 : v._width;
      return (x, a.$2 + (b.$2 - a.$2) * (x - a.$1) / (b.$1 - a.$1));
    }
    final y = edge == 2 ? v.south : v.north;
    return (a.$1 + (b.$1 - a.$1) * (y - a.$2) / (b.$2 - a.$2), y);
  }

  final result = <(double, double)>[];
  var previous = input.last;
  for (final current in input) {
    if (inside(current)) {
      if (!inside(previous)) result.add(intersect(previous, current));
      result.add(current);
    } else if (inside(previous)) {
      result.add(intersect(previous, current));
    }
    previous = current;
  }
  return result;
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

bool _insideXY(double x, double y, List<(double, double)> ring) {
  if (ring.length < 3) return false;
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if (((a.$2 > y) != (b.$2 > y)) &&
        x < (b.$1 - a.$1) * (y - a.$2) / (b.$2 - a.$2) + a.$1) {
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

double _normalize(double lon) => ((lon + 180) % 360 + 360) % 360 - 180;

Map<String, (double, double)> visibleCountryLabelAnchors(
  List<dynamic> labels,
  List<dynamic> visible,
  GeoViewport viewport, {
  List<dynamic>? fullOutlines,
}) {
  final outlines = <String, Map>{};
  for (final item in visible) {
    if (item is! Map || item['properties'] is! Map) continue;
    final id = (item['properties'] as Map)['country_id'];
    if (id is String) outlines.putIfAbsent(id, () => item);
  }
  if (fullOutlines != null) {
    for (final item in fullOutlines) {
      if (item is! Map || item['properties'] is! Map) continue;
      final id = (item['properties'] as Map)['country_id'];
      if (id is String && outlines.containsKey(id)) outlines[id] = item;
    }
  }
  final result = <String, (double, double)>{};
  for (final item in labels) {
    if (item is! Map ||
        item['properties'] is! Map ||
        item['geometry'] is! Map) {
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
    final point = countryLabelAnchor(outlines[id]!, viewport);
    if (point != null) result[id] = (point.longitude, point.latitude);
  }
  return result;
}
