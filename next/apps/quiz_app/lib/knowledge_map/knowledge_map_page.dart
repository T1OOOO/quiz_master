import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'country_marker.dart';
import 'map_state.dart';

class KnowledgeMapPage extends StatefulWidget {
  const KnowledgeMapPage({super.key, this.onExit})
    : mapBuilder = null,
      hoverMapBuilder = null,
      bundle = null;
  @visibleForTesting
  const KnowledgeMapPage.test({
    super.key,
    required this.mapBuilder,
    this.hoverMapBuilder,
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
  Map<String, dynamic>? countries, capitals, waterways, countryLabels;
  Map<String, dynamic> flags = {};
  bool failed = false, ready = false, layersOpen = false, showCapitals = true;
  String query = '';
  final hover = MapHoverState();
  Timer? hoverTimer;
  Future<void> hoverFilter = Future.value();
  final searchController = TextEditingController();
  int generation = 0;
  bool get ru => Localizations.localeOf(context).languageCode == 'ru';
  String tr(String en, String russian) => ru ? russian : en;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    startupTimer?.cancel();
    hoverTimer?.cancel();
    hover.clear();
    controller = null;
    setState(() {
      failed = false;
      ready = false;
      state = null;
      showCapitals = true;
      layersOpen = false;
      generation++;
    });
    final attempt = generation;
    try {
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
      ]);
      if (!mounted || generation != attempt) return;
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
          ),
        );
      }
      if (mounted) {
        setState(() {
          state = MapState(items);
          ready = widget.mapBuilder != null;
        });
      }
      if (widget.mapBuilder == null) {
        startupTimer = Timer(const Duration(seconds: 30), () {
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
      await c.addFillLayer(
        'waterways',
        'lakes',
        const FillLayerProperties(fillColor: '#b9dfe9'),
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
    controller?.onFeatureHover.remove(onFeatureHover);
    searchController.dispose();
    super.dispose();
  }

  Future<void> select(String? id, {bool move = false}) async {
    if (!mounted) return;
    final c = controller;
    final attempt = generation;
    setState(() {
      state?.select(id);
      query = '';
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
      var features = await c.queryRenderedFeatures(point, [
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
    try {
      await c?.setLayerVisibility('capital-dots', value);
    } catch (error, stack) {
      debugPrint('Knowledge map: layer command failed: $error\n$stack');
      if (mounted && generation == attempt && controller == c) {
        setState(() => failed = true);
      }
    }
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
          'country-markers',
        ], null);
        if (!current()) return;
        if (features.isEmpty) {
          final water = await c.queryRenderedFeatures(point, [
            'lakes',
            'rivers',
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

  void onFeatureHover(
    math.Point<double> point,
    LatLng coordinates,
    String id,
    Annotation? annotation,
    HoverEventType type,
  ) {
    if (type == HoverEventType.leave) clearHover();
  }

  @override
  Widget build(BuildContext context) {
    final selected = state?.selected;
    final hovered = state?.countries
        .where((c) => c.id == hover.countryId)
        .firstOrNull;
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
              final tooltipSize = Size(
                math.min(200, viewport.width),
                math.min(48, viewport.height),
              );
              final tooltipPosition = clampHoverTooltip(
                (hover.point ?? Offset.zero) + const Offset(14, 14),
                viewport,
                tooltipSize,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (state != null && !failed && !unsupported)
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
                              c.onFeatureHover.add(onFeatureHover);
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
                            tooltip: tr('Layers', 'Слои'),
                            onPressed: () =>
                                setState(() => layersOpen = !layersOpen),
                            icon: const Icon(Icons.layers_outlined),
                          ),
                          const SizedBox(height: 8),
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
                    if (layersOpen)
                      Positioned(
                        top: 60,
                        right: 8,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 220,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SwitchListTile(
                                  title: Text(tr('Capitals', 'Столицы')),
                                  value: showCapitals,
                                  onChanged: ready
                                      ? (v) => toggleCapitals(v)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hovered != null && hover.point != null)
                      Positioned(
                        left: tooltipPosition.dx,
                        top: tooltipPosition.dy,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: tooltipSize.width,
                            height: tooltipSize.height,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    if (flags[hovered.id] != null)
                                      Image.memory(
                                        base64Decode(flags[hovered.id]),
                                        width: 30,
                                        height: 20,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ru ? hovered.nameRu : hovered.nameEn,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (selected != null)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.min(
                              340,
                              MediaQuery.sizeOf(context).width - 24,
                            ),
                          ),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (flags[selected.id] != null)
                                        Image.memory(
                                          base64Decode(flags[selected.id]),
                                          width: 36,
                                          height: 24,
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ru
                                              ? selected.nameRu
                                              : selected.nameEn,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff302b24),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: tr('Close', 'Закрыть'),
                                        onPressed: () => select(null),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${tr('Capital', 'Столица')}: ${selected.capital ?? '—'}',
                                  ),
                                  Text(
                                    '${tr('Area', 'Площадь')}: ${selected.area ?? '—'} km²',
                                  ),
                                ],
                              ),
                            ),
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
