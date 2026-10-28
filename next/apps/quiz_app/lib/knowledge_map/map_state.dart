import 'dart:ui';

class MapCountry {
  const MapCountry({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    this.capital,
    this.area,
  });
  final String id, nameRu, nameEn;
  final String? capital;
  final num? area;
}

class MapState {
  MapState(this.countries);
  final List<MapCountry> countries;
  String? selectedId;
  MapCountry? get selected =>
      countries.where((c) => c.id == selectedId).firstOrNull;
  void select(String? id) => selectedId = id;
  List<MapCountry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return countries
        .where(
          (c) => [
            c.id,
            c.nameRu,
            c.nameEn,
          ].any((s) => s.toLowerCase().contains(q)),
        )
        .toList();
  }
}

class MapHoverState {
  int _sequence = 0;
  String? countryId;
  Offset? point;

  int begin() => ++_sequence;
  bool isCurrent(int request) => request == _sequence;
  bool complete(int request, String? id, Offset location) {
    if (!isCurrent(request)) return false;
    countryId = id;
    point = id == null ? null : location;
    return true;
  }

  void clear() {
    _sequence++;
    countryId = null;
    point = null;
  }
}

Offset clampHoverTooltip(Offset desired, Size viewport, Size tooltip) => Offset(
  desired.dx.clamp(
    0.0,
    (viewport.width - tooltip.width).clamp(0.0, double.infinity),
  ),
  desired.dy.clamp(
    0.0,
    (viewport.height - tooltip.height).clamp(0.0, double.infinity),
  ),
);
