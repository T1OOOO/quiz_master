import 'map_state.dart';

/// Exclude only countries with known classification; never exclude the target.
Set<String> practiceHintExcluded(
  List<MapCountry> countries,
  String? targetId,
  int level,
) {
  final target = countries.where((c) => c.id == targetId).firstOrNull;
  if (target == null ||
      level < 1 ||
      target.region == null ||
      target.region!.isEmpty) {
    return {};
  }
  return countries
      .where((c) {
        if (c.id == targetId || c.region == null || c.region!.isEmpty) {
          return false;
        }
        if (c.region != target.region) return true;
        return level >= 2 &&
            target.subregion != null &&
            target.subregion!.isNotEmpty &&
            c.subregion != null &&
            c.subregion!.isNotEmpty &&
            c.subregion != target.subregion;
      })
      .map((c) => c.id)
      .toSet();
}
