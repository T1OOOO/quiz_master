import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map_state.dart';
import 'history_globe.dart';
import 'history_event_symbol.dart';
import 'history_timeline.dart';

export 'history_timeline.dart' show closestHistoryEvent;

const _root = 'assets/quizipedia/map_v2/';
const _centuries = ['XVI', 'XVII', 'XVIII', 'XIX', 'XX'];
int historyCentury(int year) => (year - 1) ~/ 100 + 1;
List<Map> historyEventsFor(
  List<Map> events,
  int year,
  bool wholeCentury,
  String? country,
) {
  final end = historyCentury(year) * 100;
  return events
      .where(
        (e) =>
            e['start'] <= (wholeCentury ? end : year) &&
            e['end'] >= (wholeCentury ? end - 99 : year) &&
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
  bool century = false;
  late bool globe = widget.initialGlobe;
  int resetGlobe = 0;
  late List landPolygons;
  Map<String, dynamic> polityNames = {};
  late String? country = widget.initialCountry;
  late List<MapCountry> countryNames = widget.countries;
  _Polity? selected;
  final transform = TransformationController();
  final packs = <int, Future<List<_Polity>>>{};
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
    transform.dispose();
    super.dispose();
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
        century = true;
        selected = null;
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
      setState(() => country = choice.isEmpty ? null : choice);
    }
  }

  Future<void> showEvents(List<Map> rows, {bool detail = false}) async {
    final lang = widget.russian ? 'ru' : 'en';
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(
          detail
              ? (widget.russian
                    ? HistoryEventStyle.forKind(rows.first['kind']).ru
                    : HistoryEventStyle.forKind(rows.first['kind']).en)
              : '${century ? "$centuryName ${t('век', 'century')}" : year} · $regionName',
        ),
        content: SizedBox(
          width: 480,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (rows.isEmpty)
                Text(
                  t(
                    'Для этого периода и страны пока нет записей. Можно выбрать целый век.',
                    'No entries for this period and country yet. Try the full century.',
                  ),
                ),
              for (final r in rows) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HistoryEventSeal(r['kind'], size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            historyEventDate(r),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            r['title_$lang'],
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r['summary_$lang'],
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(height: 1.4),
                ),
                if (detail || r['place_$lang'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (r['place_$lang'] != null) r['place_$lang'],
                              if (detail)
                                ...countryNames
                                    .where(
                                      (c) => (r['countries'] as List).contains(
                                        c.id,
                                      ),
                                    )
                                    .map(name),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  children: [
                    if (year < r['start'] || year > r['end'])
                      TextButton.icon(
                        icon: const Icon(Icons.timeline),
                        onPressed: () {
                          Navigator.pop(d);
                          changeYear(r['start']);
                        },
                        label: Text(
                          t(
                            'Перейти к ${r['start']} году',
                            'Go to ${r['start']}',
                          ),
                        ),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 15),
                      onPressed: () => launchUrl(
                        Uri.parse(r['source_url']),
                        mode: LaunchMode.externalApplication,
                      ),
                      label: Text(t('Источник', 'Source')),
                    ),
                  ],
                ),
                if (r != rows.last) const Divider(height: 24),
              ],
            ],
          ),
        ),
        actions: [close(d)],
      ),
    );
  }

  void about() => showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(t('Исторические границы', 'Historical boundaries')),
      content: Text(
        t(
          'Реконструкции из Cliopatria v0.0.1 (Bennett и др., Seshat). Контуры упрощены. На светлых участках источник не указывает государство. Фильтр событий использует современные названия стран.',
          'Reconstructions from Cliopatria v0.0.1 (Bennett et al., Seshat). Shapes are simplified. Pale land means no polity shown in the source. Event filters use modern country names.',
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
          final rows = historyEventsFor(scoped, year, century, null);
          final lang = widget.russian ? 'ru' : 'en';
          final pinRecords = <HistoryEventPin, Map>{};
          for (final r in scoped) {
            final location = r['location'];
            if (r['start'] <= year &&
                r['end'] >= year &&
                location is List &&
                location.length == 2) {
              pinRecords[(
                    longitude: (location[0] as num).toDouble(),
                    latitude: (location[1] as num).toDouble(),
                    title: r['title_$lang'] as String,
                    kind: r['kind'] as String,
                  )] =
                  r;
            }
          }
          void openPin(HistoryEventPin pin) =>
              showEvents([pinRecords[pin]!], detail: true);
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
                                eventPins: pinRecords.keys.toList(),
                                onEventTap: openPin,
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
                                  final s = math.min(
                                    box.maxWidth / 360,
                                    box.maxHeight / 180,
                                  );
                                  final offset = Offset(
                                    (box.maxWidth - 360 * s) / 2,
                                    (box.maxHeight - 180 * s) / 2,
                                  );
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
                                            ),
                                          ),
                                          for (final pin in pinRecords.keys)
                                            Positioned(
                                              left:
                                                  offset.dx +
                                                  (pin.longitude + 180) * s -
                                                  historyPinTarget / 2,
                                              top:
                                                  offset.dy +
                                                  (90 - pin.latitude) * s -
                                                  historyPinTarget / 2,
                                              width: historyPinTarget,
                                              height: historyPinTarget,
                                              child: AnimatedBuilder(
                                                animation: transform,
                                                builder: (_, child) =>
                                                    Transform.scale(
                                                      scale:
                                                          1 /
                                                          transform.value
                                                              .getMaxScaleOnAxis(),
                                                      child: child,
                                                    ),
                                                child: historyPinWidget(
                                                  pin,
                                                  () => openPin(pin),
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
                                  globe
                                      ? t('2D · Карта', '2D · Map')
                                      : t('3D · Глобус', '3D · Globe'),
                                ),
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .44,
                ),
                child: SingleChildScrollView(
                  child: HistoryTimeline(
                    year: year,
                    centuryName: centuryName,
                    russian: widget.russian,
                    century: century,
                    countryName: regionName,
                    events: scoped,
                    rows: rows,
                    onYear: changeYear,
                    pickYear: chooseYear,
                    pickCentury: chooseCentury,
                    pickCountry: () => chooseCountry(events),
                    setCentury: (v) => setState(() => century = v),
                    openEvents: () => showEvents(rows),
                    openEvent: (event) => showEvents([event], detail: true),
                  ),
                ),
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
  const _Painter(this.land, this.rows, this.selected, this.offset, this.scale);
  final Path land;
  final List<_Polity> rows;
  final _Polity? selected;
  final Offset offset;
  final double scale;
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
    final fill = Paint()..color = const Color(0xfff3e8cc);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55 / scale
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xff626959);
    final grid = Paint()
      ..color = const Color(0x403a7e86)
      ..strokeWidth = .65 / scale;
    for (double x = 30; x < 360; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, 180), grid);
    }
    for (double y = 30; y < 180; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(360, y), grid);
    }
    canvas.drawPath(land, fill);
    for (final p in rows) {
      final index = p.name.codeUnits.fold<int>(
        0,
        (a, b) => (31 * a + b) % tones.length,
      );
      fill.color = tones[index];
      canvas.drawPath(p.path, fill);
      canvas.drawPath(p.path, line);
    }
    if (selected != null) {
      fill.color = const Color(0xbbffcc64);
      canvas.drawPath(selected!.path, fill);
      line.color = const Color(0xff783e1f);
      line.strokeWidth = 1.5 / scale;
      canvas.drawPath(selected!.path, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Painter old) =>
      old.rows != rows ||
      old.selected != selected ||
      old.offset != offset ||
      old.scale != scale;
}
