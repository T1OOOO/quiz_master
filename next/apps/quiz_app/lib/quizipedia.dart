/// Local, unranked visual practice. Answers stay outside ranked API models.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _catalogAsset = 'assets/quizipedia/catalog.json';

class QuizipediaPoint {
  const QuizipediaPoint(this.x, this.y);
  final double x;
  final double y;
  @override
  bool operator ==(Object other) =>
      other is QuizipediaPoint && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

/// For callers holding viewport coordinates. Child-local InteractiveViewer
/// callbacks are already in scene coordinates and must not call this again.
QuizipediaPoint scenePoint(
  QuizipediaPoint point, {
  required double scale,
  required QuizipediaPoint translation,
}) => QuizipediaPoint(
  (point.x - translation.x) / scale,
  (point.y - translation.y) / scale,
);

class QuizipediaFeature {
  const QuizipediaFeature({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.polygons,
    this.flag,
  });
  final String id;
  final String nameRu;
  final String nameEn;
  final List<List<List<QuizipediaPoint>>> polygons;
  final String? flag;

  bool contains(QuizipediaPoint point) => polygons.any(
    (polygon) =>
        polygon.isNotEmpty &&
        _inRing(point, polygon.first) &&
        !polygon.skip(1).any((hole) => _inRing(point, hole)),
  );
}

bool _inRing(QuizipediaPoint point, List<QuizipediaPoint> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if ((a.y > point.y) != (b.y > point.y) &&
        point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

Map<String, dynamic> _record(Object? value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$label object');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _records(
  Object? value,
  String label, {
  int minimum = 1,
}) {
  if (value is! List || value.length < minimum) {
    throw FormatException('$label list');
  }
  return [for (final row in value) _record(row, label)];
}

String _string(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key required');
  }
  return value;
}

double _number(
  Map<String, dynamic> row,
  String key, {
  double? min,
  double? max,
  bool positive = false,
}) {
  final value = row[key];
  if (value is! num || !value.isFinite) throw FormatException('$key number');
  final n = value.toDouble();
  if ((min != null && n < min) ||
      (max != null && n > max) ||
      (positive && n <= 0)) {
    throw FormatException('$key range');
  }
  return n;
}

void _uniqueIds(List<Map<String, dynamic>> rows, String label) {
  final ids = rows.map((row) => _string(row, 'id')).toList();
  if (ids.toSet().length != ids.length) throw FormatException('$label ids');
}

void _target(Map<String, dynamic> row) {
  for (final key in [
    'id',
    'name_ru',
    'name_en',
    'explanation_ru',
    'explanation_en',
    'source_url',
  ]) {
    _string(row, key);
  }
  final level = row['difficulty_level'];
  if (level is! int || level < 1 || level > 10) {
    throw const FormatException('difficulty_level');
  }
  final tags = row['tag_ids'];
  if (tags is! List ||
      tags.isEmpty ||
      tags.any((tag) => tag is! String || tag.trim().isEmpty) ||
      tags.toSet().length != tags.length) {
    throw const FormatException('tag_ids');
  }
}

class QuizipediaCatalog {
  const QuizipediaCatalog({
    required this.countries,
    required this.countryRows,
    required this.mapTargetIds,
    required this.anatomy,
    required this.landmarks,
    required this.constellations,
    required this.credits,
  });
  final List<QuizipediaFeature> countries;
  final List<Map<String, dynamic>> countryRows;
  final List<String> mapTargetIds;
  final Map<String, dynamic> anatomy;
  final List<Map<String, dynamic>> landmarks;
  final List<Map<String, dynamic>> constellations;
  final List<Map<String, dynamic>> credits;

  factory QuizipediaCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 'qm-quizipedia/v1') {
      throw const FormatException('quizipedia schema');
    }
    final credits = _records(json['credits'], 'credits');
    _uniqueIds(credits, 'credits');
    final creditIds = credits.map((row) => row['id']).toSet();
    for (final credit in credits) {
      for (final key in [
        'attribution',
        'source_url',
        'license',
        'license_url',
      ]) {
        _string(credit, key);
      }
    }
    void checkCredit(Map<String, dynamic> row) {
      if (!creditIds.contains(_string(row, 'credit_id'))) {
        throw const FormatException('credit reference');
      }
    }

    final countryRows = _records(json['countries'], 'countries', minimum: 4);
    _uniqueIds(countryRows, 'countries');
    final rawTargets = json['map_target_ids'];
    if (rawTargets is! List ||
        rawTargets.length < 4 ||
        rawTargets.any((id) => id is! String || id.trim().isEmpty) ||
        rawTargets.toSet().length != rawTargets.length) {
      throw const FormatException('map_target_ids');
    }
    final mapTargetIds = rawTargets.cast<String>();
    final targetIds = mapTargetIds.toSet();
    final countries = <QuizipediaFeature>[];
    for (final row in countryRows) {
      final id = _string(row, 'id');
      final nameRu = _string(row, 'name_ru');
      final nameEn = _string(row, 'name_en');
      if (targetIds.contains(id)) {
        _target(row);
        _string(row, 'flag');
      }
      final rawPolygons = row['polygons'];
      if (rawPolygons is! List || rawPolygons.isEmpty) {
        throw const FormatException('polygons');
      }
      final polygons = <List<List<QuizipediaPoint>>>[];
      for (final rawPolygon in rawPolygons) {
        if (rawPolygon is! List || rawPolygon.isEmpty) {
          throw const FormatException('polygon');
        }
        final rings = <List<QuizipediaPoint>>[];
        for (final rawRing in rawPolygon) {
          if (rawRing is! List || rawRing.length < 4) {
            throw const FormatException('ring');
          }
          final ring = <QuizipediaPoint>[];
          for (final rawPoint in rawRing) {
            if (rawPoint is! List ||
                rawPoint.length != 2 ||
                rawPoint[0] is! num ||
                rawPoint[1] is! num ||
                !(rawPoint[0] as num).isFinite ||
                !(rawPoint[1] as num).isFinite) {
              throw const FormatException('polygon point');
            }
            final x = (rawPoint[0] as num).toDouble();
            final y = (rawPoint[1] as num).toDouble();
            if (x < 0 || x > 1 || y < 0 || y > 1) {
              throw const FormatException('polygon coordinate');
            }
            ring.add(QuizipediaPoint(x, y));
          }
          if (ring.first != ring.last) throw const FormatException('open ring');
          rings.add(ring);
        }
        polygons.add(rings);
      }
      countries.add(
        QuizipediaFeature(
          id: id,
          nameRu: nameRu,
          nameEn: nameEn,
          polygons: polygons,
          flag: row['flag'] as String?,
        ),
      );
    }
    if (!targetIds.every(
      (id) => countries.any((country) => country.id == id),
    )) {
      throw const FormatException('map target reference');
    }

    final anatomy = _record(json['anatomy'], 'anatomy');
    _string(anatomy, 'image_asset');
    _number(anatomy, 'width', positive: true);
    _number(anatomy, 'height', positive: true);
    checkCredit(anatomy);
    final anatomyTargets = _records(
      anatomy['targets'],
      'anatomy targets',
      minimum: 4,
    );
    _uniqueIds(anatomyTargets, 'anatomy targets');
    for (final row in anatomyTargets) {
      _target(row);
      final hotspots = _records(row['hotspots'], 'hotspots');
      for (final spot in hotspots) {
        _number(spot, 'x', min: 0, max: 1);
        _number(spot, 'y', min: 0, max: 1);
        _number(spot, 'radius', positive: true, max: 1);
      }
    }
    anatomy['targets'] = anatomyTargets;

    final landmarks = _records(json['landmarks'], 'landmarks', minimum: 4);
    _uniqueIds(landmarks, 'landmarks');
    for (final row in landmarks) {
      _target(row);
      _string(row, 'image_asset');
      checkCredit(row);
      final iso = _string(row, 'country_iso2');
      if (!RegExp(r'^[A-Z]{2}$').hasMatch(iso)) {
        throw const FormatException('country_iso2');
      }
      _string(row, 'city_ru');
      _string(row, 'city_en');
    }
    for (final key in ['city_ru', 'city_en']) {
      if (landmarks.map((row) => row[key]).toSet().length < 4) {
        throw FormatException('$key needs four distinct cities');
      }
    }

    final constellations = _records(
      json['constellations'],
      'constellations',
      minimum: 4,
    );
    _uniqueIds(constellations, 'constellations');
    for (final row in constellations) {
      _target(row);
      checkCredit(row);
      final stars = _records(row['stars'], 'stars', minimum: 2);
      _uniqueIds(stars, 'stars');
      final starIds = stars.map((star) => star['id']).toSet();
      for (final star in stars) {
        _string(star, 'name');
        final ra = _number(star, 'ra_hours', min: 0, max: 24);
        if (ra == 24) throw const FormatException('ra_hours');
        _number(star, 'dec_degrees', min: -90, max: 90);
        _number(star, 'magnitude');
      }
      final lines = row['lines'];
      if (lines is! List ||
          lines.isEmpty ||
          lines.any(
            (line) =>
                line is! List ||
                line.length != 2 ||
                line[0] == line[1] ||
                !starIds.contains(line[0]) ||
                !starIds.contains(line[1]),
          )) {
        throw const FormatException('constellation lines');
      }
    }
    final allTargetIds = [
      ...mapTargetIds,
      ...anatomyTargets.map((row) => row['id'] as String),
      ...landmarks.map((row) => row['id'] as String),
      ...constellations.map((row) => row['id'] as String),
    ];
    if (allTargetIds.toSet().length != allTargetIds.length) {
      throw const FormatException('duplicate target id');
    }
    return QuizipediaCatalog(
      countries: countries,
      countryRows: countryRows,
      mapTargetIds: mapTargetIds,
      anatomy: anatomy,
      landmarks: landmarks,
      constellations: constellations,
      credits: credits,
    );
  }
}

class QuizipediaSession {
  QuizipediaSession(
    List<String> targets,
    this.optionFactory, {
    math.Random? random,
  }) : targets = List.unmodifiable(targets),
       _random = random ?? math.Random() {
    if (targets.isEmpty || targets.toSet().length != targets.length) {
      throw ArgumentError('unique targets required');
    }
    restart();
  }
  final List<String> targets;
  final List<String> Function(String correct) optionFactory;
  final math.Random _random;
  final List<String> seen = [];
  late List<String> _remaining;
  late String current;
  late List<String> options;
  int score = 0;
  bool submitted = false;

  void _advance() {
    current = _remaining.removeLast();
    seen.add(current);
    final candidates = optionFactory(current).toSet()..remove(current);
    if (candidates.length < 3) throw ArgumentError('four choices required');
    final distractors = candidates.toList()..shuffle(_random);
    options = [current, ...distractors.take(3)]..shuffle(_random);
    submitted = false;
  }

  bool submit(String answer) {
    if (submitted) return false;
    submitted = true;
    if (answer == current) score++;
    return answer == current;
  }

  bool get finished => submitted && _remaining.isEmpty;
  void next() {
    if (!submitted || _remaining.isEmpty) return;
    _advance();
  }

  void restart() {
    _remaining = List<String>.from(targets)..shuffle(_random);
    seen.clear();
    score = 0;
    _advance();
  }
}

/// Fixed J2000 educational projection. Largest RA gap is placed outside the
/// shape, RA increases left, and x/y use the same angular scale.
Map<String, Offset> projectConstellation(
  List<Map<String, dynamic>> stars,
  Size size,
) {
  if (stars.isEmpty) return {};
  final sorted =
      stars.map((star) => (star['ra_hours'] as num).toDouble()).toList()
        ..sort();
  var largestGap = -1.0;
  var start = sorted.first;
  for (var i = 0; i < sorted.length; i++) {
    final next = i == sorted.length - 1 ? sorted.first + 24 : sorted[i + 1];
    final gap = next - sorted[i];
    if (gap > largestGap) {
      largestGap = gap;
      start = next % 24;
    }
  }
  final centerDec =
      stars
          .map((star) => (star['dec_degrees'] as num).toDouble())
          .reduce((a, b) => a + b) /
      stars.length;
  final cosine = math
      .cos(centerDec * math.pi / 180)
      .abs()
      .clamp(.01, 1.0)
      .toDouble();
  final raw = <String, Offset>{};
  for (final star in stars) {
    var ra = (star['ra_hours'] as num).toDouble();
    if (ra < start) ra += 24;
    raw[star['id'] as String] = Offset(
      -ra * 15 * cosine,
      -(star['dec_degrees'] as num).toDouble(),
    );
  }
  final xs = raw.values.map((point) => point.dx);
  final ys = raw.values.map((point) => point.dy);
  final minX = xs.reduce((a, b) => a < b ? a : b);
  final maxX = raw.values.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
  final minY = ys.reduce((a, b) => a < b ? a : b);
  final maxY = raw.values.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
  final availableW = math.max(1.0, size.width - 48).toDouble();
  final availableH = math.max(1.0, size.height - 48).toDouble();
  final spanX = math.max(.0001, maxX - minX).toDouble();
  final spanY = math.max(.0001, maxY - minY).toDouble();
  final scale = math.min(availableW / spanX, availableH / spanY).toDouble();
  return {
    for (final entry in raw.entries)
      entry.key: Offset(
        size.width / 2 + (entry.value.dx - (minX + maxX) / 2) * scale,
        size.height / 2 + (entry.value.dy - (minY + maxY) / 2) * scale,
      ),
  };
}

String _t(BuildContext context, String en, String ru) =>
    Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

String _localized(
  BuildContext context,
  Map<String, dynamic> row,
  String stem,
) => _t(context, row['${stem}_en'] as String, row['${stem}_ru'] as String);

enum _Module { map, anatomy, landmarks, sky }

String _moduleTitle(BuildContext context, _Module module) => switch (module) {
  _Module.map => _t(context, 'World map and flags', 'Карта и флаги'),
  _Module.anatomy => _t(context, 'Endocrine system', 'Эндокринная система'),
  _Module.landmarks => _t(
    context,
    'Landmark photographs',
    'Фотографии достопримечательностей',
  ),
  _Module.sky => _t(
    context,
    'J2000 constellation atlas',
    'Атлас созвездий J2000',
  ),
};

class QuizipediaPage extends StatefulWidget {
  const QuizipediaPage({super.key, this.bundle, this.onExit});
  final VoidCallback? onExit;
  final AssetBundle? bundle;
  @override
  State<QuizipediaPage> createState() => _QuizipediaPageState();
}

class _QuizipediaPageState extends State<QuizipediaPage> {
  late Future<QuizipediaCatalog> _catalog = _load();
  bool _challenge = false;

  Future<QuizipediaCatalog> _load() async {
    final source = await (widget.bundle ?? rootBundle).loadString(
      _catalogAsset,
    );
    return QuizipediaCatalog.fromJson(_record(jsonDecode(source), 'catalog'));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_t(context, 'Quizipedia', 'Квизипедия')),
      leading: widget.onExit == null
          ? null
          : IconButton(
              tooltip: _t(context, 'Quiz library', 'Все викторины'),
              icon: const Icon(Icons.home_outlined),
              onPressed: widget.onExit,
            ),
      actions: [
        IconButton(
          tooltip: _t(context, 'Credits', 'Источники'),
          icon: const Icon(Icons.info_outline),
          onPressed: () async {
            try {
              final catalog = await _catalog;
              if (context.mounted) _showCredits(context, catalog);
            } catch (_) {
              // The visible load error offers Retry.
            }
          },
        ),
      ],
    ),
    body: FutureBuilder<QuizipediaCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _LoadError(onRetry: () => setState(() => _catalog = _load()));
        }
        final catalog = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _t(
                context,
                'Local unranked learning practice',
                'Локальная тренировка без рейтинга',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(_t(context, 'Explore', 'Изучение')),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(_t(context, 'Challenge', 'Вызов')),
                ),
              ],
              selected: {_challenge},
              onSelectionChanged: (values) =>
                  setState(() => _challenge = values.first),
            ),
            const SizedBox(height: 16),
            for (final module in _Module.values)
              Card(
                child: ListTile(
                  leading: Icon(switch (module) {
                    _Module.map => Icons.public,
                    _Module.anatomy => Icons.accessibility_new,
                    _Module.landmarks => Icons.photo,
                    _Module.sky => Icons.nightlight,
                  }),
                  title: Text(_moduleTitle(context, module)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _QuizGame(
                        catalog: catalog,
                        module: module,
                        challenge: _challenge,
                        bundle: widget.bundle ?? rootBundle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _t(
              context,
              'Quizipedia image or catalog could not load.',
              'Не удалось загрузить изображение или каталог Quizipedia.',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(_t(context, 'Retry', 'Повторить')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(_t(context, 'Exit', 'Выйти')),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showCredits(BuildContext context, QuizipediaCatalog catalog) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, 'Credits', 'Источники')),
        content: SizedBox(
          width: 460,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final credit in catalog.credits)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(credit['attribution'] as String),
                        Text(credit['license'] as String),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(credit['source_url'] as String),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(_t(context, 'Source', 'Источник')),
                            ),
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(credit['license_url'] as String),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(_t(context, 'License', 'Лицензия')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t(context, 'Close', 'Закрыть')),
          ),
        ],
      ),
    );

class _QuizGame extends StatefulWidget {
  const _QuizGame({
    required this.catalog,
    required this.module,
    required this.challenge,
    required this.bundle,
  });
  final QuizipediaCatalog catalog;
  final _Module module;
  final bool challenge;
  final AssetBundle bundle;
  @override
  State<_QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<_QuizGame> {
  late final List<Map<String, dynamic>> _targets = switch (widget.module) {
    _Module.map =>
      widget.catalog.countryRows
          .where((row) => widget.catalog.mapTargetIds.contains(row['id']))
          .toList(),
    _Module.anatomy =>
      (widget.catalog.anatomy['targets'] as List).cast<Map<String, dynamic>>(),
    _Module.landmarks => widget.catalog.landmarks,
    _Module.sky => widget.catalog.constellations,
  };
  late QuizipediaSession _session;
  final TransformationController _controller = TransformationController();
  final Map<String, Future<ui.Image>> _images = {};
  String? _selected;
  String? _exploreId;
  String? _starInfo;
  int _questionIndex = 0;
  bool _wasCorrect = false;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    final ids = _targets.map((row) => row['id'] as String).toList();
    final roundIds = List<String>.from(ids)..shuffle();
    _session = QuizipediaSession(roundIds.take(10).toList(), (correct) {
      if (widget.module != _Module.landmarks || !_reverse) return ids;
      final correctRow = _row(correct);
      final en = {correctRow['city_en'] as String};
      final ru = {correctRow['city_ru'] as String};
      final candidates = <String>[correct];
      for (final row in _targets) {
        final cityEn = row['city_en'] as String;
        final cityRu = row['city_ru'] as String;
        if (!en.contains(cityEn) && !ru.contains(cityRu)) {
          en.add(cityEn);
          ru.add(cityRu);
          candidates.add(row['id'] as String);
        }
      }
      return candidates;
    });
    _exploreId = ids.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final future in _images.values) {
      future.then((image) => image.dispose(), onError: (Object _) {});
    }
    super.dispose();
  }

  Map<String, dynamic> _row(String id) =>
      _targets.firstWhere((row) => row['id'] == id);
  String _name(String id) => _localized(context, _row(id), 'name');
  String get _currentId => widget.challenge ? _session.current : _exploreId!;
  Map<String, dynamic> get _current => _row(_currentId);
  bool get _reverse => _questionIndex.isOdd;
  bool get _submitted => widget.challenge && _session.submitted;

  Future<ui.Image> _loadImage(String asset) =>
      _images.putIfAbsent(asset, () async {
        final data = await widget.bundle.load(asset);
        final bytes = Uint8List.fromList(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final codec = await ui.instantiateImageCodec(bytes);
        try {
          final frame = await codec.getNextFrame();
          return frame.image;
        } finally {
          codec.dispose();
        }
      });

  void _retryImage(String asset) => setState(() {
    _images.remove(asset);
  });

  void _select(String? id) {
    if (_submitted) return;
    setState(() {
      if (widget.challenge) {
        _selected = id;
      } else {
        _exploreId = id ?? _exploreId;
      }
    });
  }

  void _submit() {
    if (_selected == null || _submitted) return;
    setState(() {
      _wasCorrect = _session.submit(_selected!);
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      _wasCorrect
          ? _t(context, 'Correct', 'Верно')
          : _t(context, 'Incorrect', 'Неверно'),
      Directionality.of(context),
    );
  }

  void _next() {
    setState(() {
      if (_session.finished) {
        _showResult = true;
        return;
      }
      _questionIndex++;
      _session.next();
      _selected = null;
      _starInfo = null;
      _controller.value = Matrix4.identity();
    });
  }

  void _restart() {
    setState(() {
      _questionIndex = 0;
      _session.restart();
      _showResult = false;
      _selected = null;
      _starInfo = null;
      _controller.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final row = _current;
    final imageAsset = switch (widget.module) {
      _Module.anatomy => widget.catalog.anatomy['image_asset'] as String,
      _Module.landmarks => row['image_asset'] as String,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(_moduleTitle(context, widget.module)),
        actions: [
          IconButton(
            tooltip: _t(context, 'Credits', 'Источники'),
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCredits(context, widget.catalog),
          ),
        ],
      ),
      body: SafeArea(
        child: imageAsset == null
            ? _content(null)
            : FutureBuilder<ui.Image>(
                future: _loadImage(imageAsset),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _LoadError(onRetry: () => _retryImage(imageAsset));
                  }
                  return _content(snapshot.data);
                },
              ),
      ),
    );
  }

  Widget _content(ui.Image? image) {
    if (_showResult) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t(context, 'Round complete', 'Раунд завершён'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                context,
                'Score: ${_session.score} / ${_session.targets.length}',
                'Счёт: ${_session.score} / ${_session.targets.length}',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _restart,
              child: Text(_t(context, 'Restart', 'Начать заново')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t(context, 'Exit', 'Выйти')),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.challenge
                ? _t(
                    context,
                    'Challenge · local unranked',
                    'Вызов · без рейтинга',
                  )
                : _t(
                    context,
                    'Explore · local unranked',
                    'Изучение · без рейтинга',
                  ),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (widget.challenge)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _t(
                  context,
                  'Question ${_questionIndex + 1} of ${_session.targets.length} · Score ${_session.score}',
                  'Вопрос ${_questionIndex + 1} из ${_session.targets.length} · Счёт ${_session.score}',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(_prompt(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _visual(image),
          if (widget.module == _Module.sky)
            Text(
              _t(
                context,
                'Fixed J2000 learning atlas; patterns are not IAU boundaries or the current sky.',
                'Учебный атлас J2000: рисунки не являются границами МАС или текущим небом.',
              ),
            ),
          if (_starInfo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_starInfo!),
            ),
          const SizedBox(height: 12),
          if (widget.challenge) _challengeControls() else _exploreControls(),
          if (_submitted) _feedback(),
          const SizedBox(height: 8),
          if (widget.challenge)
            TextButton(
              onPressed: _restart,
              child: Text(_t(context, 'Restart', 'Начать заново')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t(context, 'Exit', 'Выйти')),
          ),
        ],
      ),
    );
  }

  String _prompt() {
    if (!widget.challenge) {
      return _t(
        context,
        'Choose an item to explore',
        'Выберите объект для изучения',
      );
    }
    if (widget.module == _Module.map) {
      return _reverse
          ? _t(
              context,
              'Which country is highlighted?',
              'Какая страна выделена?',
            )
          : _t(
              context,
              'Tap the country for this flag: ${_current['flag']}',
              'Нажмите на страну с этим флагом: ${_current['flag']}',
            );
    }
    if (widget.module == _Module.anatomy) {
      return _reverse
          ? _t(context, 'Which gland is highlighted?', 'Какая железа выделена?')
          : _t(
              context,
              'Tap the spot for ${_name(_currentId)}',
              'Нажмите на точку: ${_name(_currentId)}',
            );
    }
    if (widget.module == _Module.landmarks) {
      return _reverse
          ? _t(
              context,
              'Which city is this landmark in?',
              'В каком городе находится эта достопримечательность?',
            )
          : _t(context, 'Name this landmark', 'Назовите достопримечательность');
    }
    return _t(
      context,
      'Name this constellation pattern',
      'Назовите рисунок созвездия',
    );
  }

  Widget _visual(ui.Image? image) => switch (widget.module) {
    _Module.map => _mapView(),
    _Module.anatomy => _anatomyView(image!),
    _Module.landmarks => _photoView(image!),
    _Module.sky => _skyView(),
  };

  Widget _challengeControls() {
    final tapMode =
        (widget.module == _Module.map || widget.module == _Module.anatomy) &&
        !_reverse;
    final options = _session.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tapMode)
          Text(
            _t(
              context,
              'Tap the picture or use a numbered choice. Then press Check.',
              'Нажмите на рисунок или выберите номер. Затем нажмите «Проверить».',
            ),
          ),
        if (tapMode)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < options.length; i++)
                _choiceButton(
                  id: options[i],
                  label: _t(
                    context,
                    'Spot ${widget.module == _Module.anatomy ? _targets.indexWhere((row) => row['id'] == options[i]) + 1 : i + 1}',
                    'Точка ${widget.module == _Module.anatomy ? _targets.indexWhere((row) => row['id'] == options[i]) + 1 : i + 1}',
                  ),
                  semantic: _t(context, 'Choice ${i + 1}', 'Вариант ${i + 1}'),
                ),
            ],
          )
        else
          for (final id in options)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _choiceButton(
                id: id,
                label: widget.module == _Module.landmarks && _reverse
                    ? _localized(context, _row(id), 'city')
                    : _name(id),
                semantic: widget.module == _Module.landmarks && _reverse
                    ? _localized(context, _row(id), 'city')
                    : _name(id),
              ),
            ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _selected == null || _submitted ? null : _submit,
          child: Text(_t(context, 'Check', 'Проверить')),
        ),
      ],
    );
  }

  Widget _choiceButton({
    required String id,
    required String label,
    required String semantic,
  }) {
    final selected = _selected == id;
    return Semantics(
      label: semantic,
      child: OutlinedButton(
        onPressed: _submitted ? null : () => _select(id),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: selected
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _exploreControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_name(_currentId), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(_localized(context, _current, 'explanation')),
      if (widget.module == _Module.landmarks)
        Text(
          _t(
            context,
            'City: ${_localized(context, _current, 'city')}',
            'Город: ${_localized(context, _current, 'city')}',
          ),
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final row in _targets)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _exploreId = row['id'] as String;
                  _starInfo = null;
                  _controller.value = Matrix4.identity();
                });
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(_localized(context, row, 'name')),
            ),
        ],
      ),
    ],
  );

  Widget _feedback() {
    final correct = _current;
    return Semantics(
      liveRegion: true,
      child: Card(
        key: const Key('quizipedia-feedback'),
        color: _wasCorrect
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _wasCorrect
                    ? _t(context, 'Correct', 'Верно')
                    : _t(context, 'Incorrect', 'Неверно'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _t(
                  context,
                  'Correct answer: ${_name(_currentId)}',
                  'Правильный ответ: ${_name(_currentId)}',
                ),
              ),
              if (widget.module == _Module.landmarks)
                Text(
                  _t(
                    context,
                    'City: ${_localized(context, correct, 'city')}',
                    'Город: ${_localized(context, correct, 'city')}',
                  ),
                ),
              Text(_localized(context, correct, 'explanation')),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _next,
                child: Text(_t(context, 'Next', 'Далее')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sceneViewport(double ratio, Widget Function(Size) scene) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 700.0).toDouble();
          final height = width / ratio;
          final size = Size(width, height);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  height: height,
                  child: ClipRect(
                    child: InteractiveViewer(
                      key: const Key('quizipedia-viewport'),
                      transformationController: _controller,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(100),
                      minScale: 1,
                      maxScale: 6,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: scene(size),
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: _t(context, 'Zoom in', 'Увеличить'),
                      icon: const Icon(Icons.zoom_in),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: () => _zoom(1.5),
                    ),
                    IconButton(
                      tooltip: _t(context, 'Zoom out', 'Уменьшить'),
                      icon: const Icon(Icons.zoom_out),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: () => _zoom(1 / 1.5),
                    ),
                    IconButton(
                      tooltip: _t(context, 'Reset view', 'Сбросить вид'),
                      icon: const Icon(Icons.center_focus_strong),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      onPressed: () => _controller.value = Matrix4.identity(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  void _zoom(double factor) {
    final current = _controller.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 6.0);
    final ratio = next / current;
    _controller.value = _controller.value.clone()
      ..scaleByDouble(ratio, ratio, ratio, 1);
  }

  Widget _mapView() => _sceneViewport(2, (size) {
    final highlight = widget.challenge
        ? (_reverse || _submitted ? _currentId : null)
        : _exploreId;
    return Semantics(
      label: _t(context, 'Interactive world map', 'Интерактивная карта мира'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          // InteractiveViewer gives its child a child-local scene position.
          final point = QuizipediaPoint(
            details.localPosition.dx / size.width,
            details.localPosition.dy / size.height,
          );
          String? hit;
          for (final country in widget.catalog.countries.reversed) {
            if (country.contains(point)) {
              hit = country.id;
              break;
            }
          }
          if (widget.challenge ||
              (hit != null && widget.catalog.mapTargetIds.contains(hit))) {
            _select(hit); // Ocean clears a tentative selection.
          }
        },
        child: CustomPaint(
          key: const Key('quizipedia-map'),
          size: size,
          painter: _MapPainter(
            features: widget.catalog.countries,
            highlighted: highlight,
            selected: _selected,
            correct: _submitted ? _currentId : null,
            numbers: widget.challenge && !_reverse
                ? _session.options
                : const [],
            showLabels: !widget.challenge,
            russian: Localizations.localeOf(context).languageCode == 'ru',
          ),
        ),
      ),
    );
  });

  Widget _anatomyView(ui.Image image) {
    final anatomy = widget.catalog.anatomy;
    final ratio =
        (anatomy['width'] as num).toDouble() /
        (anatomy['height'] as num).toDouble();
    final allSpots = <_Hotspot>[];
    for (var i = 0; i < _targets.length; i++) {
      final row = _targets[i];
      for (final spot
          in (row['hotspots'] as List).cast<Map<String, dynamic>>()) {
        allSpots.add(
          _Hotspot(
            row['id'] as String,
            i + 1,
            (spot['x'] as num).toDouble(),
            (spot['y'] as num).toDouble(),
            (spot['radius'] as num).toDouble(),
          ),
        );
      }
    }
    return _sceneViewport(
      ratio,
      (size) => Semantics(
        label: _t(
          context,
          'Endocrine diagram with numbered spots',
          'Схема эндокринной системы с пронумерованными точками',
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            if (_submitted) return;
            final p = Offset(
              details.localPosition.dx / size.width,
              details.localPosition.dy / size.height,
            );
            final hits = allSpots
                .where((spot) {
                  final dx = (p.dx - spot.x) * size.width;
                  final dy = (p.dy - spot.y) * size.height;
                  final radius = math.max(
                    22.0,
                    spot.radius * math.min(size.width, size.height),
                  );
                  return dx * dx + dy * dy <= radius * radius;
                })
                .map((spot) => spot.id)
                .toSet()
                .toList();
            if (hits.isEmpty) {
              if (widget.challenge) _select(null);
            } else if (hits.length == 1) {
              _select(hits.first);
            } else {
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _t(
                            context,
                            'Choose the intended numbered spot',
                            'Выберите нужную пронумерованную точку',
                          ),
                        ),
                      ),
                      for (final id in hits)
                        ListTile(
                          title: Text(
                            widget.challenge
                                ? _t(
                                    context,
                                    'Spot ${_targets.indexWhere((row) => row['id'] == id) + 1}',
                                    'Точка ${_targets.indexWhere((row) => row['id'] == id) + 1}',
                                  )
                                : _name(id),
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _select(id);
                          },
                        ),
                    ],
                  ),
                ),
              );
            }
          },
          child: CustomPaint(
            key: const Key('quizipedia-anatomy'),
            size: size,
            painter: _AnatomyPainter(
              image: image,
              spots: allSpots,
              numbers: {for (final spot in allSpots) spot.id: spot.number},
              highlighted: widget.challenge
                  ? (_reverse || _submitted ? _currentId : null)
                  : _exploreId,
              selected: _selected,
              correct: _submitted ? _currentId : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoView(ui.Image image) {
    final width = image.width.toDouble(), height = image.height.toDouble();
    return Semantics(
      label: _t(context, 'Photograph', 'Фотография'),
      child: SizedBox(
        height: 320,
        child: Center(
          child: RawImage(
            image: image,
            fit: BoxFit.contain,
            width: math.min(600.0, width).toDouble(),
            height: math.min(320.0, height).toDouble(),
          ),
        ),
      ),
    );
  }

  Widget _skyView() {
    final row = _current;
    final stars = (row['stars'] as List).cast<Map<String, dynamic>>();
    final lines = (row['lines'] as List).cast<List>();
    final canInspect = !widget.challenge || _submitted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sceneViewport(1.2, (size) {
          final points = projectConstellation(stars, size);
          return Semantics(
            label: _t(
              context,
              'Constellation star pattern',
              'Звёздный рисунок созвездия',
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: canInspect
                  ? (details) {
                      Map<String, dynamic>? nearest;
                      var distance = double.infinity;
                      for (final star in stars) {
                        final at = points[star['id']]!;
                        final d = (details.localPosition - at).distance;
                        if (d < distance) {
                          distance = d;
                          nearest = star;
                        }
                      }
                      if (nearest != null && distance <= 24) {
                        setState(() => _starInfo = _starDescription(nearest!));
                      }
                    }
                  : null,
              child: CustomPaint(
                key: const Key('quizipedia-sky'),
                size: size,
                painter: _SkyPainter(stars, lines, points),
              ),
            ),
          );
        }),
        if (canInspect)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final star in stars)
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _starInfo = _starDescription(star)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(star['name'] as String),
                ),
            ],
          ),
      ],
    );
  }

  String _starDescription(Map<String, dynamic> star) => _t(
    context,
    '${star['name']} · magnitude ${star['magnitude']}',
    '${star['name']} · звёздная величина ${star['magnitude']}',
  );
}

class _Hotspot {
  const _Hotspot(this.id, this.number, this.x, this.y, this.radius);
  final String id;
  final int number;
  final double x, y, radius;
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.features,
    required this.highlighted,
    required this.selected,
    required this.correct,
    required this.numbers,
    required this.showLabels,
    required this.russian,
  });
  final List<QuizipediaFeature> features;
  final String? highlighted, selected, correct;
  final List<String> numbers;
  final bool showLabels, russian;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffd9edfc),
    );
    for (final feature in features) {
      for (final polygon in feature.polygons) {
        final path = Path()..fillType = PathFillType.evenOdd;
        for (final ring in polygon) {
          path.moveTo(ring.first.x * size.width, ring.first.y * size.height);
          for (final point in ring.skip(1)) {
            path.lineTo(point.x * size.width, point.y * size.height);
          }
          path.close();
        }
        final fill = feature.id == correct
            ? const Color(0xff3caa70)
            : feature.id == selected
            ? const Color(0xffffa335)
            : feature.id == highlighted
            ? const Color(0xff8167ce)
            : const Color(0xffd5d8d0);
        canvas.drawPath(path, Paint()..color = fill);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xff737d82),
        );
      }
    }
    if (showLabels) {
      for (final feature in features) {
        if (feature.id != highlighted) continue;
        final at = _centroid(feature, size);
        _paintLabel(
          canvas,
          at,
          russian ? feature.nameRu : feature.nameEn,
          Colors.black,
          Colors.white,
        );
      }
    }
    for (var i = 0; i < numbers.length; i++) {
      final feature = features
          .where((feature) => feature.id == numbers[i])
          .firstOrNull;
      if (feature == null) continue;
      _paintLabel(
        canvas,
        _centroid(feature, size),
        '${i + 1}',
        Colors.white,
        const Color(0xff263d58),
      );
    }
  }

  Offset _centroid(QuizipediaFeature feature, Size size) {
    final ring = feature.polygons.first.first;
    final points = ring.length > 1 && ring.first == ring.last
        ? ring.take(ring.length - 1)
        : ring;
    var x = 0.0, y = 0.0, count = 0;
    for (final point in points) {
      x += point.x;
      y += point.y;
      count++;
    }
    return Offset(x / count * size.width, y / count * size.height);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      highlighted != old.highlighted ||
      selected != old.selected ||
      correct != old.correct ||
      showLabels != old.showLabels ||
      russian != old.russian ||
      numbers != old.numbers;
}

class _AnatomyPainter extends CustomPainter {
  const _AnatomyPainter({
    required this.image,
    required this.spots,
    required this.numbers,
    required this.highlighted,
    required this.selected,
    required this.correct,
  });
  final ui.Image image;
  final List<_Hotspot> spots;
  final Map<String, int> numbers;
  final String? highlighted, selected, correct;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint(),
    );
    for (final spot in spots) {
      final at = Offset(spot.x * size.width, spot.y * size.height);
      final color = spot.id == correct
          ? const Color(0xff218455)
          : spot.id == selected
          ? const Color(0xffef8b1c)
          : spot.id == highlighted
          ? const Color(0xff7250be)
          : const Color(0xff263d58);
      canvas.drawCircle(at, 18, Paint()..color = color);
      canvas.drawCircle(
        at,
        18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
      final number = numbers[spot.id];
      if (number != null) {
        _paintLabel(canvas, at, '$number', Colors.white, Colors.transparent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter old) =>
      image != old.image ||
      highlighted != old.highlighted ||
      selected != old.selected ||
      correct != old.correct ||
      numbers != old.numbers;
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter(this.stars, this.lines, this.points);
  final List<Map<String, dynamic>> stars;
  final List<List> lines;
  final Map<String, Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff09192e),
    );
    for (final line in lines) {
      canvas.drawLine(
        points[line[0]]!,
        points[line[1]]!,
        Paint()
          ..color = const Color(0xff76a5cc)
          ..strokeWidth = 1.5,
      );
    }
    for (final star in stars) {
      final magnitude = (star['magnitude'] as num).toDouble();
      final radius = (5 - magnitude / 2).clamp(2.5, 7.0).toDouble();
      canvas.drawCircle(
        points[star['id']]!,
        radius,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      stars != old.stars || lines != old.lines || points != old.points;
}

void _paintLabel(
  Canvas canvas,
  Offset center,
  String text,
  Color foreground,
  Color background,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: foreground,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final rect = Rect.fromCenter(
    center: center,
    width: painter.width + 8,
    height: painter.height + 4,
  );
  if (background != Colors.transparent) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = background,
    );
  }
  painter.paint(canvas, rect.topLeft + const Offset(4, 2));
}
