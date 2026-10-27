import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice_models.dart';

const _expected = {
  'athens': (
    country: 'GR',
    source: 'https://www.britishmuseum.org/sites/default/files/2023-04/Luxury_and_power_large_print_guide.pdf',
  ),
  'pyramids': (country: 'EG', source: 'https://whc.unesco.org/en/list/86'),
  'nineteenth_amendment': (
    country: 'US',
    source: 'https://www.archives.gov/milestone-documents/19th-amendment',
  ),
  'qin': (
    country: 'CN',
    source: 'https://whc.unesco.org/uploads/nominations/1002.pdf',
  ),
  'islam': (
    country: 'SA',
    source: 'https://www.loc.gov/resource/amed.00277334471/?sp=45&st=text',
  ),
  'tang': (
    country: 'CN',
    source: 'https://www.metmuseum.org/toah/hd/tang/hd_tang.htm',
  ),
  'magna': (
    country: 'GB',
    source: 'https://searcharchives.bl.uk/catalog/040-001102110',
  ),
  'glorious': (
    country: 'GB',
    source: 'https://www.parliament.uk/about/living-heritage/evolutionofparliament/parliamentaryauthority/revolution/',
  ),
  'american_rev': (
    country: 'US',
    source: 'https://www.archives.gov/founding-docs/declaration',
  ),
  'french_rev': (
    country: 'FR',
    source: 'https://gallica.bnf.fr/essentiels/repere/prise-bastille-1789',
  ),
  'meiji': (
    country: 'JP',
    source: 'https://www.ndl.go.jp/portrait/e/pickup/012',
  ),
  'universal_declaration': (
    country: 'FR',
    source: 'https://www.un.org/en/about-us/udhr/history-of-the-declaration',
  ),
  'civil_rights': (
    country: 'US',
    source: 'https://www.archives.gov/milestone-documents/civil-rights-act',
  ),
  'berlin': (
    country: 'DE',
    source: 'https://www.bundesstiftung-aufarbeitung.de/de/vermitteln/bildung/aufbruch-umbruch/mauerfall',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reviewed events use modern-country study locations, not historical borders', () async {
    final atlas = jsonDecode(
      File('assets/quizipedia/knowledge_atlas.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final events = (atlas['events'] as List).cast<Map<String, dynamic>>();
    final byId = {for (final event in events) event['id'] as String: event};
    final mapped = events
        .where((event) => event.containsKey('country_ids'))
        .toList();

    expect(events, hasLength(46));
    expect(mapped, hasLength(14));
    expect(mapped.map((event) => event['id']).toSet(), _expected.keys.toSet());

    final catalog = jsonDecode(
      File('assets/quizipedia/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final geometryIds = (catalog['countries'] as List)
        .cast<Map<String, dynamic>>()
        .where((country) => (country['polygons'] as List).isNotEmpty)
        .map((country) => country['id'] as String)
        .toSet();

    for (final entry in _expected.entries) {
      final event = byId[entry.key]!;
      expect(event['source_url'], entry.value.source);
      expect(event['country_ids'], [entry.value.country]);
      expect(geometryIds, contains(entry.value.country));
    }
    expect(
      events.where((event) => !event.containsKey('country_ids')),
      hasLength(32),
    );
    expect((await loadStudyFacts('all')), hasLength(13834));
  });
}
