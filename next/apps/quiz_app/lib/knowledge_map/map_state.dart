import 'dart:ui';

Future<List> queryVisibleWithRetry(
  Future<List> Function() query,
  bool Function() current,
  Future<void> Function() wait,
) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    final features = await query();
    if (features.isNotEmpty || !current() || attempt == 9) return features;
    await wait();
    if (!current()) return [];
  }
  return [];
}

List<MapCountry> visibleCountries(List<MapCountry> countries, List features) {
  final ids = <String>{};
  for (final feature in features) {
    if (feature is Map && feature['properties'] is Map) {
      final id = feature['properties']['country_id'];
      if (id is String) ids.add(id);
    }
  }
  return countries.where((country) => ids.contains(country.id)).toList();
}

class MapCountry {
  const MapCountry({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    this.capital,
    this.area,
    this.population,
    this.populationYear,
    this.currencies = const [],
    this.languages = const [],
    this.interestingFacts = const [],
  });
  final String id, nameRu, nameEn;
  final String? capital;
  final num? area, population;
  final int? populationYear;
  final List<String> currencies, languages;
  final List<MapInterestingFact> interestingFacts;
}

class MapInterestingFact {
  const MapInterestingFact({
    required this.textRu,
    required this.textEn,
    required this.source,
  });
  final String textRu, textEn;
  final Uri source;

  static MapInterestingFact? fromJson(Object? value) {
    if (value is! Map) return null;
    final ru = value['text_ru'];
    final en = value['text_en'];
    final raw = value['source_url'];
    if (ru is! String ||
        ru.trim().isEmpty ||
        en is! String ||
        en.trim().isEmpty ||
        raw is! String) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return MapInterestingFact(textRu: ru, textEn: en, source: uri);
  }
}

class MapLandmark {
  MapLandmark.fromProperties(Map<String, dynamic> p)
    : id = p['id'] as String,
      countryId = p['country_id'] as String,
      nameRu = p['name_ru'] as String,
      nameEn = p['name_en'] as String,
      explanationRu = p['explanation_ru'] as String,
      explanationEn = p['explanation_en'] as String,
      sourceUrl = p['source_url'] as String,
      coordinateSourceUrl = p['coordinate_source_url'] as String,
      thumbnailAsset = p['thumbnail_asset'] as String?,
      imageAttribution = p['image_attribution'] as String?,
      imageLicense = p['image_license'] as String?,
      imageLicenseUrl = p['image_license_url'] as String?,
      imageSourceUrl = p['image_source_url'] as String?;
  final String id,
      countryId,
      nameRu,
      nameEn,
      explanationRu,
      explanationEn,
      sourceUrl,
      coordinateSourceUrl;
  final String? thumbnailAsset,
      imageAttribution,
      imageLicense,
      imageLicenseUrl,
      imageSourceUrl;
}

class MapState {
  MapState(this.countries, {this.landmarks = const []});
  final List<MapLandmark> landmarks;
  String? selectedLandmarkId;
  MapLandmark? get selectedLandmark =>
      landmarks.where((l) => l.id == selectedLandmarkId).firstOrNull;
  void selectLandmark(String? id) {
    selectedLandmarkId = id;
    selectedId = null;
  }

  final List<MapCountry> countries;
  String? selectedId;
  MapCountry? get selected =>
      countries.where((c) => c.id == selectedId).firstOrNull;
  void select(String? id) {
    selectedId = id;
    selectedLandmarkId = null;
  }

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
  String? landmarkId;
  Offset? point;

  int begin() => ++_sequence;
  bool isCurrent(int request) => request == _sequence;
  bool complete(int request, String? id, Offset location) {
    if (!isCurrent(request)) return false;
    countryId = id;
    landmarkId = null;
    point = id == null ? null : location;
    return true;
  }

  bool completeLandmark(int request, String id, Offset location) {
    if (!isCurrent(request)) return false;
    countryId = null;
    landmarkId = id;
    point = location;
    return true;
  }

  void clear() {
    _sequence++;
    landmarkId = null;
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

class MapTapRequests {
  int _sequence = 0;
  int begin() => ++_sequence;
  bool isCurrent(int request) => request == _sequence;
  void invalidate() => _sequence++;
}

Future<void> ensureMapSprite(
  Set<String> cache,
  String key,
  Future<void> Function() render,
  Future<void> Function() register,
) async {
  if (cache.contains(key)) return;
  await render();
  await register();
  cache.add(key);
}
