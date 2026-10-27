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
