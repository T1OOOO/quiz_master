import 'dart:math' as math;

import 'map_state.dart';

/// Country label coordinates are used only to rule out other countries.
Set<String> practiceHintExcluded(
  List<MapCountry> countries,
  String? targetId,
  int level, {
  Map<String, List<double>> coordinates = const {},
}) {
  final target = countries.where((c) => c.id == targetId).firstOrNull;
  if (target == null || level < 1) return {};
  final origin = coordinates[targetId];
  final radius = [9000.0, 6500.0, 4500.0, 2500.0][math.min(level, 4) - 1];
  return countries
      .where((c) {
        if (c.id == targetId) return false;
        if (level >= 5 && target.region?.isNotEmpty == true) {
          if (c.region?.isNotEmpty != true) return false;
          if (target.region != c.region) return true;
          return target.subregion?.isNotEmpty == true &&
              c.subregion?.isNotEmpty == true &&
              c.subregion != target.subregion;
        }
        final point = coordinates[c.id];
        if (origin != null && point != null) {
          final lat1 = origin[1] * math.pi / 180;
          final lat2 = point[1] * math.pi / 180;
          final dLat = lat2 - lat1;
          final dLon = (point[0] - origin[0]) * math.pi / 180;
          final a =
              math.pow(math.sin(dLat / 2), 2) +
              math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
          if (12742 * math.asin(math.sqrt(a.clamp(0, 1))) > radius) return true;
        }
        return false;
      })
      .map((c) => c.id)
      .toSet();
}

Set<String> practiceHintRegion(List<MapCountry> countries, String? targetId) {
  final target = countries.where((c) => c.id == targetId).firstOrNull;
  if (target?.region?.isNotEmpty != true) return {};
  return countries
      .where(
        (c) =>
            c.region == target!.region &&
            (target.subregion?.isNotEmpty != true ||
                c.subregion == target.subregion),
      )
      .map((c) => c.id)
      .toSet();
}
