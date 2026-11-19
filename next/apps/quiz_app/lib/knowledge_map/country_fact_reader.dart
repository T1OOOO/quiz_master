import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'country_number_format.dart';
import '../country_labels_ru.dart';
import 'map_state.dart';

/// Build once per asset load. Every story keeps its original source.
Map<String, List<MapInterestingFact>> countryReadingLists(
  List<MapCountry> countries,
  List<MapLandmark> places,
  List capitals,
  Map capitalFacts, {
  List dishes = const [],
  List foodSources = const [],
}) {
  final lists = {
    for (final c in countries) c.id: [...c.interestingFacts],
  };
  for (final feature in capitals) {
    final p = feature['properties'] as Map;
    for (final raw
        in capitalFacts[p['fact_id'] ?? p['id']] as List? ?? const []) {
      final fact = MapInterestingFact.fromJson(
        raw,
        subjectRu: p['name_ru'] is String
            ? "Столица · ${russianCountryLabel(p['name_ru'])}"
            : null,
        subjectEn: p['name_en'] is String ? "Capital · ${p['name_en']}" : null,
      );
      if (fact != null) lists[p['country_id']]?.add(fact);
    }
  }
  for (final place in places) {
    final fact = MapInterestingFact.fromJson(
      {
        'text_ru': place.explanationRu,
        'text_en': place.explanationEn,
        'source_url': place.sourceUrl,
      },
      subjectRu: 'Место · ${place.nameRu}',
      subjectEn: 'Place · ${place.nameEn}',
    );
    if (fact != null) lists[place.countryId]?.add(fact);
  }
  final foodUrls = {
    for (final source in foodSources.whereType<Map>())
      source['id']: source['url'],
  };
  for (final dish in dishes.whereType<Map>()) {
    final owners = countries
        .where((c) => c.nameEn == dish['country_en'])
        .toList();
    if (owners.length != 1) continue;
    final source = (dish['source_ids'] as List? ?? const [])
        .map((id) => foodUrls[id])
        .whereType<String>()
        .firstOrNull;
    final fact = MapInterestingFact.fromJson(
      {
        'text_ru': dish['summary_ru'],
        'text_en': dish['summary_en'],
        'source_url': source,
      },
      subjectRu: 'Кухня · ${dish['name_ru']}',
      subjectEn: 'Cuisine · ${dish['name_en']}',
    );
    if (fact != null) lists[owners.single.id]!.add(fact);
  }
  final reference = countries.where(
    (c) =>
        const {'SM', 'MT', 'LU', 'IS', 'AU', 'CH'}.contains(c.id) &&
        (c.area ?? 0) > 0,
  );
  for (final c in countries) {
    final stories = lists[c.id]!;
    final seenRu = <String>{}, seenEn = <String>{};
    final pages = <String>{};
    stories.removeWhere((fact) {
      final ru = fact.textRu.trim(), en = fact.textEn.trim();
      // The country and its capital can paraphrase the same site, e.g. the Seine.
      final page = fact.source.toString().replaceFirst(RegExp(r'/$'), '');
      if (seenRu.contains(ru) || seenEn.contains(en) || pages.contains(page)) {
        return true;
      }
      seenRu.add(ru);
      seenEn.add(en);
      pages.add(page);
      return false;
    });
    if (stories.length != 1 || (c.area ?? 0) <= 0) continue;
    final others = reference.where((other) => other.id != c.id).toList();
    double distance(MapCountry other) => math.log(other.area! / c.area!).abs();
    others.sort((a, b) => distance(a).compareTo(distance(b)));
    if (others.isEmpty) continue;
    final other = others.first;
    String area(MapCountry place, bool ru) =>
        formatCountryNumber(place.area, russian: ru).replaceFirst('≈ ', '');
    stories.add(
      MapInterestingFact(
        subjectRu: 'География · Площадь',
        subjectEn: 'Geography · Area',
        textRu:
            'Площадь территории — около ${area(c, true)} км². Для сравнения: ${other.nameRu} занимает около ${area(other, true)} км².',
        textEn:
            'The territory covers about ${area(c, false)} km². For comparison, ${other.nameEn} covers about ${area(other, false)} km².',
        source: Uri.parse(
          'https://github.com/mledoze/countries/blob/master/countries.json',
        ),
      ),
    );
  }
  return lists;
}

/// A country shares its reading history between the directory and map panel.
class CountryFactRotation {
  static final session = CountryFactRotation();
  final _read = <String, Set<String>>{};
  SharedPreferences? _preferences;

  Future<void> restore() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
    } catch (_) {
      // Storage can be disabled in a browser. Rotation still works in memory.
    }
  }

  final _random = math.Random();

  MapInterestingFact next(String id, List<MapInterestingFact> facts) {
    final key = 'atlas.reading.v1.$id';
    final seen = _read.putIfAbsent(id, () {
      final stored = _preferences?.get(key);
      return stored is List ? stored.whereType<String>().toSet() : <String>{};
    });
    var remaining = facts.where((f) => !seen.contains(f.textEn)).toList();
    if (remaining.isEmpty) {
      final previous = seen.lastOrNull;
      seen.clear();
      remaining = facts
          .where((f) => facts.length == 1 || f.textEn != previous)
          .toList();
    }
    final next = remaining[_random.nextInt(remaining.length)];
    seen.add(next.textEn);
    final storage = _preferences;
    if (storage != null) {
      unawaited(
        storage
            .setStringList(key, seen.toList())
            .catchError((Object _) => false),
      );
    }
    return next;
  }
}

class CountryFactReader extends StatefulWidget {
  const CountryFactReader({
    super.key,
    required this.countryId,
    required this.facts,
    required this.rotation,
    required this.russian,
  });
  final String countryId;
  final List<MapInterestingFact> facts;
  final CountryFactRotation rotation;
  final bool russian;

  @override
  State<CountryFactReader> createState() => _CountryFactReaderState();
}

class _CountryFactReaderState extends State<CountryFactReader> {
  late MapInterestingFact story;

  void advance() =>
      story = widget.rotation.next(widget.countryId, widget.facts);

  @override
  void initState() {
    super.initState();
    advance();
  }

  @override
  void didUpdateWidget(CountryFactReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countryId != widget.countryId) advance();
  }

  Future<void> openSource() async {
    try {
      if (await launchUrl(story.source, mode: LaunchMode.externalApplication)) {
        return;
      }
    } on PlatformException {
      // Report the failure in the reader so the user can keep their place.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.russian
                ? 'Не удалось открыть источник'
                : 'Could not open the source',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = widget.russian;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xffecf3ed),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xff317562), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ru
                ? (story.subjectRu ?? 'Интересные факты')
                : (story.subjectEn ?? 'Interesting facts'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xff345d50),
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              ru ? story.textRu : story.textEn,
              key: const ValueKey('current-country-fact'),
              style: const TextStyle(
                fontSize: 18,
                height: 1.48,
                color: Color(0xff172e2a),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 6,
            children: [
              if (widget.facts.length > 1)
                TextButton.icon(
                  onPressed: () => setState(advance),
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: Text(ru ? 'Ещё факт' : 'Another fact'),
                ),
              TextButton.icon(
                onPressed: openSource,
                icon: const Icon(Icons.open_in_new, size: 15),
                label: Text(ru ? 'Источник' : 'Source'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
