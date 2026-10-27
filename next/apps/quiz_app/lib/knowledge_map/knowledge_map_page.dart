import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'flag_sprite.dart';
import 'map_state.dart';

class KnowledgeMapPage extends StatefulWidget {
  const KnowledgeMapPage({super.key, this.onExit})
    : mapBuilder = null,
      bundle = null;
  @visibleForTesting
  const KnowledgeMapPage.test({
    super.key,
    required this.mapBuilder,
    this.bundle,
    this.onExit,
  });
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
  Map<String, dynamic>? countries, capitals, waterways;
  Map<String, dynamic> flags = {};
  bool failed = false,
      ready = false,
      layersOpen = false,
      showWater = true,
      showCapitals = true;
  String query = '';
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
    controller = null;
    setState(() {
      failed = false;
      ready = false;
      state = null;
      showWater = true;
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
      final facts =
          (jsonDecode(texts[3]) as Map<String, dynamic>)['countries'] as List;
      final byId = {for (final f in facts) f['id']: f};
      flags =
          (jsonDecode(texts[4]) as Map<String, dynamic>)['flags']
              as Map<String, dynamic>;
      final items = <MapCountry>[];
      for (final feature in countries!['features'] as List) {
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
      for (final feature in capitals!['features'] as List) {
        final properties = feature['properties'] as Map<String, dynamic>;
        final id = properties['country_id'];
        if (id is String && flags.containsKey(id)) {
          properties['sprite'] = 'flag-$id';
        }
      }
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
      for (final entry in flags.entries) {
        stage = 'flag sprite ${entry.key}';
        await c.addImage(
          'flag-${entry.key}',
          normalizeFlagSprite(base64Decode(entry.value as String)),
        );
      }
      stage = 'flag layer';
      await c.addSymbolLayer(
        'capitals',
        'flags',
        const SymbolLayerProperties(
          iconImage: ['get', 'sprite'],
          iconSize: 0.15,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconAnchor: 'bottom',
          iconOffset: [0, -12],
        ),
        minzoom: 2.5,
        filter: ['has', 'sprite'],
      );
      debugPrint(
        'Knowledge map: flag layer created with ${flags.length} sprites',
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
      final features = await c.queryRenderedFeatures(point, ['land'], null);
      if (!mounted || generation != attempt || controller != c) return;
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

  Future<void> toggle(String layer, bool value) async {
    if (!mounted || !ready) return;
    final c = controller;
    final attempt = generation;
    setState(() {
      if (layer == 'water') {
        showWater = value;
      } else {
        showCapitals = value;
      }
    });
    try {
      for (final name
          in layer == 'water'
              ? ['lakes', 'rivers']
              : ['capital-dots', 'flags']) {
        if (!mounted || generation != attempt || controller != c) return;
        await c?.setLayerVisibility(name, value);
      }
    } catch (error, stack) {
      debugPrint('Knowledge map: layer command failed: $error\n$stack');
      if (mounted && generation == attempt && controller == c) {
        setState(() => failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = state?.selected;
    final unsupported =
        widget.mapBuilder == null &&
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
    return Theme(
      data: ThemeData.light(useMaterial3: true),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (state != null && !failed && !unsupported)
                widget.mapBuilder?.call(context, select) ??
                    MapLibreMap(
                      key: ValueKey(generation),
                      styleString: '{"version":8,"sources":{},"layers":[{"id":"sea","type":"background","paint":{"background-color":"#c8e5ed"}}]}',
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(20, 10),
                        zoom: 1.6,
                      ),
                      onMapCreated: (c) => controller = c,
                      onStyleLoadedCallback: setup,
                      onMapClick: tap,
                      featureTapsTriggersMapClick: true,
                      compassEnabled: false,
                      attributionButtonPosition:
                          AttributionButtonPosition.bottomRight,
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
                  onPressed: widget.onExit ?? () => Navigator.maybePop(context),
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
                            constraints: const BoxConstraints(maxHeight: 200),
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
                                    onTap: () => select(country.id, move: true),
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
                              title: Text(
                                tr('Rivers and lakes', 'Реки и озёра'),
                              ),
                              value: showWater,
                              onChanged: ready
                                  ? (v) => toggle('water', v)
                                  : null,
                            ),
                            SwitchListTile(
                              title: Text(
                                tr('Capitals and flags', 'Столицы и флаги'),
                              ),
                              value: showCapitals,
                              onChanged: ready
                                  ? (v) => toggle('capitals', v)
                                  : null,
                            ),
                          ],
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
                                      ru ? selected.nameRu : selected.nameEn,
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
          ),
        ),
      ),
    );
  }
}
