import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'atlas_controls.dart';
import 'history_globe.dart';
import 'history_relief.dart';

/// MapLibre Native currently offers only a flat projection. Use the atlas's
/// orthographic renderer with modern outlines on those devices.
class WorldGlobe extends StatefulWidget {
  const WorldGlobe({
    super.key,
    required this.features,
    required this.names,
    required this.russian,
    this.selectedId,
  });

  final List features;
  final Map<String, String> names;
  final bool russian;
  final String? selectedId;

  @override
  State<WorldGlobe> createState() => _WorldGlobeState();
}

// Keep tiny islands intact while bounding the work on each drag frame.
List _overviewRing(List ring) {
  if (ring.length <= 5) return ring;
  final result = [ring.first];
  for (final point in ring.skip(1).take(ring.length - 2)) {
    final dx = point[0] - result.last[0];
    final dy = point[1] - result.last[1];
    if (dx * dx + dy * dy >= 0.16) result.add(point);
  }
  return result.length >= 3 ? (result..add(ring.last)) : ring;
}

class _WorldGlobeState extends State<WorldGlobe> {
  late final polities = <GlobePolity>[
    for (final feature in widget.features)
      if (feature['geometry']['type'] == 'Polygon' ||
          feature['geometry']['type'] == 'MultiPolygon')
        GlobePolity(
          name: feature['properties']['country_id'] as String,
          polygons: [
            for (final polygon
                in feature['geometry']['type'] == 'Polygon'
                    ? [feature['geometry']['coordinates']]
                    : feature['geometry']['coordinates'] as List)
              [for (final ring in polygon as List) _overviewRing(ring as List)],
          ],
        ),
  ];
  late String? selected = widget.selectedId;
  ui.Image? relief;

  @override
  void initState() {
    super.initState();
    _loadRelief();
  }

  Future<void> _loadRelief() async {
    try {
      final image = await loadHistoryRelief();
      if (mounted) {
        setState(() => relief = image);
      } else {
        image.dispose();
      }
    } catch (error) {
      debugPrint('World globe relief unavailable: $error');
    }
  }

  @override
  void dispose() {
    relief?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ru = widget.russian;
    final name = widget.names[selected];
    return Scaffold(
      backgroundColor: const Color(0xff17353e),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            HistoryGlobe(
              land: const [],
              polities: polities,
              year: 0,
              relief: relief,
              russian: ru,
              selectedName: selected,
              onSelect: (id) => setState(() => selected = id),
            ),
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Align(
                alignment: Alignment.topLeft,
                child: AtlasHeader(
                  russian: ru,
                  title: ru ? 'Глобус мира' : 'World globe',
                  globe: true,
                  onBack: () => Navigator.pop(context),
                  onProjection: () => Navigator.pop(context),
                ),
              ),
            ),
            if (name != null)
              Positioned(
                left: 12,
                bottom: 12,
                right: 76,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => Navigator.pop(context, selected),
                    label: Text(name),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
