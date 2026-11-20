import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map_state.dart';
import 'history_globe.dart';
import 'history_event_symbol.dart';
import 'history_map_pins.dart';
import 'history_timeline.dart';
import 'history_period.dart';
import 'history_event_index.dart';
import 'history_relief.dart';

export 'history_period.dart' show historyPeriod;
export 'history_timeline.dart' show closestHistoryEvent;

const _root = 'assets/quizipedia/map_v2/';
const _centuries = ['XVI', 'XVII', 'XVIII', 'XIX', 'XX'];
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
            e['start'] <= end &&
            e['end'] >= start &&
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
  bool calendarCentury = false;
  (int, int) get period =>
      historyPeriod(year, periodLength, calendarCentury: calendarCentury);
  String get periodLabel =>
      period.$1 == period.$2 ? '${period.$1}' : '${period.$1}–${period.$2}';

  Future<void> choosePeriod() async {
    final choice = await showDialog<(int, int, bool)>(
      context: context,
      builder: (_) => HistoryPeriodDialog(
        year: year,
        period: period,
        russian: widget.russian,
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      year = choice.$1;
      periodLength = choice.$2;
      calendarCentury = choice.$3;
      preview = null;
      selected = null;
    });
  }

  late bool globe = widget.initialGlobe;
  int resetGlobe = 0;
  Map? preview;
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
  String get centuryName => _centuries[historyCentury(year) - 16];
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
    if (v == year) return;
    setState(() {
      year = v;
      selected = null;
      preview = null;
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

  Future<void> chooseYear() async {
    var input = year.toString();
    final n = await showDialog<int>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, refresh) {
          final v = int.tryParse(input);
          final valid = v != null && v >= 1501 && v <= 2000;
          return AlertDialog(
            title: Text(t('Перейти к году', 'Go to year')),
            content: TextFormField(
              initialValue: input,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(helperText: '1501–2000'),
              onChanged: (s) => refresh(() => input = s),
              onFieldSubmitted: (_) {
                if (valid) Navigator.pop(d, v);
              },
            ),
            actions: [
              close(d),
              FilledButton(
                onPressed: valid ? () => Navigator.pop(d, v) : null,
                child: Text(t('Перейти', 'Go')),
              ),
            ],
          );
        },
      ),
    );
    if (mounted && n != null) changeYear(n);
  }

  Widget close(BuildContext d) => TextButton(
    onPressed: () => Navigator.pop(d),
    child: Text(t('Закрыть', 'Close')),
  );
  Future<void> chooseCentury() async {
    final c = await showDialog<int>(
      context: context,
      builder: (d) => SimpleDialog(
        title: Text(t('Выбрать век', 'Choose century')),
        children: [
          for (var i = 16; i <= 20; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(d, i),
              child: Text('${_centuries[i - 16]} · ${i * 100 - 99}–${i * 100}'),
            ),
          close(d),
        ],
      ),
    );
    if (mounted && c != null) {
      setState(() {
        if (historyCentury(year) != c) year = c * 100 - 99;
        calendarCentury = true;
        periodLength = 100;
        selected = null;
        preview = null;
      });
    }
  }

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
        preview = null;
      });
    }
  }

  Future<void> openIndex(List<Map> rows) async {
    await showDialog<void>(
      context: context,
      builder: (d) => HistoryEventIndex(
        rows: rows,
        period: periodLabel,
        region: regionName,
        russian: widget.russian,
        countriesOf: (event) => countryNames
            .where((c) => (event['countries'] as List).contains(c.id))
            .map(name)
            .join(', '),
        onOpen: (event) async {
          final showOnMap = await showDetail(event);
          if (showOnMap && d.mounted) Navigator.pop(d);
        },
      ),
    );
  }

  Future<bool> showDetail(Map event) async {
    final lang = widget.russian ? 'ru' : 'en';
    final style = HistoryEventStyle.forKind(event['kind']);
    final location = [
      if (event['place_$lang'] != null) event['place_$lang'],
      if (event['location'] == null) t('Регион события', 'Event region'),
      ...countryNames
          .where((c) => (event['countries'] as List).contains(c.id))
          .map(name),
    ].join(' · ');
    final action = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        scrollable: true,
        title: Text(event['title_$lang']),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HistoryEventSeal(event['kind'], size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${historyEventDate(event)} · ${widget.russian ? style.ru : style.en}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event['summary_$lang'],
              style: Theme.of(d).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(location, style: Theme.of(d).textTheme.bodySmall),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              onPressed: () => launchUrl(
                Uri.parse(event['source_url']),
                mode: LaunchMode.externalApplication,
              ),
              label: Text(t('Источник', 'Source')),
            ),
            if (year < event['start'] || year > event['end'])
              TextButton(
                onPressed: () => Navigator.pop(d, 'year'),
                child: Text(
                  t(
                    'Перейти к ${event['start']} году',
                    'Go to ${event['start']}',
                  ),
                ),
              ),
          ],
        ),
        actions: [
          close(d),
          FilledButton.icon(
            icon: const Icon(Icons.place_outlined),
            label: Text(t('На карте', 'Show on map')),
            onPressed: () => Navigator.pop(d, 'map'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return false;
    setState(() {
      if (action == 'year') {
        year = event['start'];
        selected = null;
      }
      preview = event;
    });
    return true;
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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: widget.onExit == null
          ? null
          : BackButton(onPressed: widget.onExit),
      title: Text(t('Историческая карта', 'Historical map')),
      actions: [
        IconButton(
          tooltip: t('Вписать карту', 'Fit map'),
          icon: const Icon(Icons.fit_screen_outlined),
          onPressed: () {
            if (globe) {
              setState(() => resetGlobe++);
            } else {
              transform.value = Matrix4.identity();
            }
          },
        ),
        IconButton(
          tooltip: t('Об источнике', 'About the data'),
          icon: const Icon(Icons.info_outline),
          onPressed: about,
        ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<(Path, List<Map>)>(
        future: base,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                t('Не удалось загрузить атлас', 'Could not load atlas'),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (land, events) = snap.data!;
          final scoped = country == null
              ? events
              : events
                    .where((r) => (r['countries'] as List).contains(country))
                    .toList();
          final rows = historyEventsFor(scoped, period.$1, period.$2, null);
          final lang = widget.russian ? 'ru' : 'en';
          final story = preview ?? closestHistoryEvent(rows, year);
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
            if (r == story) {
              focus = pin;
              final regionName = countryNames
                  .where((c) => c.id == region)
                  .firstOrNull;
              final location = xy is List
                  ? ''
                  : ' · ${t("Регион", "Region")} ${regionName == null ? region : name(regionName)}';
              focusCaption = '${historyEventDate(r)}$location\n${pin.title}';
            }
          }
          Future<void> openPins(List<HistoryEventPin> pins) async {
            Map? event = pinRecords[pins.first];
            if (pins.length > 1) {
              event = await showDialog<Map>(
                context: context,
                builder: (d) => SimpleDialog(
                  title: Text(t('События рядом', 'Nearby events')),
                  children: [
                    for (final pin in pins)
                      ListTile(
                        leading: HistoryEventSeal(pin.kind, size: 32),
                        title: Text(pin.title),
                        subtitle: Text(historyEventDate(pinRecords[pin]!)),
                        onTap: () => Navigator.pop(d, pinRecords[pin]),
                      ),
                    close(d),
                  ],
                ),
              );
            }
            if (!mounted || event == null) return;
            setState(() => preview = event);
            await showDetail(event);
          }

          return Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: globe
                      ? const Color(0xff142f3a)
                      : const Color(0xffadd6df),
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
                                key: ValueKey(resetGlobe),
                                land: landPolygons,
                                polities: globePolities,
                                year: year,
                                focus: focus,
                                focusCaption: focusCaption,
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
                                  return InteractiveViewer(
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
                                                focus: focus,
                                                caption: focusCaption,
                                                russian: widget.russian,
                                                onOpen: openPins,
                                                project: (p) =>
                                                    MatrixUtils.transformPoint(
                                                      transform.value,
                                                      offset +
                                                          Offset(
                                                                180 +
                                                                    p.longitude,
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
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Tooltip(
                              message: globe
                                  ? t('Показать плоскую карту', 'Show flat map')
                                  : t('Показать глобус', 'Show globe'),
                              child: FilledButton.tonalIcon(
                                onPressed: () => setState(() => globe = !globe),
                                icon: Icon(
                                  globe ? Icons.map_outlined : Icons.public,
                                  size: 18,
                                ),
                                label: Text(
                                  MediaQuery.sizeOf(context).width < 350
                                      ? (globe ? '2D' : '3D')
                                      : globe
                                      ? t('Карта', 'Map')
                                      : t('Глобус', 'Globe'),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: FilledButton.tonalIcon(
                              onPressed: choosePeriod,
                              icon: const Icon(
                                Icons.date_range_outlined,
                                size: 18,
                              ),
                              label: Text(
                                '${t("Период", "Period")} · $periodLabel',
                              ),
                            ),
                          ),
                          if (selected != null)
                            Positioned(
                              top: 52,
                              left: 8,
                              right: 8,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Chip(
                                  label: Text(
                                    widget.russian
                                        ? (polityNames[selected!.name]
                                                  as String? ??
                                              selected!.name)
                                        : selected!.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onDeleted: () =>
                                      setState(() => selected = null),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              HistoryTimeline(
                year: year,
                centuryName: centuryName,
                russian: widget.russian,
                countryName: regionName,
                events: scoped,
                eventCount: rows.length,
                period: period,
                onYear: changeYear,
                pickYear: chooseYear,
                pickCentury: chooseCentury,
                pickCountry: () => chooseCountry(events),
                openEvents: () => openIndex(rows),
              ),
            ],
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
