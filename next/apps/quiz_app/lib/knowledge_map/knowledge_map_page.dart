import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../country_labels_ru.dart';
import 'country_marker.dart';
import 'map_state.dart';

class KnowledgeMapPage extends StatefulWidget {
  const KnowledgeMapPage({super.key, this.onExit})
    : mapBuilder = null,
      hoverMapBuilder = null,
      landmarkMapBuilder = null,
      bundle = null;
  @visibleForTesting
  const KnowledgeMapPage.test({
    super.key,
    required this.mapBuilder,
    this.hoverMapBuilder,
    this.landmarkMapBuilder,
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
  final AssetBundle? bundle;
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
  bool detailRiversReady = false, detailLakesReady = false;
  bool failed = false,
      ready = false,
      layersOpen = false,
      showCapitals = true,
      showLandmarks = true,
      showCountryLabels = true,
      showWaterLabels = true;
  String query = '';
  final hover = MapHoverState();
  Timer? hoverTimer;
  Future<void> hoverFilter = Future.value();
  Future<void> capitalCommands = Future.value();
  Future<void> labelCommands = Future.value();
  final searchController = TextEditingController();
  int generation = 0;
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
    controller = null;
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
            area: f?['area_km2'],
            population: f?['population'],
            populationYear: f?['population_year'],
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
      if (mounted) {
        setState(() {
          state = MapState(items, landmarks: landmarkItems);
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
            enableInteraction: false,
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
            enableInteraction: false,
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
      await c.addCircleLayer(
        'capitals',
        'capital-dots',
        const CircleLayerProperties(
          circleColor: '#805e48',
          circleRadius: 2.5,
          circleStrokeColor: '#ffffff',
          circleStrokeWidth: 1,
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
        );
        if (!mounted || generation != attempt || controller != c || failed) {
          return;
        }
        await c.addImage('country-$id', bytes);
        properties['sprite'] = 'country-$id';
      }
      await c.addGeoJsonSource('country-markers', countryLabels!);
      await c.addSymbolLayer(
        'country-markers',
        'country-markers',
        const SymbolLayerProperties(iconImage: ['get', 'sprite'], iconSize: 1),
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
          final marker = await renderCountryMarker(
            name: '$prefix${p[localizedRu ? 'name_ru' : 'name_en']}',
            landmark: source == 'landmarks',
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
            iconSize: 1,
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
      await addLabels('capital-labels', capitals!, '• ', 4);
      stage = 'water labels';
      await addLabels('water-labels', waterLabels!, '≈ ', 3);
      stage = 'landmarks';
      await addLabels('landmarks', landmarks!, '', 4);
      if (!mounted || generation != attempt || controller != c || failed) {
        return;
      }
      startupTimer?.cancel();
      setState(() => ready = true);
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
    searchController.dispose();
    super.dispose();
  }

  Future<void> select(String? id, {bool move = false}) async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final c = controller;
    final attempt = generation;
    setState(() {
      state?.select(id);
      query = '';
      layersOpen = false;
    });
    searchController.clear();
    if (!ready || c == null) return;
    try {
      await c.setFilter('selected', [
        '==',
        ['get', 'country_id'],
        id ?? '',
      ]);
      if (!mounted || generation != attempt || controller != c) return;
      if (move && id != null && capitals != null) {
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

  Future<void> tap(math.Point<double> point, LatLng position) async {
    final c = controller;
    final attempt = generation;
    if (!mounted || !ready || c == null) return;
    try {
      var features = await c.queryRenderedFeatures(point, ['landmarks'], null);
      if (!mounted || generation != attempt || controller != c) return;
      if (features.isNotEmpty) {
        await selectLandmark(features.first['properties']['id'] as String);
        return;
      }
      features = await c.queryRenderedFeatures(point, [
        'country-markers',
      ], null);
      if (!mounted || generation != attempt || controller != c) return;
      if (features.isEmpty) {
        features = await c.queryRenderedFeatures(point, ['land'], null);
        if (!mounted || generation != attempt || controller != c) return;
      }
      await select(
        features.isEmpty
            ? null
            : features.first['properties']['country_id'] as String?,
      );
    } catch (error, stack) {
      debugPrint('Knowledge map: tap failed: $error\n$stack');
      if (mounted && generation == attempt && controller == c) {
        setState(() => failed = true);
      }
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

  Future<void> selectLandmark(String? id) async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final c = controller;
    final attempt = generation;
    setState(() {
      state?.selectLandmark(id);
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
    labelCommands = labelCommands.catchError((Object _) {}).then((_) async {
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
    });
    await labelCommands;
  }

  void clearHover() {
    hoverTimer?.cancel();
    hover.clear();
    if (mounted) setState(() {});
    queueHoverFilter();
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
    if (!mounted || !ready || controller == null) return;
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
        features = await c.queryRenderedFeatures(point, [
          'country-markers',
        ], null);
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
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: math.min(360, math.max(0, viewport.width - 24)),
        maxHeight: math.max(0, math.min(340, viewport.height - 84)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = state?.selected;
    final selectedLandmark = state?.selectedLandmark;
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (state != null && !failed && !unsupported)
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
                            onMapClick: tap,
                            featureTapsTriggersMapClick: true,
                            compassEnabled: false,
                            attributionButtonPosition:
                                AttributionButtonPosition.bottomRight,
                          ),
                        ),
                  if ((state == null || !ready) && !failed && !unsupported)
                    const Center(child: CircularProgressIndicator()),
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
                    child: IconButton.filledTonal(
                      tooltip: tr('Back', 'Назад'),
                      onPressed:
                          widget.onExit ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  if (state != null && !failed && !unsupported) ...[
                    Positioned(
                      top: 8,
                      left: 64,
                      right: 64,
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: tr('Search countries', 'Поиск стран'),
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => setState(() => query = v),
                            ),
                            if (query.isNotEmpty)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for (final country
                                        in state!.search(query).take(8))
                                      ListTile(
                                        title: Text(
                                          ru ? country.nameRu : country.nameEn,
                                        ),
                                        subtitle: Text(country.id),
                                        onTap: () =>
                                            select(country.id, move: true),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Column(
                        children: [
                          IconButton.filledTonal(
                            tooltip: tr('Zoom in', 'Увеличить'),
                            onPressed: ready
                                ? () => controller?.animateCamera(
                                    CameraUpdate.zoomIn(),
                                  )
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                          IconButton.filledTonal(
                            tooltip: tr('Zoom out', 'Уменьшить'),
                            onPressed: ready
                                ? () => controller?.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  )
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: IconButton.filledTonal(
                        tooltip: tr('Layers', 'Слои'),
                        onPressed: () =>
                            setState(() => layersOpen = !layersOpen),
                        icon: Icon(
                          layersOpen ? Icons.close : Icons.layers_outlined,
                        ),
                      ),
                    ),
                    if (layersOpen)
                      Positioned(
                        right: 12,
                        bottom: 68,
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      16,
                                      4,
                                    ),
                                    child: Text(
                                      tr(
                                        'Rivers and lakes are always visible',
                                        'Реки и озёра видны всегда',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                  SwitchListTile(
                                    dense: true,
                                    title: Text(
                                      tr('Country labels', 'Названия стран'),
                                    ),
                                    value: showCountryLabels,
                                    onChanged: ready
                                        ? (v) =>
                                              toggleLabels('country-markers', v)
                                        : null,
                                  ),
                                  SwitchListTile(
                                    dense: true,
                                    title: Text(
                                      tr('Water labels', 'Названия водоёмов'),
                                    ),
                                    value: showWaterLabels,
                                    onChanged: ready
                                        ? (v) => toggleLabels('water-labels', v)
                                        : null,
                                  ),
                                  SwitchListTile(
                                    dense: true,
                                    title: Text(tr('Capitals', 'Столицы')),
                                    value: showCapitals,
                                    onChanged: ready ? toggleCapitals : null,
                                  ),
                                  SwitchListTile(
                                    dense: true,
                                    title: Text(
                                      tr('Landmarks', 'Интересные места'),
                                    ),
                                    value: showLandmarks,
                                    onChanged: ready ? toggleLandmarks : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!layersOpen && selectedLandmark != null)
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
                    if (!layersOpen && selected != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 68,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _detailCard(
                            viewport: viewport,
                            title: ru ? selected.nameRu : selected.nameEn,
                            leading: flags[selected.id] == null
                                ? null
                                : Image.memory(
                                    base64Decode(flags[selected.id]),
                                    width: 36,
                                    height: 24,
                                  ),
                            onClose: () => select(null),
                            children: [
                              Text(
                                '${tr('Capital', 'Столица')}: ${selected.capital == null
                                    ? '—'
                                    : ru
                                    ? russianCountryLabel(selected.capital!)
                                    : selected.capital}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tr('Area', 'Площадь')}: ${selected.area ?? '—'} km²',
                              ),
                              if (selected.population != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${tr('Population', 'Население')}${selected.populationYear == null ? '' : ' (${selected.populationYear})'}: ${selected.population}',
                                ),
                              ],
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
                              if (selected.interestingFacts.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  tr('Interesting facts', 'Интересные факты'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
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
