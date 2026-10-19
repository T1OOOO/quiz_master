import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class WaterPoint {
  const WaterPoint(this.x, this.y);
  final double x, y;
}

bool _inRing(WaterPoint p, List<WaterPoint> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if ((a.y > p.y) != (b.y > p.y) &&
        p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

class WaterShape {
  const WaterShape({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.kind,
    required this.anchor,
    required this.polygons,
    required this.lines,
  });
  final String id, nameRu, nameEn, kind;
  final WaterPoint anchor;
  final List<List<List<WaterPoint>>> polygons;
  final List<List<WaterPoint>> lines;

  bool contains(WaterPoint point, {double tolerance = .000001}) {
    if (polygons.any(
      (p) =>
          _inRing(point, p.first) &&
          !p.skip(1).any((hole) => _inRing(point, hole)),
    )) {
      return true;
    }
    for (final line in lines) {
      for (var i = 1; i < line.length; i++) {
        final a = line[i - 1], b = line[i];
        final dx = b.x - a.x, dy = b.y - a.y;
        final length = dx * dx + dy * dy;
        final t = length == 0
            ? 0.0
            : (((point.x - a.x) * dx + (point.y - a.y) * dy) / length).clamp(
                0.0,
                1.0,
              );
        if (math.pow(point.x - a.x - t * dx, 2) +
                math.pow(point.y - a.y - t * dy, 2) <
            tolerance * tolerance) {
          return true;
        }
      }
    }
    return false;
  }
}

class WaterAtlas {
  const WaterAtlas(this.features);
  final List<WaterShape> features;

  factory WaterAtlas.fromJson(Object? value) {
    Never invalid() => throw const FormatException('Invalid water geometry');
    if (value is! Map ||
        value['schema_version'] != 'qm-waterways/v1' ||
        value['features'] is! List ||
        (value['features'] as List).isEmpty ||
        (value['features'] as List).length > 500) {
      invalid();
    }
    WaterPoint point(Object? v) {
      if (v is! List ||
          v.length != 2 ||
          v.any((n) => n is! num || !n.isFinite || n < 0 || n > 1)) {
        invalid();
      }
      return WaterPoint((v[0] as num).toDouble(), (v[1] as num).toDouble());
    }

    final ids = <String>{};
    final rows = <WaterShape>[];
    for (final row in value['features'] as List) {
      if (row is! Map ||
          [
            'id',
            'name_ru',
            'name_en',
            'kind',
          ].any((k) => row[k] is! String || (row[k] as String).isEmpty) ||
          !ids.add(row['id'] as String) ||
          !['marine', 'lake', 'river'].contains(row['kind']) ||
          row['polygons'] is! List ||
          row['lines'] is! List) {
        invalid();
      }
      List<WaterPoint> path(Object? v, {bool ring = false}) {
        if (v is! List || v.length < (ring ? 4 : 2)) invalid();
        final points = v.map(point).toList(growable: false);
        if (ring &&
            (points.first.x != points.last.x ||
                points.first.y != points.last.y)) {
          invalid();
        }
        return List.unmodifiable(points);
      }

      final polygons = <List<List<WaterPoint>>>[];
      for (final polygon in row['polygons'] as List) {
        if (polygon is! List || polygon.isEmpty) invalid();
        polygons.add(
          List.unmodifiable(polygon.map((r) => path(r, ring: true))),
        );
      }
      final lines = (row['lines'] as List)
          .map((l) => path(l))
          .toList(growable: false);
      if (row['kind'] == 'river'
          ? (lines.isEmpty || polygons.isNotEmpty)
          : (polygons.isEmpty || lines.isNotEmpty)) {
        invalid();
      }
      final shape = WaterShape(
        id: row['id'],
        nameRu: row['name_ru'],
        nameEn: row['name_en'],
        kind: row['kind'],
        anchor: point(row['anchor']),
        polygons: List.unmodifiable(polygons),
        lines: List.unmodifiable(lines),
      );
      if (!shape.contains(shape.anchor)) invalid();
      rows.add(shape);
    }
    return WaterAtlas(List.unmodifiable(rows));
  }

  static Future<WaterAtlas> load([AssetBundle? bundle]) async =>
      WaterAtlas.fromJson(
        jsonDecode(
          await (bundle ?? rootBundle).loadString(
            'assets/quizipedia/waterways.json',
            cache: false,
          ),
        ),
      );
}
