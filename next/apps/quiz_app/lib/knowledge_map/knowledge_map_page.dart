import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../country_labels_ru.dart';
import 'country_marker.dart';
import 'country_label_layout.dart';
import 'landmarks_browser.dart';
import 'country_number_format.dart';
import 'countries_browser.dart';
import 'map_state.dart';

@visibleForTesting
String thematicNumberLabel(
  num? value, {
  required bool russian,
  required bool area,
}) {
  if (value == null) return russian ? 'Нет данных' : 'No data';
  return '${formatCountryNumber(value, russian: russian)}${area ? (russian ? ' км²' : ' km²') : ''}';
}

@visibleForTesting
String? capitalThematicLabel(MapCountry? country, {required bool russian}) {
  final value = country?.capital;
  if (value == null || value.trim().isEmpty) return null;
  return russian ? russianCountryLabel(value) : value;
}

@visibleForTesting
Future<void> commitCountryLabelsUpdate({
  required Future<void> Function() update,
  required void Function() commit,
}) async {
  await update();
  commit();
}

class KnowledgeMapPage extends StatefulWidget {
  const KnowledgeMapPage({super.key, this.onExit})
    : mapBuilder = null,
      hoverMapBuilder = null,
      landmarkMapBuilder = null,
      featureMapBuilder = null,
      visibleCountryIds = null,
      bundle = null;
  @visibleForTesting
  const KnowledgeMapPage.test({
    super.key,
    required this.mapBuilder,
    this.hoverMapBuilder,
    this.landmarkMapBuilder,
    this.featureMapBuilder,
    this.visibleCountryIds,
    this.bundle,
    this.onExit,
  });
  final Widget Function(
    BuildContext,
    void Function(String?),
    void Function(String?, Offset),
    VoidCallback,
  )?
  hoverMapBuilder;
  final Widget Function(
    BuildContext,
    void Function(String?),
    void Function(String?, Offset),
  )?
  landmarkMapBuilder;
  final Widget Function(
    BuildContext,
    void Function(String, Map<String, dynamic>),
  )?
  featureMapBuilder;
  final AssetBundle? bundle;
  final List<String>? visibleCountryIds;
  final VoidCallback? onExit;
  final Widget Function(BuildContext, void Function(String?))? mapBuilder;
  @override
  State<KnowledgeMapPage> createState() => _KnowledgeMapPageState();
}

class _KnowledgeMapPageState extends State<KnowledgeMapPage> {
  MapLibreMapController? controller;
  Timer? startupTimer;
  MapState? state;
  Map<String, dynamic>? countries,
      capitals,
      waterways,
      riverDetail,
      lakeDetail,
      countryLabels,
      waterLabels,
      landmarks;
  Map<String, dynamic> flags = {};
  Map<String, dynamic> featureFacts = {};
  Map<String, dynamic>? selectedFeature;
  String? selectedFeatureKind;
  bool detailRiversReady = false, detailLakesReady = false;
  bool failed = false,
      ready = false,
      layersOpen = false,
      showCapitals = true,
      showLandmarks = true,
      showCountryLabels = true,
      showWaterLabels = true;
  String thematic = 'none';
  List<dynamic> dishes = [];
  Map<String, dynamic> waters = {};
  List<dynamic> waterSources = [], foodSources = [];
  final Set<String> thematicSprites = {};
  final hover = MapHoverState();
  final tapRequests = MapTapRequests();
  Timer? hoverTimer;
  Future<void> hoverFilter = Future.value();
  Future<void> capitalCommands = Future.value();
  Future<void> labelCommands = Future.value();
  Future<void> thematicCommands = Future.value();
  int thematicSequence = 0;
  int generation = 0;
  int visibleRequest = 0;
  Size mapViewport = Size.zero;
  List<MapCountry> visible = [];
  bool visibleOpen = false;
  Map<String, dynamic>? appliedCountryLabels;
  String appliedThematic = 'none';
  Map<String, (double, double)> labelOverrides = {};
  bool browserOpen = false;
  bool placesOpen = false;
  String placesCategory = 'all';
  Future<void> placesCommands = Future.value();
  bool countryDetailsOpen = false;
  bool countryPanelOnSide = false;
  double? countryPanelHeight;
  bool practice = false;
  bool practiceBusy = false;
  int practiceMode = 0;
  String? practiceTarget;
  List<MapCountry> practiceOptions = [];
  bool? practiceResult;
  bool get ru => Localizations.localeOf(context).languageCode == 'ru';
  String tr(String en, String russian) => ru ? russian : en;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<Map<String, dynamic>?> loadOptionalWater(
    String asset,
    Set<String> geometryTypes,
  ) async {
    try {
      final text = await (widget.bundle ?? rootBundle).loadString(
        asset,
        cache: false,
      );
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic> ||
          data['type'] != 'FeatureCollection' ||
          data['features'] is! List ||
          (data['features'] as List).isEmpty) {
        throw const FormatException('Invalid or empty water FeatureCollection');
      }
      for (final feature in data['features'] as List) {
        if (feature is! Map ||
            feature['type'] != 'Feature' ||
            feature['geometry'] is! Map ||
            !geometryTypes.contains((feature['geometry'] as Map)['type']) ||
            (feature['geometry'] as Map)['coordinates'] is! List) {
          throw const FormatException('Invalid detailed water geometry');
        }
      }
      return data;
    } catch (error) {
      debugPrint('Knowledge map: detailed water unavailable ($asset): $error');
      return null;
    }
  }

  Future<void> load() async {
    startupTimer?.cancel();
    hoverTimer?.cancel();
    hover.clear();
    tapRequests.invalidate();
    visibleRequest++;
    visible = [];
    labelOverrides = {};
    visibleOpen = false;
    browserOpen = false;
    placesOpen = false;
    placesCategory = 'all';
    controller = null;
    thematicSprites.clear();
    dishes = [];
    thematic = 'none';
    thematicSequence++;
    detailRiversReady = false;
    detailLakesReady = false;
    setState(() {
      failed = false;
      ready = false;
      state = null;
      showCapitals = true;
      showLandmarks = true;
      showCountryLabels = true;
      showWaterLabels = true;
      layersOpen = false;
      countryDetailsOpen = false;
      generation++;
    });
    final attempt = generation;
    try {
      final riverFuture = loadOptionalWater(
        'assets/quizipedia/map_v2/rivers_detail.geojson',
        const {'LineString', 'MultiLineString'},
      );
      final lakeFuture = loadOptionalWater(
        'assets/quizipedia/map_v2/lakes_detail.geojson',
        const {'Polygon', 'MultiPolygon'},
      );
      final texts = await Future.wait([
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/map_v2/countries.geojson',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/map_v2/capitals.geojson',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/map_v2/waterways.geojson',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/map_v2/country_labels.geojson',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/country_facts.json',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/country_flag_images.json',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/map_v2/water_labels.geojson',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/map_v2/landmarks.geojson',
          cache: false,
        ),
        (widget.bundle ?? rootBundle).loadString(
          'assets/quizipedia/country_interesting_facts.json',
          cache: false,
        ),
      ]);
      final details = await Future.wait([riverFuture, lakeFuture]);
      try {
        final atlas = jsonDecode(
          await (widget.bundle ?? rootBundle).loadString(
            'assets/quizipedia/food_atlas.json',
            cache: false,
          ),
        ) as Map<String, dynamic>;
        dishes = atlas['dishes'] as List? ?? [];
        foodSources = atlas['sources'] as List? ?? [];
      } catch (_) {
        dishes = [];
      }
      try {
        final waterData = jsonDecode(
          await (widget.bundle ?? rootBundle).loadString(
            'assets/quizipedia/country_waters.json',
            cache: false,
          ),
        ) as Map<String, dynamic>;
        waters = waterData['countries'] as Map<String, dynamic>? ?? {};
        waterSources = waterData['sources'] as List? ?? [];
      } catch (_) {
        waters = {};
        waterSources = [];
      }
      try {
        featureFacts = jsonDecode(
          await (widget.bundle ?? rootBundle).loadString(
            'assets/quizipedia/map_feature_facts.json',
            cache: false,
          ),
        ) as Map<String, dynamic>;
      } catch (_) {
        featureFacts = {};
      }
      if (!mounted || generation != attempt) return;
      riverDetail = details[0];
      lakeDetail = details[1];
      countries = jsonDecode(texts[0]) as Map<String, dynamic>;
      capitals = jsonDecode(texts[1]) as Map<String, dynamic>;
      waterways = jsonDecode(texts[2]) as Map<String, dynamic>;
      countryLabels = jsonDecode(texts[3]) as Map<String, dynamic>;
      final facts =
          (jsonDecode(texts[4]) as Map<String, dynamic>)['countries'] as List;
      final byId = {for (final f in facts) f['id']: f};
      flags =
          (jsonDecode(texts[5]) as Map<String, dynamic>)['flags']
              as Map<String, dynamic>;
      waterLabels = jsonDecode(texts[6]) as Map<String, dynamic>;
      landmarks = jsonDecode(texts[7]) as Map<String, dynamic>;
      final interesting =
          (jsonDecode(texts[8]) as Map<String, dynamic>)['countries']
              as Map<String, dynamic>;
      final landmarkItems = (landmarks!['features'] as List)
          .map(
            (f) => MapLandmark.fromProperties(
              f['properties'] as Map<String, dynamic>,
            ),
          )
          .toList();
      final items = <MapCountry>[];
      for (final feature in countryLabels!['features'] as List) {
        final p = feature['properties'] as Map<String, dynamic>;
        final f = byId[p['country_id']];
        items.add(
          MapCountry(
            id: p['country_id'],
            nameRu: p['name_ru'],
            nameEn: p['name_en'],
            capital: f?['capital'],
            region: f?['region'],
            subregion: f?['subregion'],
            neighbors: (f?['neighbors'] as List? ?? const [])
                .whereType<String>()
                .toList(),
            area: f?['area_km2'],
            population: (f?['population'] as num?) == 0
                ? null
                : f?['population'],
            populationYear: f?['population_year'] == 0
                ? null
                : f?['population_year'],
            currencies:
                (f?['currencies'] as List?)
                    ?.whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .toList() ??
                const [],
            languages:
                (f?['languages'] as List?)
                    ?.whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .toList() ??
                const [],
            interestingFacts:
                (interesting[p['country_id']] as List? ?? const [])
                    .map(MapInterestingFact.fromJson)
                    .whereType<MapInterestingFact>()
                    .toList(),
          ),
        );
      }
      final existingIds = items.map((item) => item.id).toSet();
      for (final f in facts) {
        if (existingIds.contains(f['id'])) continue;
        items.add(
          MapCountry(
            id: f['id'],
            nameRu: f['name_ru'] ?? f['name_en'],
            nameEn: f['name_en'],
            capital: f['capital'],
            region: f['region'],
            subregion: f['subregion'],
            area: f['area_km2'],
            population: f['population'] == 0 ? null : f['population'],
            populationYear: f['population_year'] == 0
                ? null
                : f['population_year'],
            currencies: (f['currencies'] as List? ?? const [])
                .whereType<String>()
                .toList(),
            languages: (f['languages'] as List? ?? const [])
                .whereType<String>()
                .toList(),
            neighbors: (f['neighbors'] as List? ?? const [])
                .whereType<String>()
                .toList(),
            interestingFacts: (interesting[f['id']] as List? ?? const [])
                .map(MapInterestingFact.fromJson)
                .whereType<MapInterestingFact>()
                .toList(),
          ),
        );
      }
      if (mounted) {
        setState(() {
          state = MapState(items, landmarks: landmarkItems);
          if (widget.visibleCountryIds != null) {
            visible = items
                .where((item) => widget.visibleCountryIds!.contains(item.id))
                .toList();
          }
          ready = widget.mapBuilder != null;
        });
      }
      if (widget.mapBuilder == null) {
        startupTimer = Timer(const Duration(seconds: 90), () {
          if (mounted && generation == attempt && !ready) {
            debugPrint('Knowledge map: initialization timed out');
            setState(() => failed = true);
          }
        });
      }
    } catch (error, stack) {
      debugPrint('Knowledge map: asset load failed: $error\n$stack');
      if (mounted && generation == attempt) setState(() => failed = true);
    }
  }

  Future<void> setup() async {
    final c = controller;
    if (c == null) return;
    final attempt = generation;
    thematicSprites.clear();
    thematicSequence++;
    var stage = 'countries';
    try {
      await c.addGeoJsonSource('countries', countries!);
      await c.addFillLayer(
        'countries',
        'land',
        const FillLayerProperties(fillColor: '#f4efd9'),
      );
      await c.addLineLayer(
        'countries',
        'borders',
        const LineLayerProperties(lineColor: '#b2a996', lineWidth: 0.8),
      );
      await c.addLineLayer(
        'countries',
        'selected',
        const LineLayerProperties(lineColor: '#ce773f', lineWidth: 3),
        filter: [
          '==',
          ['get', 'country_id'],
          '',
        ],
      );
      await c.addLineLayer(
        'countries',
        'hovered',
        const LineLayerProperties(lineColor: '#bd6d3c', lineWidth: 2),
        filter: [
          '==',
          ['get', 'country_id'],
          '',
        ],
      );
      stage = 'waterways';
      await c.addGeoJsonSource('waterways', waterways!);
      if (!mounted || generation != attempt || controller != c || failed) {
        return;
      }
      if (lakeDetail != null) {
        try {
          await c.addGeoJsonSource('lakes-detail', lakeDetail!);
          await c.addFillLayer(
            'lakes-detail',
            'lakes-detail',
            const FillLayerProperties(fillColor: '#b9dfe9'),
            minzoom: 4,
            enableInteraction: true,
          );
          if (!mounted || generation != attempt || controller != c || failed) {
            return;
          }
          detailLakesReady = true;
        } catch (error) {
          debugPrint('Knowledge map: detailed lakes unavailable: $error');
        }
      }
      if (!mounted || generation != attempt || controller != c || failed) {
        return;
      }
      if (riverDetail != null) {
        try {
          await c.addGeoJsonSource('rivers-detail', riverDetail!);
          await c.addLineLayer(
            'rivers-detail',
            'rivers-detail',
            const LineLayerProperties(lineColor: '#91c9d9', lineWidth: 1.2),
            minzoom: 4,
            enableInteraction: true,
          );
          if (!mounted || generation != attempt || controller != c || failed) {
            return;
          }
          detailRiversReady = true;
        } catch (error) {
          debugPrint('Knowledge map: detailed rivers unavailable: $error');
        }
      }
      if (!mounted || generation != attempt || controller != c || failed) {
        return;
      }
      await c.addFillLayer(
        'waterways',
        'lakes',
        const FillLayerProperties(fillColor: '#b9dfe9'),
        maxzoom: detailLakesReady ? 4 : null,
        filter: [
          '==',
          ['get', 'kind'],
          'lake',
        ],
      );
      await c.addLineLayer(
        'waterways',
        'rivers',
        const LineLayerProperties(lineColor: '#91c9d9', lineWidth: 1.2),
        maxzoom: detailRiversReady ? 4 : null,
        filter: [
          '==',
          ['get', 'kind'],
          'river',
        ],
      );
      stage = 'capitals';
      await c.addGeoJsonSource('capitals', capitals!);
      await c.addImage('capital-star', await renderCapitalMarker());
      await c.addSymbolLayer(
        'capitals',
        'capital-dots',
        const SymbolLayerProperties(
          iconImage: 'capital-star',
          iconAllowOverlap: true,
        ),
        minzoom: 2.5,
      );
      stage = 'country markers';
      final localizedRu = ru;
      for (final feature in countryLabels!['features'] as List) {
        if (!mounted || generation != attempt || controller != c || failed) {
          return;
        }
        final properties = feature['properties'] as Map<String, dynamic>;
        final id = properties['country_id'] as String;
        final encoded = flags[id] as String?;
        final bytes = await renderCountryMarker(
          name: properties[localizedRu ? 'name_ru' : 'name_en'] as String,
          flagBytes: encoded == null ? null : base64Decode(encoded),
          compact: true,
        );
        if (!mounted || generation != attempt || controller != c || failed) {
          return;
        }
        await c.addImage('country-$id', bytes);
        properties['sprite'] = 'country-$id';
      }
      await c.addGeoJsonSource('country-markers', countryLabels!);
      appliedCountryLabels =
          jsonDecode(jsonEncode(countryLabels)) as Map<String, dynamic>;
      appliedThematic = 'none';
      await c.addSymbolLayer(
        'country-markers',
        'country-markers',
        const SymbolLayerProperties(
          iconImage: ['get', 'sprite'],
          iconSize: 1.0,
        ),
      );
      Future<void> addLabels(
        String source,
        Map<String, dynamic> collection,
        String prefix,
        double minZoom,
      ) async {
        for (final feature in collection['features'] as List) {
          if (!mounted || generation != attempt || controller != c || failed) {
            return;
          }
          final p = feature['properties'] as Map<String, dynamic>;
          final id = p['id'] as String;
          if (source == 'landmarks') {
            p['map_category'] = placeCategory(
              p['categories'] as List? ?? const [],
            );
          }
          final country = source == 'capital-labels'
              ? state?.countryById(p['country_id'])
              : null;
          final countryName = country == null
              ? null
              : (localizedRu ? country.nameRu : country.nameEn);
          final name = '$prefix${p[localizedRu ? 'name_ru' : 'name_en']}';
          final marker = await renderCountryMarker(
            name: countryName == null ? name : '$name · $countryName',
            landmark: source == 'landmarks',
            wonder:
                source == 'landmarks' &&
                placeCategory(p['categories'] as List? ?? const []) ==
                    'wonders',
            capital: source == 'capital-labels',
          );
          if (!mounted || generation != attempt || controller != c || failed) {
            return;
          }
          await c.addImage('$source-$id', marker);
          p['sprite'] = '$source-$id';
        }
        if (!mounted || generation != attempt || controller != c || failed) {
          return;
        }
        await c.addGeoJsonSource(source, collection);
        await c.addSymbolLayer(
          source,
          source,
          SymbolLayerProperties(
            iconImage: const ['get', 'sprite'],
            iconSize: source == 'capital-labels'
                ? const [
                    'interpolate',
                    ['linear'],
                    ['zoom'],
                    4,
                    1.5,
                    7,
                    2,
                  ]
                : 1,
            iconAnchor: source == 'capital-labels'
                ? 'bottom'
                : source == 'landmarks'
                ? 'top'
                : 'center',
            iconOffset: source == 'capital-labels'
                ? const [0, -4]
                : source == 'landmarks'
                ? const [0, 4]
                : const [0, 0],
          ),
          minzoom: minZoom,
        );
      }

      stage = 'capital labels';
      await addLabels('capital-labels', capitals!, '', 4);
      stage = 'water labels';
      await addLabels('water-labels', waterLabels!, '≈ ', 3);
      stage = 'landmarks';
      await addLabels('landmarks', landmarks!, '', 3.5);
      await c.addCircleLayer(
        'landmarks',
        'landmark-pins',
        const CircleLayerProperties(
          circleRadius: 4,
          circleColor: [
            'match',
            ['get', 'map_category'],
            'mountains',
            '#7253ad',
            'depressions',
            '#397ab0',
            'deserts',
            '#cc8220',
            'reserves',
            '#258054',
            'wonders',
            '#bf4672',
            '#247a83',
          ],
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 1.5,
        ),
        minzoom: 1.5,
      );
      if (!mounted || generation != attempt || controller != c || failed) {
        return;
      }
      startupTimer?.cancel();
      setState(() => ready = true);
      updateVisibleCountries();
    } catch (error, stack) {
      debugPrint('Knowledge map: setup failed at $stage: $error\n$stack');
      if (mounted && generation == attempt) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    startupTimer?.cancel();
    hoverTimer?.cancel();
    hover.clear();
    controller?.onMapMouseMove.remove(onMouseMove);
    super.dispose();
  }

  List<MapCountry> get practiceCountries {
    final mapped = (countries?['features'] as List? ?? const [])
        .map((f) => f['properties']['country_id'])
        .whereType<String>()
        .toSet();
    return (state?.countries ?? const <MapCountry>[])
        .where(
          (country) =>
              mapped.contains(country.id) &&
              (practiceMode != 1 && practiceMode != 3 ||
                  flags[country.id] is String),
        )
        .toList();
  }

  Future<void> practiceVisibility(bool show) async {
    final c = controller;
    if (c == null || !ready) return;
    for (final entry in <String, bool>{
      'country-markers': show && showCountryLabels,
      'capital-labels': show && showCapitals,
      'capital-dots': show && showCapitals,
      'landmarks': show && showLandmarks,
      'landmark-pins': show && showLandmarks,
      'water-labels': show && showWaterLabels,
    }.entries) {
      await c.setLayerVisibility(entry.key, entry.value);
    }
    await c.setFilter('selected', [
      '==',
      ['get', 'country_id'],
      '',
    ]);
  }

  Future<void> nextPractice() async {
    if (practiceBusy || !mounted || !practice) return;
    setState(() => practiceBusy = true);
    try {
      final candidates = practiceCountries..shuffle();
      if (candidates.isEmpty) {
        setState(() {
          practiceTarget = null;
          practiceOptions = [];
          practiceResult = null;
        });
        return;
      }
      final target = candidates.first;
      final options = candidates.take(4).toList()..shuffle();
      setState(() {
        practiceTarget = target.id;
        practiceOptions = options;
        practiceResult = null;
      });
      final c = controller;
      if (c == null || !ready) return;
      await c.setFilter('selected', [
        '==',
        ['get', 'country_id'],
        practiceMode >= 2 ? target.id : '',
      ]);
      if (!mounted || !practice || practiceMode < 2) return;
      final matches = (countryLabels?['features'] as List? ?? const []).where(
        (f) => f['properties']['country_id'] == target.id,
      );
      if (matches.isNotEmpty) {
        final coordinates = matches.first['geometry']['coordinates'] as List;
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              (coordinates[1] as num).toDouble(),
              (coordinates[0] as num).toDouble(),
            ),
            3,
          ),
        );
      }
    } catch (error, stack) {
      debugPrint('Knowledge map: practice failed: $error\n$stack');
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => practiceBusy = false);
    }
  }

  Future<void> setPractice(bool value) async {
    if (!mounted || practiceBusy) return;
    clearHover();
    setState(() {
      practice = value;
      practiceBusy = true;
      state?.select(null);
      selectedFeature = null;
      selectedFeatureKind = null;
      browserOpen = false;
      placesOpen = false;
      visibleOpen = false;
      layersOpen = false;
    });
    try {
      await practiceVisibility(!value);
    } catch (error, stack) {
      debugPrint('Knowledge map: practice visibility failed: $error\n$stack');
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => practiceBusy = false);
    }
    if (value && mounted && practice && !failed) await nextPractice();
  }

  Future<void> select(String? id, {bool move = false}) async {
    if (!mounted) return;
    if (practice) {
      if (!practiceBusy &&
          practiceMode < 2 &&
          id != null &&
          practiceResult != true) {
        setState(() => practiceResult = id == practiceTarget);
      }
      return;
    }
    tapRequests.invalidate();
    FocusScope.of(context).unfocus();
    final c = controller;
    final attempt = generation;
    setState(() {
      state?.select(id);
      placesOpen = false;
      countryDetailsOpen = false;
      if (id != null) {
        visibleOpen = false;
        browserOpen = false;
      }
      selectedFeature = null;
      selectedFeatureKind = null;
      layersOpen = false;
    });
    if (!ready || c == null) return;
    try {
      await c.setFilter('selected', [
        '==',
        ['get', 'country_id'],
        id ?? '',
      ]);
      if (!mounted || generation != attempt || controller != c) return;
      if (move &&
          id != null &&
          capitals != null &&
          (countries!['features'] as List).any(
            (f) => f['properties']['country_id'] == id,
          )) {
        final matches = (capitals!['features'] as List).where(
          (f) => f['properties']['country_id'] == id,
        );
        if (matches.isNotEmpty) {
          final coordinates = matches.first['geometry']['coordinates'] as List;
          await c.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                (coordinates[1] as num).toDouble(),
                (coordinates[0] as num).toDouble(),
              ),
              4,
            ),
          );
        }
      }
    } catch (error, stack) {
      debugPrint('Knowledge map: selection command failed: $error\n$stack');
      if (mounted && generation == attempt && controller == c) {
        setState(() => failed = true);
      }
    }
  }

  Future<void> selectFeature(
    String kind,
    Map<String, dynamic> properties,
  ) async {
    if (!mounted) return;
    tapRequests.invalidate();
    FocusScope.of(context).unfocus();
    final waterId = properties['water_id'];
    if (waterId is String && waterways != null) {
      final match = (waterways!['features'] as List)
          .map((f) => f['properties'] as Map)
          .where((p) => p['id'] == waterId && p['kind'] == kind)
          .firstOrNull;
      if (match != null) {
        properties = {
          ...properties,
          'fact_id': waterId,
          'name_en': match['name_en'],
          'name_ru': match['name_ru'],
        };
      }
    }
    setState(() {
      state?.select(null);
      visibleOpen = false;
      selectedFeatureKind = kind;
      selectedFeature = properties;
      placesOpen = false;
      layersOpen = false;
    });
    final c = controller;
    if (c != null && ready) {
      await c.setFilter('selected', [
        '==',
        ['get', 'country_id'],
        '',
      ]);
    }
  }

  Future<List> queryCountryMarkers(
    MapLibreMapController c,
    math.Point<double> point,
  ) async {
    return c.queryRenderedFeatures(point, ['country-markers'], null);
  }

  Future<void> tap(math.Point<double> point, LatLng position) async {
    final c = controller;
    final attempt = generation;
    if (!mounted || !ready || c == null) return;
    final request = tapRequests.begin();
    bool current() =>
        mounted &&
        generation == attempt &&
        controller == c &&
        tapRequests.isCurrent(request);
    try {
      if (practice) {
        if (practiceMode < 2) {
          final hits = await c.queryRenderedFeatures(point, ['land'], null);
          if (current() && hits.isNotEmpty) {
            await select(hits.first['properties']['country_id'] as String?);
          }
        }
        return;
      }
      var features = await c.queryRenderedFeatures(point, [
        'landmarks',
        'landmark-pins',
      ], null);
      if (!current()) return;
      if (features.isNotEmpty) {
        await selectLandmark(features.first['properties']['id'] as String);
        return;
      }
      for (final entry in <String, List<String>>{
        'capital': ['capital-labels', 'capital-dots'],
        'water': [
          'water-labels',
          'lakes',
          'rivers',
          if (detailLakesReady) 'lakes-detail',
          if (detailRiversReady) 'rivers-detail',
        ],
      }.entries) {
        features = await c.queryRenderedFeatures(point, entry.value, null);
        if (!current()) return;
        if (features.isNotEmpty) {
          final p = Map<String, dynamic>.from(
            features.first['properties'] as Map,
          );
          await selectFeature(
            entry.key == 'water'
                ? (p['kind'] as String? ?? 'water')
                : entry.key,
            p,
          );
          return;
        }
      }
      features = await queryCountryMarkers(c, point);
      if (!current()) return;
      final markerTapped = features.isNotEmpty;
      if (features.isEmpty) {
        features = await c.queryRenderedFeatures(point, ['land'], null);
        if (!current()) return;
      }
      final id = features.isEmpty
          ? null
          : features.first['properties']['country_id'] as String?;
      await select(id);
      if (markerTapped &&
          id != null &&
          mounted &&
          generation == attempt &&
          controller == c &&
          state?.selectedId == id) {
        final matches = (countryLabels?['features'] as List? ?? const []).where(
          (f) => f['properties']['country_id'] == id,
        );
        if (matches.isNotEmpty) {
          final coordinates = matches.first['geometry']['coordinates'] as List;
          await c.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(
                (coordinates[1] as num).toDouble(),
                (coordinates[0] as num).toDouble(),
              ),
            ),
          );
        }
      }
    } catch (error, stack) {
      debugPrint('Knowledge map: tap failed: $error\n$stack');
      if (current()) {
        setState(() => failed = true);
      }
    }
  }

  Future<void> setThematic(String value) async {
    if (!mounted || !ready) return;
    setState(() => thematic = value);
    final request = ++thematicSequence;
    final c = controller;
    if (c == null || countryLabels == null || state == null) return;
    thematicCommands = thematicCommands
        .catchError((Object _) {})
        .then((_) => _applyThematic(value, request, c));
    await thematicCommands;
  }

  Future<void> _applyThematic(
    String value,
    int request,
    MapLibreMapController c,
  ) async {
    if (!mounted || request != thematicSequence || controller != c) return;
    final attempt = generation;
    final labels = jsonDecode(
      jsonEncode(appliedCountryLabels ?? countryLabels),
    ) as Map<String, dynamic>;
    try {
      for (final feature in labels['features'] as List) {
        if (!mounted ||
            generation != attempt ||
            controller != c ||
            request != thematicSequence) {
          return;
        }
        final p = feature['properties'] as Map<String, dynamic>;
        final id = p['country_id'] as String;
        final country = state!.countries
            .where((item) => item.id == id)
            .firstOrNull;
        final matches = dishes
            .where(
              (dish) => dish is Map && dish['country_en'] == country?.nameEn,
            )
            .toList();
        final uniqueCountry =
            country != null &&
            state!.countries
                    .where((item) => item.nameEn == country.nameEn)
                    .length ==
                1;
        final datum = value == 'food'
            ? (uniqueCountry && matches.isNotEmpty
                  ? matches
                        .map((dish) => dish[ru ? 'name_ru' : 'name_en'])
                        .whereType<String>()
                        .join(', ')
                  : null)
            : value == 'population'
            ? country?.population
            : value == 'capital'
            ? capitalThematicLabel(country, russian: ru)
            : country?.area;
        final suffix = value == 'none'
            ? ''
            : value == 'population' || value == 'area'
            ? '\n${thematicNumberLabel(datum as num?, russian: ru, area: value == 'area')}'
            : '\n${datum ?? tr('No data', 'Нет данных')}';
        final name = p[ru ? 'name_ru' : 'name_en'] as String;
        final sprite = 'country-$id-$value-${ru ? 'ru' : 'en'}';
        late Uint8List bytes;
        await ensureMapSprite(
          thematicSprites,
          sprite,
          () async {
            final encoded = flags[id] as String?;
            bytes = await renderCountryMarker(
              name: '$name$suffix',
              maxLines: value == 'none' ? null : 4,
              flagBytes: encoded == null ? null : base64Decode(encoded),
              compact: true,
            );
          },
          () async {
            if (!mounted ||
                generation != attempt ||
                controller != c ||
                request != thematicSequence) {
              throw StateError('Thematic request superseded');
            }
            await c.addImage(sprite, bytes);
          },
        );
        if (!mounted ||
            generation != attempt ||
            controller != c ||
            request != thematicSequence) {
          return;
        }
        p['sprite'] = sprite;
      }
      if (mounted &&
          generation == attempt &&
          controller == c &&
          request == thematicSequence) {
        final previous = appliedCountryLabels;
        if (previous == null) return;
        await commitCountryLabelsUpdate(
          update: () => c.setGeoJsonSource('country-markers', labels),
          commit: () {
            appliedCountryLabels = labels;
            appliedThematic = value;
          },
        );
      }
    } catch (error) {
      if (mounted && generation == attempt && request == thematicSequence) {
        setState(() => thematic = appliedThematic);
      }
      debugPrint('Knowledge map: thematic labels unavailable: $error');
    }
  }

  Future<void> toggleCapitals(bool value) async {
    if (!mounted || !ready) return;
    final c = controller;
    final attempt = generation;
    setState(() => showCapitals = value);
    capitalCommands = capitalCommands.catchError((Object _) {}).then((_) async {
      if (!mounted ||
          generation != attempt ||
          controller != c ||
          c == null ||
          showCapitals != value) {
        return;
      }
      try {
        await c.setLayerVisibility('capital-dots', value);
        if (!mounted ||
            generation != attempt ||
            controller != c ||
            showCapitals != value) {
          return;
        }
        await c.setLayerVisibility('capital-labels', value);
      } catch (error, stack) {
        debugPrint('Knowledge map: layer command failed: $error\n$stack');
        if (mounted && generation == attempt && controller == c) {
          setState(() => failed = true);
        }
      }
    });
    await capitalCommands;
  }

  Future<void> setPlacesCategory(String value) async {
    setState(() => placesCategory = value);
    final c = controller;
    if (c == null || !ready || landmarks == null) return;
    final ids = (landmarks!['features'] as List)
        .where(
          (f) =>
              value == 'all' ||
              (f['properties']['categories'] as List? ?? const []).contains(
                value,
              ),
        )
        .map((f) => f['properties']['id'] as String)
        .toList();
    final attempt = generation;
    placesCommands = placesCommands.catchError((Object _) {}).then((_) async {
      if (!mounted ||
          controller != c ||
          generation != attempt ||
          placesCategory != value) {
        return;
      }
      try {
        final filter = [
          'in',
          ['get', 'id'],
          ['literal', ids],
        ];
        await c.setFilter('landmarks', filter);
        if (mounted && controller == c && generation == attempt) {
          await c.setFilter('landmark-pins', filter);
        }
      } catch (error) {
        debugPrint('Knowledge map: place filter failed: $error');
      }
    });
    await placesCommands;
  }

  Future<void> openPlace(String id) async {
    final matches = (landmarks?['features'] as List? ?? const []).where(
      (f) => f['properties']['id'] == id,
    );
    if (matches.isEmpty) return;
    final coordinates = matches.first['geometry']['coordinates'] as List;
    setState(() => placesOpen = false);
    await selectLandmark(id);
    final c = controller;
    if (!mounted || !ready || c == null || state?.selectedLandmarkId != id) {
      return;
    }
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            (coordinates[1] as num).toDouble(),
            (coordinates[0] as num).toDouble(),
          ),
          5.5,
        ),
      );
    } catch (error) {
      debugPrint('Knowledge map: place camera failed: $error');
    }
  }

  Future<void> selectLandmark(String? id) async {
    if (!mounted) return;
    tapRequests.invalidate();
    FocusScope.of(context).unfocus();
    final c = controller;
    final attempt = generation;
    setState(() {
      state?.selectLandmark(id);
      if (id != null) {
        visibleOpen = false;
        placesOpen = false;
      }
      selectedFeature = null;
      selectedFeatureKind = null;
      layersOpen = false;
    });
    if (!ready || c == null) return;
    try {
      await c.setFilter('selected', [
        '==',
        ['get', 'country_id'],
        '',
      ]);
    } catch (error, stack) {
      debugPrint('Knowledge map: landmark selection failed: $error\n$stack');
      if (mounted && generation == attempt && controller == c) {
        setState(() => failed = true);
      }
    }
  }

  Future<void> toggleLandmarks(bool value) async {
    if (!mounted || !ready) return;
    final c = controller;
    final attempt = generation;
    setState(() {
      showLandmarks = value;
      if (!value && state?.selectedLandmark != null) {
        state?.selectLandmark(null);
      }
    });
    if (!value) clearHover();
    try {
      await c?.setLayerVisibility('landmarks', value);
      await c?.setLayerVisibility('landmark-pins', value);
    } catch (error, stack) {
      debugPrint('Knowledge map: landmark layer failed: $error\n$stack');
      if (mounted && generation == attempt && controller == c) {
        setState(() => failed = true);
      }
    }
  }

  Future<void> toggleLabels(String layer, bool value) async {
    if (!mounted || !ready) return;
    final c = controller;
    final attempt = generation;
    setState(() {
      if (layer == 'country-markers') {
        showCountryLabels = value;
      } else {
        showWaterLabels = value;
      }
    });
    bool current() => layer == 'country-markers'
        ? showCountryLabels == value
        : showWaterLabels == value;
    Future<void> applyVisibility() async {
      if (!mounted ||
          generation != attempt ||
          controller != c ||
          c == null ||
          !current()) {
        return;
      }
      try {
        await c.setLayerVisibility(layer, value);
      } catch (error, stack) {
        debugPrint('Knowledge map: label visibility failed: $error\n$stack');
        if (mounted && generation == attempt && controller == c) {
          setState(() => failed = true);
        }
      }
    }

    if (layer == 'country-markers') {
      thematicCommands = thematicCommands
          .catchError((Object _) {})
          .then((_) => applyVisibility());
      await thematicCommands;
    } else {
      labelCommands = labelCommands
          .catchError((Object _) {})
          .then((_) => applyVisibility());
      await labelCommands;
    }
  }

  void clearHover() {
    hoverTimer?.cancel();
    hover.clear();
    if (mounted) setState(() {});
    queueHoverFilter();
  }

  Future<void> updateVisibleCountries() async {
    if (!mounted) return;
    final c = controller;
    final currentState = state;
    final size = mapViewport;
    if (!ready || c == null || currentState == null || size.isEmpty) return;
    final request = ++visibleRequest;
    try {
      bool current() => mounted && request == visibleRequest && controller == c;
      final scale = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? MediaQuery.devicePixelRatioOf(context)
          : 1.0;
      final features = await queryVisibleWithRetry(
        () => c.queryRenderedFeaturesInRect(Offset.zero & (size * scale), [
          'land',
        ], null),
        current,
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      if (!current()) return;
      final result = visibleCountries(currentState.countries, features);
      setState(() => visible = result);
      if (practice || countryLabels == null || appliedCountryLabels == null) {
        return;
      }
      final bounds = await c.getVisibleRegion();
      if (!current()) return;
      final viewport = GeoViewport(
        west: bounds.southwest.longitude,
        east: bounds.northeast.longitude,
        south: bounds.southwest.latitude,
        north: bounds.northeast.latitude,
      );
      final anchors = visibleCountryLabelAnchors(
        countryLabels!['features'] as List,
        features,
        viewport,
        fullOutlines: countries!['features'] as List,
      );
      if (mapEquals(anchors, labelOverrides)) return;
      thematicCommands = thematicCommands.catchError((Object _) {}).then((
        _,
      ) async {
        if (!current() ||
            appliedCountryLabels == null ||
            countryLabels == null) {
          return;
        }
        final labels = jsonDecode(
          jsonEncode(appliedCountryLabels),
        ) as Map<String, dynamic>;
        final originals = <String, dynamic>{
          for (final feature in countryLabels!['features'] as List)
            feature['properties']['country_id'] as String:
                feature['geometry']['coordinates'],
        };
        for (final feature in labels['features'] as List) {
          final id = feature['properties']['country_id'] as String;
          final anchor = anchors[id];
          feature['geometry']['coordinates'] = anchor == null
              ? originals[id]
              : [anchor.$1, anchor.$2];
        }
        await c.setGeoJsonSource('country-markers', labels);
        if (current()) {
          appliedCountryLabels = labels;
          labelOverrides = anchors;
        }
      });
      await thematicCommands;
    } catch (error) {
      if (mounted && request == visibleRequest && controller == c) {
        setState(() => visible = []);
      }
      debugPrint('Knowledge map: visible countries unavailable: $error');
    }
  }

  void queueHoverFilter() {
    final c = controller;
    final attempt = generation;
    final id = hover.countryId;
    hoverFilter = hoverFilter.catchError((Object _) {}).then((_) async {
      if (!mounted ||
          !ready ||
          generation != attempt ||
          controller != c ||
          c == null ||
          id != hover.countryId) {
        return;
      }
      try {
        await c.setFilter('hovered', [
          '==',
          ['get', 'country_id'],
          id ?? '',
        ]);
      } catch (error, stack) {
        debugPrint('Knowledge map: hover outline failed: $error\n$stack');
      }
    });
  }

  void setTestHover(String? id, Offset point) {
    if (!mounted) return;
    final request = hover.begin();
    hover.complete(request, id, point);
    setState(() {});
    queueHoverFilter();
  }

  void setTestLandmarkHover(String? id, Offset point) {
    if (!mounted) return;
    final request = hover.begin();
    if (id == null) {
      hover.complete(request, null, point);
    } else {
      hover.completeLandmark(request, id, point);
    }
    setState(() {});
    queueHoverFilter();
  }

  void onMouseMove(math.Point<double> point, LatLng coordinates) {
    if (!mounted || !ready || controller == null || practice) return;
    final request = hover.begin();
    final attempt = generation;
    final c = controller!;
    hoverTimer?.cancel();
    hoverTimer = Timer(const Duration(milliseconds: 40), () async {
      try {
        bool current() =>
            mounted &&
            generation == attempt &&
            controller == c &&
            hover.isCurrent(request);
        var features = await c.queryRenderedFeatures(point, [
          'landmarks',
          'landmark-pins',
        ], null);
        if (!current()) return;
        if (features.isNotEmpty) {
          final id = features.first['properties']['id'] as String;
          if (hover.completeLandmark(request, id, Offset(point.x, point.y))) {
            setState(() {});
            queueHoverFilter();
          }
          return;
        }
        features = await queryCountryMarkers(c, point);
        if (!current()) return;
        if (features.isEmpty) {
          final water = await c.queryRenderedFeatures(point, [
            'lakes',
            'rivers',
            if (detailRiversReady) 'rivers-detail',
            if (detailLakesReady) 'lakes-detail',
          ], null);
          if (!current()) return;
          if (water.isEmpty) {
            features = await c.queryRenderedFeatures(point, ['land'], null);
            if (!current()) return;
          }
        }
        final id = features.isEmpty
            ? null
            : features.first['properties']['country_id'] as String?;
        if (hover.complete(request, id, Offset(point.x, point.y))) {
          setState(() {});
          queueHoverFilter();
        }
      } catch (error, stack) {
        debugPrint('Knowledge map: hover query failed: $error\n$stack');
        if (mounted &&
            generation == attempt &&
            controller == c &&
            hover.isCurrent(request)) {
          hover.complete(request, null, Offset(point.x, point.y));
          setState(() {});
          queueHoverFilter();
        }
      }
    });
  }

  Widget _detailCard({
    required Size viewport,
    required String title,
    String? subtitle,
    Widget? leading,
    required VoidCallback onClose,
    required List<Widget> children,
    bool countryPanel = false,
  }) {
    return PointerInterceptor(
      child: ConstrainedBox(
        key: countryPanel ? const ValueKey('country-bottom-panel') : null,
        constraints: BoxConstraints(
          maxWidth: countryPanel
              ? viewport.width
              : math.min(360, math.max(0, viewport.width - 24)),
          maxHeight: countryPanel
              ? viewport.height
              : math.max(
                  0,
                  math.min(
                    340,
                    viewport.height - (visible.isNotEmpty ? 240 : 84),
                  ),
                ),
        ),
        child: Material(
          elevation: 4,
          color: const Color(0xfffaf9f6),
          borderRadius: countryPanel
              ? (countryPanelOnSide
                    ? const BorderRadius.horizontal(left: Radius.circular(20))
                    : const BorderRadius.vertical(top: Radius.circular(20)))
              : BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (countryPanel && !countryPanelOnSide)
                GestureDetector(
                  key: const ValueKey('country-panel-resize'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) => setState(() {
                    countryPanelHeight =
                        ((countryPanelHeight ??
                                    math.min(340, viewport.height * 0.45)) -
                                details.delta.dy)
                            .clamp(
                              viewport.height * 0.2,
                              viewport.height * 0.8,
                            );
                  }),
                  child: SizedBox(
                    height: 24,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xffaaa3ad),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                child: Row(
                  children: [
                    if (leading != null) ...[leading, const SizedBox(width: 8)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (countryPanel)
                      IconButton(
                        tooltip: countryPanelOnSide
                            ? tr(
                                'Move panel to bottom',
                                'Переместить панель вниз',
                              )
                            : tr(
                                'Move panel to side',
                                'Переместить панель вбок',
                              ),
                        onPressed: () => setState(
                          () => countryPanelOnSide = !countryPanelOnSide,
                        ),
                        icon: Icon(
                          countryPanelOnSide
                              ? Icons.vertical_align_bottom
                              : Icons.vertical_split_outlined,
                        ),
                      ),
                    if (countryPanel)
                      IconButton(
                        tooltip: tr('Layers', 'Слои'),
                        onPressed: () => setState(() {
                          layersOpen = true;
                          countryDetailsOpen = false;
                        }),
                        icon: const Icon(Icons.layers_outlined),
                      ),
                    IconButton(
                      tooltip: tr('Close', 'Закрыть'),
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const regionRu = <String, String>{
    'Africa': 'Африка',
    'Americas': 'Америка',
    'Antarctic': 'Антарктика',
    'Asia': 'Азия',
    'Europe': 'Европа',
    'Oceania': 'Океания',
    'Australia and New Zealand': 'Австралия и Новая Зеландия',
    'Caribbean': 'Карибский регион',
    'Central America': 'Центральная Америка',
    'Central Asia': 'Центральная Азия',
    'Central Europe': 'Центральная Европа',
    'Eastern Africa': 'Восточная Африка',
    'Eastern Asia': 'Восточная Азия',
    'Eastern Europe': 'Восточная Европа',
    'Melanesia': 'Меланезия',
    'Micronesia': 'Микронезия',
    'Middle Africa': 'Центральная Африка',
    'North America': 'Северная Америка',
    'Northern Africa': 'Северная Африка',
    'Northern Europe': 'Северная Европа',
    'Polynesia': 'Полинезия',
    'South America': 'Южная Америка',
    'South-Eastern Asia': 'Юго-Восточная Азия',
    'Southeast Europe': 'Юго-Восточная Европа',
    'Southern Africa': 'Южная Африка',
    'Southern Asia': 'Южная Азия',
    'Southern Europe': 'Южная Европа',
    'Western Africa': 'Западная Африка',
    'Western Asia': 'Западная Азия',
    'Western Europe': 'Западная Европа',
  };

  @override
  Widget build(BuildContext context) {
    final selected = state?.selected;
    final selectedLandmark = state?.selectedLandmark;
    final visibleSorted = [...visible]
      ..sort(
        (a, b) =>
            (ru ? a.nameRu : a.nameEn).compareTo(ru ? b.nameRu : b.nameEn),
      );
    final feature = selectedFeature;
    final featureKind = selectedFeatureKind;
    String countryName(String id) {
      final country = state?.countries.where((c) => c.id == id).firstOrNull;
      return country == null ? id : (ru ? country.nameRu : country.nameEn);
    }

    final unsupported =
        widget.mapBuilder == null &&
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final panelOpen =
                  selected != null &&
                  countryDetailsOpen &&
                  !layersOpen &&
                  !visibleOpen &&
                  !browserOpen &&
                  !placesOpen;
              final panelHeight = panelOpen && !countryPanelOnSide
                  ? (countryPanelHeight ??
                            math.min(340.0, viewport.height * 0.45))
                        .clamp(viewport.height * 0.2, viewport.height * 0.8)
                  : 0.0;
              final panelWidth = panelOpen && countryPanelOnSide
                  ? math.min(360.0, viewport.width * 0.7)
                  : 0.0;
              final mapBottom = practice
                  ? math.min(viewport.height, viewport.height * 0.48 + 12)
                  : panelHeight;
              final currentMapViewport = Size(
                viewport.width - panelWidth,
                viewport.height - mapBottom,
              );
              if (currentMapViewport != mapViewport) {
                mapViewport = currentMapViewport;
                visibleRequest++;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) updateVisibleCountries();
                });
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (state != null && !failed && !unsupported)
                    Positioned(
                      left: 0,
                      right: panelWidth,
                      top: 0,
                      bottom: mapBottom,
                      child:
                          widget.featureMapBuilder?.call(
                            context,
                            selectFeature,
                          ) ??
                          widget.landmarkMapBuilder?.call(
                            context,
                            selectLandmark,
                            setTestLandmarkHover,
                          ) ??
                          widget.hoverMapBuilder?.call(
                            context,
                            select,
                            setTestHover,
                            clearHover,
                          ) ??
                          widget.mapBuilder?.call(context, select) ??
                          MouseRegion(
                            onExit: (_) => clearHover(),
                            child: MapLibreMap(
                              key: ValueKey(generation),
                              disableSymbolPlacementFade: true,
                              styleString: '{"version":8,"sources":{},"layers":[{"id":"sea","type":"background","paint":{"background-color":"#c8e5ed"}}]}',
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(20, 10),
                                zoom: 1.6,
                              ),
                              onMapCreated: (c) {
                                controller = c;
                                c.onMapMouseMove.add(onMouseMove);
                              },
                              onStyleLoadedCallback: setup,
                              onCameraMove: (_) {
                                visibleRequest++;
                                if (visible.isNotEmpty) {
                                  clearHover();
                                  setState(() {
                                    visible = [];
                                    visibleOpen = false;
                                  });
                                }
                              },
                              onCameraIdle: updateVisibleCountries,
                              onMapClick: tap,
                              featureTapsTriggersMapClick: true,
                              compassEnabled: false,
                              attributionButtonPosition:
                                  AttributionButtonPosition.bottomRight,
                            ),
                          ),
                    ),
                  if ((state == null || !ready) && !failed && !unsupported)
                    const Center(child: CircularProgressIndicator()),
                  if (!practice &&
                      visibleOpen &&
                      visible.isNotEmpty &&
                      !layersOpen)
                    Positioned(
                      right: panelWidth + 12,
                      top: 64,
                      child: PointerInterceptor(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: math.max(
                              0,
                              math.min(280, viewport.width - 24),
                            ),
                            height: math.max(
                              0,
                              math.min(300, viewport.height - 220),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        tr(
                                          'Visible countries',
                                          'Страны на карте',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: tr(
                                        'Close visible countries',
                                        'Закрыть список стран',
                                      ),
                                      onPressed: () =>
                                          setState(() => visibleOpen = false),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: visibleSorted.length,
                                    itemBuilder: (context, index) {
                                      final country = visibleSorted[index];
                                      final encoded =
                                          flags[country.id] as String?;
                                      return MouseRegion(
                                        onEnter: (_) {
                                          final request = hover.begin();
                                          hover.complete(
                                            request,
                                            country.id,
                                            Offset.zero,
                                          );
                                          queueHoverFilter();
                                        },
                                        onExit: (_) => clearHover(),
                                        child: ListTile(
                                          dense: true,
                                          leading: encoded == null
                                              ? null
                                              : Image.memory(
                                                  base64Decode(encoded),
                                                  width: 30,
                                                  height: 20,
                                                ),
                                          title: Text(
                                            ru
                                                ? country.nameRu
                                                : country.nameEn,
                                          ),
                                          onTap: () {
                                            setState(() => visibleOpen = false);
                                            clearHover();
                                            select(country.id);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (failed || unsupported)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('Map unavailable', 'Карта недоступна')),
                          if (!unsupported)
                            TextButton(
                              onPressed: load,
                              child: Text(tr('Retry', 'Повторить')),
                            ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: PointerInterceptor(
                      child: IconButton.filledTonal(
                        tooltip: tr('Back', 'Назад'),
                        onPressed:
                            widget.onExit ?? () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                  if (!practice &&
                      state != null &&
                      ready &&
                      !failed &&
                      !unsupported)
                    Positioned(
                      top: 8,
                      left: 64,
                      child: PointerInterceptor(
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          shape: const CircleBorder(),
                          child: PopupMenuButton<String>(
                            tooltip: tr('Map menu', 'Меню карты'),
                            icon: const Icon(Icons.menu),
                            onSelected: (section) {
                              if (section == 'practice') {
                                setPractice(true);
                                return;
                              }
                              setState(() {
                                browserOpen =
                                    section == 'countries' && !browserOpen;
                                placesOpen = section == 'places' && !placesOpen;
                                visibleOpen =
                                    section == 'visible' && !visibleOpen;
                                layersOpen = section == 'data' && !layersOpen;
                                countryDetailsOpen = false;
                              });
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'countries',
                                child: PointerInterceptor(
                                  child: ListTile(
                                    leading: const Icon(Icons.public),
                                    title: Text(tr('Countries', 'Страны')),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'visible',
                                enabled: visible.isNotEmpty,
                                child: PointerInterceptor(
                                  child: ListTile(
                                    leading: const Icon(Icons.map_outlined),
                                    title: Text(
                                      tr(
                                        'Visible countries',
                                        'Страны на карте',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'places',
                                child: PointerInterceptor(
                                  child: ListTile(
                                    leading: const Icon(Icons.place_outlined),
                                    title: Text(tr('Places', 'Места')),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'data',
                                child: PointerInterceptor(
                                  child: ListTile(
                                    leading: const Icon(Icons.layers_outlined),
                                    title: Text(
                                      tr('Map data', 'Данные на карте'),
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'practice',
                                child: PointerInterceptor(
                                  child: ListTile(
                                    leading: const Icon(Icons.quiz_outlined),
                                    title: Text(tr('Practice', 'Тренировка')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (placesOpen && landmarks != null)
                    Positioned(
                      top: viewport.height < 400 ? 0 : 64,
                      left: 12,
                      bottom: viewport.height < 400 ? 0 : 68,
                      width: math.min(420, math.max(0, viewport.width - 24)),
                      child: PointerInterceptor(
                        child: LandmarksBrowser(
                          features: landmarks!['features'] as List,
                          category: placesCategory,
                          russian: ru,
                          onClose: () => setState(() => placesOpen = false),
                          onCategory: setPlacesCategory,
                          onSelect: openPlace,
                        ),
                      ),
                    ),
                  if (!practice &&
                      selected != null &&
                      !panelOpen &&
                      !layersOpen &&
                      !visibleOpen &&
                      !browserOpen &&
                      !placesOpen)
                    Positioned(
                      bottom: 12,
                      left: 76,
                      right: 76,
                      child: Center(
                        child: PointerInterceptor(
                          child: FilledButton.tonalIcon(
                            onPressed: () =>
                                setState(() => countryDetailsOpen = true),
                            icon: const Icon(Icons.info_outline),
                            label: Text(tr('Country details', 'О стране')),
                          ),
                        ),
                      ),
                    ),
                  if (practice)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: PointerInterceptor(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: viewport.height * 0.48,
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tr(
                                              'Map practice',
                                              'Тренировка по карте',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: tr(
                                            'Exit practice',
                                            'Выйти из тренировки',
                                          ),
                                          onPressed: practiceBusy
                                              ? null
                                              : () => setPractice(false),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                    DropdownButton<int>(
                                      value: practiceMode,
                                      isExpanded: true,
                                      items: [
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text(
                                            tr(
                                              'Name → map',
                                              'Название → карта',
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text(
                                            tr('Flag → map', 'Флаг → карта'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 2,
                                          child: Text(
                                            tr(
                                              'Map → name',
                                              'Карта → название',
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 3,
                                          child: Text(
                                            tr('Map → flag', 'Карта → флаг'),
                                          ),
                                        ),
                                      ],
                                      onChanged: practiceBusy
                                          ? null
                                          : (value) {
                                              if (value != null) {
                                                setState(
                                                  () => practiceMode = value,
                                                );
                                                nextPractice();
                                              }
                                            },
                                    ),
                                    if (practiceTarget == null)
                                      Text(
                                        tr(
                                          'No countries available for this mode',
                                          'Для этого режима нет доступных стран',
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        practiceMode < 2
                                            ? tr(
                                                'Find the country on the map',
                                                'Найдите страну на карте',
                                              )
                                            : tr(
                                                'Which country is outlined?',
                                                'Какая страна выделена?',
                                              ),
                                      ),
                                      if (practiceMode == 0)
                                        Text(
                                          ru
                                              ? state!
                                                    .countryById(
                                                      practiceTarget,
                                                    )!
                                                    .nameRu
                                              : state!
                                                    .countryById(
                                                      practiceTarget,
                                                    )!
                                                    .nameEn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      if (practiceMode == 1)
                                        Image.memory(
                                          base64Decode(flags[practiceTarget]),
                                          width: 72,
                                          height: 48,
                                        ),
                                      if (practiceMode >= 2)
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            for (final country
                                                in practiceOptions)
                                              OutlinedButton(
                                                onPressed:
                                                    practiceResult == true
                                                    ? null
                                                    : () => setState(
                                                        () => practiceResult =
                                                            country.id ==
                                                            practiceTarget,
                                                      ),
                                                child: practiceMode == 3
                                                    ? Image.memory(
                                                        base64Decode(
                                                          flags[country.id],
                                                        ),
                                                        width: 48,
                                                        height: 32,
                                                      )
                                                    : Text(
                                                        ru
                                                            ? country.nameRu
                                                            : country.nameEn,
                                                      ),
                                              ),
                                          ],
                                        ),
                                      if (practiceResult != null)
                                        Text(
                                          practiceResult!
                                              ? tr('Correct!', 'Верно!')
                                              : tr(
                                                  'Try again',
                                                  'Попробуйте ещё раз',
                                                ),
                                        ),
                                      TextButton(
                                        onPressed: practiceBusy
                                            ? null
                                            : nextPractice,
                                        child: Text(
                                          practiceResult == true
                                              ? tr('Next', 'Дальше')
                                              : tr('Skip', 'Пропустить'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (browserOpen && state != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 68,
                      top: 64,
                      child: PointerInterceptor(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: CountriesBrowser(
                            onClose: () => setState(() => browserOpen = false),
                            countries: state!.countries,
                            selectedId: state!.selectedId,
                            flags: flags,
                            mappedIds: (countries!['features'] as List)
                                .map((f) => f['properties']['country_id'])
                                .whereType<String>()
                                .toSet(),
                            onSelect: (country) =>
                                select(country.id, move: true),
                          ),
                        ),
                      ),
                    ),
                  if (!practice &&
                      state != null &&
                      !failed &&
                      !unsupported) ...[
                    if (!browserOpen &&
                        !placesOpen &&
                        !visibleOpen &&
                        !layersOpen)
                      Positioned(
                        top: 8,
                        right: panelWidth + 8,
                        child: Column(
                          children: [
                            PointerInterceptor(
                              child: IconButton.filledTonal(
                                tooltip: tr('Zoom in', 'Увеличить'),
                                onPressed: ready
                                    ? () => controller?.animateCamera(
                                        CameraUpdate.zoomIn(),
                                      )
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ),
                            PointerInterceptor(
                              child: IconButton.filledTonal(
                                tooltip: tr('Zoom out', 'Уменьшить'),
                                onPressed: ready
                                    ? () => controller?.animateCamera(
                                        CameraUpdate.zoomOut(),
                                      )
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (layersOpen)
                      Positioned(
                        right: 12,
                        bottom: 68,
                        child: PointerInterceptor(
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: math.min(
                                  360,
                                  math.max(0, viewport.width - 24),
                                ),
                                maxHeight: math.max(0, viewport.height - 80),
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tr('Map data', 'Данные на карте'),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: tr(
                                              'Close map data',
                                              'Закрыть данные карты',
                                            ),
                                            onPressed: () => setState(
                                              () => layersOpen = false,
                                            ),
                                            icon: const Icon(Icons.close),
                                          ),
                                        ],
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          for (final mode in [
                                            'none',
                                            'population',
                                            'area',
                                            'capital',
                                            'food',
                                          ])
                                            ChoiceChip(
                                              label: Text(switch (mode) {
                                                'population' => tr(
                                                  'Population',
                                                  'Население',
                                                ),
                                                'area' => tr('Area', 'Площадь'),
                                                'capital' => tr(
                                                  'Capital',
                                                  'Столица',
                                                ),
                                                'food' => tr('Dishes', 'Блюда'),
                                                _ => tr('Map', 'Карта'),
                                              }),
                                              selected: thematic == mode,
                                              onSelected: ready
                                                  ? (_) => setThematic(mode)
                                                  : null,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!layersOpen &&
                        !visibleOpen &&
                        feature != null &&
                        featureKind != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 68,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _detailCard(
                            viewport: viewport,
                            title:
                                (feature[ru ? 'name_ru' : 'name_en']
                                    as String?) ??
                                tr('Unnamed feature', 'Без названия'),
                            subtitle: switch (featureKind) {
                              'capital' =>
                                '${tr('Capital', 'Столица')} · ${countryName(feature['country_id'] as String? ?? '')}',
                              'lake' => tr('Lake', 'Озеро'),
                              'river' => tr('River', 'Река'),
                              _ => tr('Water', 'Водоём'),
                            },
                            onClose: () => select(null),
                            children: [
                              for (final fact
                                  in ((featureFacts[featureKind == 'capital'
                                                      ? 'capitals'
                                                      : 'waterways']
                                                  as Map?)?[feature['fact_id'] ??
                                                  feature['id']]
                                              as List? ??
                                          const [])
                                      .map(MapInterestingFact.fromJson)
                                      .whereType<MapInterestingFact>()) ...[
                                Text(ru ? fact.textRu : fact.textEn),
                                TextButton(
                                  onPressed: () => launchUrl(
                                    fact.source,
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: Text(tr('Source', 'Источник')),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (!layersOpen && !visibleOpen && selectedLandmark != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 68,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _detailCard(
                            viewport: viewport,
                            title: ru
                                ? selectedLandmark.nameRu
                                : selectedLandmark.nameEn,
                            subtitle: countryName(selectedLandmark.countryId),
                            onClose: () => selectLandmark(null),
                            children: [
                              if (selectedLandmark.thumbnailAsset != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    selectedLandmark.thumbnailAsset!,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                ru
                                    ? selectedLandmark.explanationRu
                                    : selectedLandmark.explanationEn,
                              ),
                              if (selectedLandmark.thumbnailAsset != null &&
                                  selectedLandmark.imageAttribution != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${selectedLandmark.imageAttribution} · ${selectedLandmark.imageLicense ?? ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                              Wrap(
                                spacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(selectedLandmark.sourceUrl),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Text(tr('Source', 'Источник')),
                                  ),
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(
                                        selectedLandmark.coordinateSourceUrl,
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Text(
                                      tr('Coordinates', 'Координаты'),
                                    ),
                                  ),
                                  if (selectedLandmark.thumbnailAsset != null &&
                                      selectedLandmark.imageSourceUrl != null)
                                    TextButton(
                                      onPressed: () => launchUrl(
                                        Uri.parse(
                                          selectedLandmark.imageSourceUrl!,
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Text(
                                        tr('Image source', 'Источник фото'),
                                      ),
                                    ),
                                  if (selectedLandmark.thumbnailAsset != null &&
                                      selectedLandmark.imageLicenseUrl != null)
                                    TextButton(
                                      onPressed: () => launchUrl(
                                        Uri.parse(
                                          selectedLandmark.imageLicenseUrl!,
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Text(
                                        tr('Image licence', 'Лицензия фото'),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (panelOpen)
                      Positioned(
                        left: countryPanelOnSide ? null : 0,
                        right: 0,
                        top: countryPanelOnSide ? 0 : null,
                        bottom: 0,
                        child: SizedBox(
                          width: countryPanelOnSide ? panelWidth : null,
                          height: countryPanelOnSide
                              ? viewport.height
                              : panelHeight,
                          child: _detailCard(
                            countryPanel: true,
                            viewport: viewport,
                            title: ru ? selected.nameRu : selected.nameEn,
                            leading: flags[selected.id] == null
                                ? null
                                : Image.memory(
                                    base64Decode(flags[selected.id]),
                                    width: 36,
                                    height: 24,
                                  ),
                            onClose: () =>
                                setState(() => countryDetailsOpen = false),
                            children: [
                              if (selected.interestingFacts.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  tr('Interesting facts', 'Интересные факты'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xff76543c),
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index < selected.interestingFacts.length;
                                  index++
                                ) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    ru
                                        ? selected
                                              .interestingFacts[index]
                                              .textRu
                                        : selected
                                              .interestingFacts[index]
                                              .textEn,
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      key: ValueKey('fact-source-$index'),
                                      onPressed: () => launchUrl(
                                        selected.interestingFacts[index].source,
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Text(
                                        '${tr('Source', 'Источник')} ${index + 1}',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              const Divider(height: 24),
                              Text(
                                tr('Overview', 'Общие сведения'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${tr('Capital', 'Столица')}: ${selected.capital == null
                                    ? '—'
                                    : ru
                                    ? russianCountryLabel(selected.capital!)
                                    : selected.capital}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tr('Area', 'Площадь')}: ${formatCountryNumber(selected.area, russian: ru)} ${tr('km²', 'км²')}',
                              ),
                              if (selected.population != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${tr('Population', 'Население')}${selected.populationYear == null ? '' : ' (${selected.populationYear})'}: ${formatCountryNumber(selected.population, russian: ru)}',
                                ),
                              ],
                              if (selected.region != null)
                                Text(
                                  '${tr('Region', 'Регион')}: ${[selected.region, selected.subregion].whereType<String>().map((value) => ru ? (regionRu[value] ?? value) : value).join(' · ')}',
                                ),
                              if (selected.neighbors.isNotEmpty)
                                Text(
                                  '${tr('Neighbours', 'Соседи')}: ${selected.neighbors.map(countryName).join(', ')}',
                                ),
                              if (selected.currencies.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${tr('Currency', 'Валюта')}: ${selected.currencies.join(', ')}',
                                ),
                              ],
                              if (selected.languages.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${tr('Languages', 'Языки')}: ${selected.languages.map((value) => ru ? russianCountryLabel(value) : value).join(', ')}',
                                ),
                              ],
                              if (state!.landmarks.any(
                                (item) => item.countryId == selected.id,
                              ))
                                Text(
                                  tr('Landmarks', 'Достопримечательности'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              for (final landmark in state!.landmarks.where(
                                (item) => item.countryId == selected.id,
                              ))
                                TextButton(
                                  onPressed: () => selectLandmark(landmark.id),
                                  child: Text(
                                    ru ? landmark.nameRu : landmark.nameEn,
                                  ),
                                ),
                              if ((waters[selected.id] as List? ?? const [])
                                  .isNotEmpty)
                                Text(
                                  tr('Waters', 'Водоёмы'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              for (final water
                                  in (waters[selected.id] as List? ?? const [])
                                      .where(
                                        (water) =>
                                            water is Map &&
                                            water[ru ? 'name_ru' : 'name_en']
                                                is String,
                                      )) ...[
                                Text(
                                  water[ru ? 'name_ru' : 'name_en'] as String,
                                ),
                                for (final source in waterSources.where(
                                  (source) =>
                                      source['id'] == water['source_id'],
                                ))
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(source['url']),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Text(
                                      '${tr('Water source', 'Источник о водоёме')}: ${water[ru ? 'name_ru' : 'name_en']}',
                                    ),
                                  ),
                              ],
                              if (dishes.any(
                                (dish) =>
                                    dish is Map &&
                                    dish['country_en'] == selected.nameEn &&
                                    dish[ru ? 'name_ru' : 'name_en'] is String,
                              ))
                                Text(
                                  tr('Dishes', 'Блюда'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              for (final dish in dishes.where(
                                (dish) =>
                                    dish is Map &&
                                    dish['country_en'] == selected.nameEn &&
                                    dish[ru ? 'name_ru' : 'name_en'] is String,
                              )) ...[
                                Text(
                                  dish[ru ? 'name_ru' : 'name_en'] as String,
                                ),
                                for (final source in foodSources.where(
                                  (source) =>
                                      (dish['source_ids'] as List? ?? const [])
                                          .contains(source['id']),
                                ))
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(source['url']),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Text(
                                      '${tr('Dish source', 'Источник блюда')}: ${dish[ru ? 'name_ru' : 'name_en']}',
                                    ),
                                  ),
                              ],
                              Wrap(
                                children: [
                                  TextButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(
                                        'https://github.com/mledoze/countries/blob/master/countries.json',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Text(
                                      tr(
                                        'Country data source',
                                        'Источник данных о стране',
                                      ),
                                    ),
                                  ),
                                  if (selected.population != null)
                                    TextButton(
                                      onPressed: () => launchUrl(
                                        Uri.parse(
                                          'https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?date=2024&format=json&per_page=400',
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Text(
                                        tr(
                                          'Population source',
                                          'Источник населения',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
