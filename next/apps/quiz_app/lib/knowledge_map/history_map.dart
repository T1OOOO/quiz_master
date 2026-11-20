import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'atlas_controls.dart';
import 'map_state.dart';
import 'history_globe.dart';
import 'history_event_symbol.dart';
import 'history_map_pins.dart';
import 'history_timeline.dart';
import 'history_period.dart';
import 'history_event_index.dart';
import 'history_relief.dart';

export 'history_period.dart' show historyPeriod;

const _root = 'assets/quizipedia/map_v2/';
int historyCentury(int year) => (year - 1) ~/ 100 + 1;
List<Map> historyEventsFor(
  List<Map> events,
  int start,
  int end,
  String? country,
) {
  return events
      .where(
        (e) =>
            historyEventOverlaps(e, start, end) &&
            (country == null || (e['countries'] as List).contains(country)),
      )
      .toList()
    ..sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
}

class HistoryMap extends StatefulWidget {
  const HistoryMap({
    super.key,
    this.countries = const [],
    required this.russian,
    this.initialCountry,
    this.initialYear = 1914,
    this.initialGlobe = false,
    this.onExit,
  });
  final List<MapCountry> countries;
  final bool russian;
  final String? initialCountry;
  final int initialYear;
  final bool initialGlobe;
  final VoidCallback? onExit;
  @override
  State<HistoryMap> createState() => _HistoryMapState();
}

class _HistoryMapState extends State<HistoryMap> {
  late int year = widget.initialYear.clamp(1501, 2000);
  int periodLength = 1;
  bool customRange = false;
  (int, int) get period => historyPeriod(year, periodLength);
  String get periodLabel =>
      period.$1 == period.$2 ? '${period.$1}' : '${period.$1}–${period.$2}';

  final dateButton = GlobalKey();
  bool readerOpen = false;
  Map? reading;
  List<Map>? nearbyRows;
  void resetReader() {
    reading = null;
    nearbyRows = null;
  }

  void closeReader() => setState(() {
    readerOpen = false;
    resetReader();
  });

  Future<void> choosePeriod(List<Map> scoped) async {
    final choice = await showHistoryPeriodMenu(
      dateButton.currentContext!,
      HistoryPeriodMenu(
        year: year,
        step: periodLength,
        customRange: customRange,
        events: scoped,
        russian: widget.russian,
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      year = choice.$1;
      periodLength = choice.$2;
      customRange = choice.$3;
      resetReader();
      selectedEvent = null;
      selected = null;
    });
  }

  late bool globe = widget.initialGlobe;
  Map? selectedEvent;
  final regionAnchors = <String, Offset>{};
  late List landPolygons;
  Map<String, dynamic> polityNames = {};
  late String? country = widget.initialCountry;
  late List<MapCountry> countryNames = widget.countries;
  _Polity? selected;
  final transform = TransformationController();
  final packs = <int, Future<List<_Polity>>>{};
  ui.Image? relief;
  late final base = _loadBase();
  String t(String ru, String en) => widget.russian ? ru : en;
  String name(MapCountry c) => widget.russian ? c.nameRu : c.nameEn;
  String get regionName {
    final r = countryNames.where((c) => c.id == country).firstOrNull;
    return r == null ? t('Все страны', 'All countries') : name(r);
  }

  @override
  void dispose() {
    relief?.dispose();
    transform.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadHistoryRelief().then(
      (image) {
        if (!mounted) {
          image.dispose();
          return;
        }
        setState(() => relief = image);
      },
      onError: (Object error) =>
          debugPrint('Historical terrain image unavailable: $error'),
    );
  }

  Future<(Path, List<Map>)> _loadBase() async {
    final texts = await Future.wait(
      [
        'historical_land',
        'history_events',
        'historical_polity_names_ru',
      ].map((s) => rootBundle.loadString('$_root$s.json')),
    );
    if (countryNames.isEmpty) {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/quizipedia/country_facts.json'),
      );
      countryNames = [
        for (final r in raw['countries'])
          MapCountry(id: r['id'], nameRu: r['name_ru'], nameEn: r['name_en']),
      ];
    }
    polityNames = jsonDecode(texts[2]) as Map<String, dynamic>;
    final labels = jsonDecode(
      await rootBundle.loadString('${_root}country_labels.geojson'),
    );
    for (final feature in labels['features']) {
      final xy = feature['geometry']['coordinates'];
      regionAnchors[feature['properties']['country_id']] = Offset(
        (xy[0] as num).toDouble(),
        (xy[1] as num).toDouble(),
      );
    }
    landPolygons = jsonDecode(texts[0]) as List;
    return (
      _shape(landPolygons),
      (jsonDecode(texts[1])['records'] as List).cast<Map>(),
    );
  }

  Future<List<_Polity>> _load(int c) {
    if (!packs.containsKey(c) && packs.length >= 2) {
      packs.remove(packs.keys.first);
    }
    return packs.putIfAbsent(c, () async {
      final obj = jsonDecode(
        await rootBundle.loadString('${_root}historical_shapes_$c.json'),
      );
      return (obj['polities'] as List)
          .map((r) => _Polity(r[0], r[1], r[2], r[3]))
          .toList();
    });
  }

  int? visibleYear;
  List<_Polity>? visiblePack;
  List<_Polity> visiblePolities = [];
  List<GlobePolity> globePolities = [];
  void updateVisible(List<_Polity> pack) {
    if (visibleYear == year && identical(visiblePack, pack)) return;
    visibleYear = year;
    visiblePack = pack;
    final matching = pack
        .where((p) => p.start <= year && p.end >= year)
        .toList();
    if (listEquals(matching, visiblePolities)) return;
    visiblePolities = matching;
    globePolities = [for (final p in visiblePolities) p.globePolity];
  }

  void changeYear(int v) {
    if (v == year && selectedEvent == null) return;
    setState(() {
      year = v;
      selected = null;
      resetReader();
      selectedEvent = null;
    });
  }

  HistoryEventPin? lastFlatFocus;

  void revealFlatPin(
    HistoryEventPin? pin,
    Size size,
    Offset origin,
    double scale,
  ) {
    if (pin == lastFlatFocus) return;
    lastFlatFocus = pin;
    if (pin == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || globe || lastFlatFocus != pin) return;
      final matrix = transform.value;
      final zoom = matrix.getMaxScaleOnAxis();
      if (zoom <= 1) return;
      final scene =
          origin + Offset(180 + pin.longitude, 90 - pin.latitude) * scale;
      final point = MatrixUtils.transformPoint(matrix, scene);
      if ((Offset.zero & size).deflate(historyPinTarget).contains(point)) {
        return;
      }
      final x = (size.width / 2 - scene.dx * zoom).clamp(
        size.width * (1 - zoom),
        0.0,
      );
      final y = (size.height / 2 - scene.dy * zoom).clamp(
        size.height * (1 - zoom),
        0.0,
      );
      transform.value = matrix.clone()..setTranslationRaw(x, y, 0);
    });
  }

  Widget close(BuildContext d) => TextButton(
    onPressed: () => Navigator.pop(d),
    child: Text(t('Закрыть', 'Close')),
  );
  Future<void> chooseCountry(List<Map> events) async {
    var query = '';
    final ids = events
        .expand((r) => (r['countries'] as List).cast<String>())
        .toSet();
    final choices = countryNames.where((c) => ids.contains(c.id)).toList()
      ..sort((a, b) => name(a).compareTo(name(b)));
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(t('События по стране', 'Events by country')),
          content: SizedBox(
            width: 380,
            height: 350,
            child: Column(
              children: [
                TextField(
                  onChanged: (s) =>
                      refresh(() => query = s.toLowerCase().trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: t('Название страны', 'Country name'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        title: Text(t('Все страны', 'All countries')),
                        onTap: () => Navigator.pop(d, ''),
                      ),
                      for (final c in choices.where(
                        (c) => name(c).toLowerCase().contains(query),
                      ))
                        ListTile(
                          title: Text(name(c)),
                          onTap: () => Navigator.pop(d, c.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [close(d)],
        ),
      ),
    );
    if (mounted && choice != null) {
      setState(() {
        country = choice.isEmpty ? null : choice;
        resetReader();
        selectedEvent = null;
      });
    }
  }

  void about() => showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(t('Исторические границы', 'Historical boundaries')),
      content: Text(
        t(
          'Реконструкции из Cliopatria v0.0.1 (Bennett и др., Seshat). Контуры упрощены. На светлых участках источник не указывает государство. Фильтр событий использует современные названия стран. Рельеф: Natural Earth I with Shaded Relief and Water, public domain.',
          'Reconstructions from Cliopatria v0.0.1 (Bennett et al., Seshat). Shapes are simplified. Pale land means no polity shown in the source. Event filters use modern country names. Relief: Natural Earth I with Shaded Relief and Water, public domain.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              launchUrl(Uri.parse('https://doi.org/10.5281/zenodo.13363121')),
          child: const Text('Cliopatria'),
        ),
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse('https://creativecommons.org/licenses/by/4.0/'),
          ),
          child: const Text('CC BY 4.0'),
        ),
        close(d),
      ],
    ),
  );
  void zoomFlat(Size size, double factor) {
    final center = size.center(Offset.zero);
    final scene = transform.toScene(center);
    final zoom = (transform.value.getMaxScaleOnAxis() * factor).clamp(
      1.0,
      18.0,
    );
    transform.value = Matrix4.diagonal3Values(zoom, zoom, zoom)
      ..setTranslationRaw(
        (center.dx - scene.dx * zoom).clamp(size.width * (1 - zoom), 0.0),
        (center.dy - scene.dy * zoom).clamp(size.height * (1 - zoom), 0.0),
        0,
      );
  }

  Widget frame(Widget map, {bool loaded = false}) => LayoutBuilder(
    builder: (context, box) => Stack(
      fit: StackFit.expand,
      children: [
        map,
        if (box.maxHeight >= 60)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Align(
              alignment: Alignment.topLeft,
              child: AtlasHeader(
                russian: widget.russian,
                title: box.maxWidth < 380
                    ? t('История', 'History')
                    : t('Исторический атлас', 'Historical atlas'),
                globe: globe,
                onBack: readerOpen
                    ? closeReader
                    : widget.onExit ?? () => Navigator.maybePop(context),
                onAbout: about,
                onProjection: loaded
                    ? () => setState(() => globe = !globe)
                    : null,
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<(Path, List<Map>)>(
        future: base,
        builder: (context, snap) {
          if (snap.hasError) {
            return frame(
              Center(
                child: Text(
                  t('Не удалось загрузить атлас', 'Could not load atlas'),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return frame(const Center(child: CircularProgressIndicator()));
          }
          final (land, events) = snap.data!;
          final scoped = country == null
              ? events
              : events
                    .where((r) => (r['countries'] as List).contains(country))
                    .toList();
          final rows = historyEventsFor(scoped, period.$1, period.$2, null);
          final lang = widget.russian ? 'ru' : 'en';
          final topControlsHeight = selected == null ? 60.0 : 108.0;
          HistoryEventPin pinFor(Map row, Offset point) => (
            longitude: point.dx,
            latitude: point.dy,
            title: row['title_$lang'] as String,
            kind: row['kind'] as String,
          );
          // A missing location represents the country's region, not its capital.
          final pinRecords = <HistoryEventPin, Map>{};
          HistoryEventPin? focus;
          String? focusCaption;
          for (final r in rows) {
            final xy = r['location'];
            final region = country ?? r['countries'].first as String;
            final point = xy is List
                ? Offset((xy[0] as num).toDouble(), (xy[1] as num).toDouble())
                : regionAnchors[region];
            if (point == null) continue;
            final pin = pinFor(r, point);
            pinRecords[pin] = r;
            if (r == selectedEvent) {
              focus = pin;
              final regionHint = xy is List
                  ? ''
                  : ' · ${t("регион", "region")}';
              focusCaption = '${historyEventDate(r)} · ${pin.title}$regionHint';
            }
          }
          void openPins(List<HistoryEventPin> pins) {
            if (pins.isEmpty) return;
            setState(() {
              readerOpen = true;
              nearbyRows = pins.length > 1
                  ? [for (final pin in pins) pinRecords[pin]!]
                  : null;
              reading = pins.length == 1 ? pinRecords[pins.first] : null;
              if (reading != null) selectedEvent = reading;
            });
          }

          final map = ColoredBox(
            color: globe ? const Color(0xff142f3a) : const Color(0xffadd6df),
            child: FutureBuilder<List<_Polity>>(
              future: _load(historyCentury(year)),
              builder: (context, pack) {
                if (pack.hasError) {
                  return Center(
                    child: Text(
                      t(
                        'Не удалось загрузить границы',
                        'Could not load boundaries',
                      ),
                    ),
                  );
                }
                if (!pack.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                updateVisible(pack.data!);
                final visible = visiblePolities;
                return Stack(
                  children: [
                    if (globe)
                      Positioned.fill(
                        child: HistoryGlobe(
                          onSearch: () => chooseCountry(events),
                          land: landPolygons,
                          polities: globePolities,
                          year: year,
                          focus: focus,
                          focusCaption: focusCaption,
                          topControlsHeight: topControlsHeight,
                          russian: widget.russian,
                          eventPins: pinRecords.keys.toList(),
                          relief: relief,
                          onEventTap: (pin) => openPins([pin]),
                          onGroupTap: openPins,
                          selectedName: selected?.name,
                          onSelect: (name) => setState(
                            () => selected = visible
                                .where((p) => p.name == name)
                                .firstOrNull,
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            if (box.biggest.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final s = math.min(
                              box.maxWidth / 360,
                              box.maxHeight / 180,
                            );
                            final offset = Offset(
                              (box.maxWidth - 360 * s) / 2,
                              (box.maxHeight - 180 * s) / 2,
                            );
                            revealFlatPin(focus, box.biggest, offset, s);
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                InteractiveViewer(
                                  transformationController: transform,
                                  maxScale: 18,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (tap) {
                                      final point =
                                          (tap.localPosition - offset) / s;
                                      setState(
                                        () => selected = visible.reversed
                                            .where(
                                              (p) => p.path.contains(point),
                                            )
                                            .firstOrNull,
                                      );
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CustomPaint(
                                          painter: _Painter(
                                            land,
                                            visible,
                                            selected,
                                            offset,
                                            s,
                                            transform,
                                            relief: relief,
                                          ),
                                        ),
                                        AnimatedBuilder(
                                          animation: transform,
                                          builder: (context, _) => Transform(
                                            transform: Matrix4.inverted(
                                              transform.value,
                                            ),
                                            child: HistoryMapPins(
                                              size: box.biggest,
                                              pins: pinRecords.keys,
                                              obstacles: [
                                                Rect.fromLTWH(
                                                  0,
                                                  0,
                                                  box.maxWidth,
                                                  topControlsHeight,
                                                ),
                                                AtlasCameraControls.bounds(
                                                  box.biggest,
                                                  search: true,
                                                ).inflate(3),
                                              ],
                                              focus: focus,
                                              caption: focusCaption,
                                              russian: widget.russian,
                                              onOpen: openPins,
                                              project: (p) =>
                                                  MatrixUtils.transformPoint(
                                                    transform.value,
                                                    offset +
                                                        Offset(
                                                              180 + p.longitude,
                                                              90 - p.latitude,
                                                            ) *
                                                            s,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: AtlasCameraControls(
                                    russian: widget.russian,
                                    viewport: box.biggest,
                                    showSearch: true,
                                    onSearch: () => chooseCountry(events),
                                    onFit: () =>
                                        transform.value = Matrix4.identity(),
                                    onZoomIn: () => zoomFlat(box.biggest, 1.5),
                                    onZoomOut: () =>
                                        zoomFlat(box.biggest, 1 / 1.5),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (pack.connectionState == ConnectionState.waiting)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(),
                      ),
                    if (selected != null)
                      Positioned(
                        top: 64,
                        left: 8,
                        right: 8,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Chip(
                            label: Text(
                              widget.russian
                                  ? (polityNames[selected!.name] as String? ??
                                        selected!.name)
                                  : selected!.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () => setState(() => selected = null),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
          final timeline = HistoryTimeline(
            dateButton: dateButton,
            step: periodLength,
            russian: widget.russian,
            countryName: regionName,
            eventCount: rows.length,
            period: period,
            onYear: changeYear,
            openCalendar: () => choosePeriod(scoped),
            pickCountry: () => chooseCountry(events),
            openEvents: () => setState(() {
              readerOpen = !readerOpen;
              resetReader();
            }),
          );
          final reader = HistoryEventIndex(
            key: ValueKey((period, country, nearbyRows)),
            rows: nearbyRows ?? rows,
            nearby: nearbyRows != null,
            period: periodLabel,
            region: regionName,
            russian: widget.russian,
            detail: reading,
            year: year,
            countriesOf: (event) => countryNames
                .where((c) => (event['countries'] as List).contains(c.id))
                .map(name)
                .join(', '),
            onClose: closeReader,
            onRead: (event) => setState(() {
              reading = event;
              if (event != null) selectedEvent = event;
            }),
            onMap: (event, jump) => setState(() {
              if (jump) {
                year = event['start'];
                selected = null;
              }
              selectedEvent = event;
              readerOpen = false;
              resetReader();
            }),
          );
          return PopScope(
            canPop: !readerOpen,
            onPopInvokedWithResult: (popped, _) {
              if (!popped && readerOpen) closeReader();
            },
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final wide = box.maxWidth >= 680;
                      final editing =
                          MediaQuery.viewInsetsOf(context).bottom > 0;
                      return Flex(
                        direction: wide ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(child: frame(map, loaded: true)),
                          if (readerOpen)
                            SizedBox(
                              width: wide
                                  ? math.min(400, box.maxWidth * .44)
                                  : null,
                              height: wide
                                  ? null
                                  : box.maxHeight * (editing ? 0.9 : 0.55),
                              child: reader,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                timeline,
              ],
            ),
          );
        },
      ),
    ),
  );
}

Path _shape(List polygons) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final polygon in polygons) {
    for (final ring in polygon) {
      for (var i = 0; i < ring.length; i++) {
        final p = ring[i],
            x = 180 + (p[0] as num).toDouble(),
            y = 90 - (p[1] as num).toDouble();
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
    }
  }
  return path;
}

class _Polity {
  _Polity(this.name, this.start, this.end, this.polygons);
  final String name;
  final int start, end;
  final List polygons;
  late final path = _shape(polygons);
  late final globePolity = GlobePolity(name: name, polygons: polygons);
}

class _Painter extends CustomPainter {
  _Painter(
    this.land,
    this.rows,
    this.selected,
    this.offset,
    this.scale,
    this.transform, {
    this.relief,
  }) : super(repaint: transform);
  final TransformationController transform;
  final Path land;
  final List<_Polity> rows;
  final _Polity? selected;
  final Offset offset;
  final double scale;
  final ui.Image? relief;
  static const tones = [
    Color(0xffa1c5a9),
    Color(0xffe7bf89),
    Color(0xffbcadd1),
    Color(0xff8ec3bc),
    Color(0xffdfaca3),
    Color(0xffc7c991),
    Color(0xffb2c9e0),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    if (relief case final image?) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        const Rect.fromLTWH(0, 0, 360, 180),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final fill = Paint()..color = const Color(0xfff3e8cc);
    final screenScale = scale * transform.value.getMaxScaleOnAxis();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .52 / screenScale
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xb3556254);
    final grid = Paint()
      ..color = const Color(0x403a7e86)
      ..strokeWidth = .45 / screenScale;
    for (double x = 30; x < 360; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, 180), grid);
    }
    for (double y = 30; y < 180; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(360, y), grid);
    }
    if (relief == null) canvas.drawPath(land, fill);
    for (final p in rows) {
      final index = p.name.codeUnits.fold<int>(
        0,
        (a, b) => (31 * a + b) % tones.length,
      );
      fill.color = tones[index].withValues(alpha: relief == null ? 1 : .30);
      canvas.drawPath(p.path, fill);
      canvas.drawPath(p.path, line);
    }
    if (selected != null) {
      fill.color = const Color(0xbbffcc64);
      canvas.drawPath(selected!.path, fill);
      line.color = const Color(0xff783e1f);
      line.strokeWidth = 1.15 / screenScale;
      canvas.drawPath(selected!.path, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Painter old) =>
      old.land != land ||
      old.transform != transform ||
      old.rows != rows ||
      old.selected != selected ||
      old.offset != offset ||
      old.scale != scale ||
      !identical(old.relief, relief);
}
