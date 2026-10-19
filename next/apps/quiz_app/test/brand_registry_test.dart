import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shipped brand registry has substantial dated and sourced coverage', () {
    final doc = jsonDecode(
      File('assets/quizipedia/brands.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(doc['schema_version'], 'qm-brand-atlas/v1');
    final brands = (doc['brands'] as List).cast<Map<String, dynamic>>();
    final owners = (doc['owners'] as List).cast<Map<String, dynamic>>();
    final sources = (doc['sources'] as List).cast<Map<String, dynamic>>();
    expect(brands.length, greaterThanOrEqualTo(60));
    final sourceIds = sources.map((s) => s['id']).toSet();
    final ownerIds = owners.map((s) => s['id']).toSet();
    final byId = {for (final brand in brands) brand['id']: brand};
    expect(byId['samsung']!['founded_year'], 1969);
    expect(byId['porsche']!['founded_year'], 1931);
    expect(byId['nestle']!['date_scope'], 'predecessor');
    expect(byId['pepsi']!['logo_history'][0]['year'], 1951);
    expect(byId['prada']!['source_ids'], isNot(contains('lvmh_history')));
    expect(byId['warner_bros']!['owner_id'], 'skydance');
    expect(byId['electronic_arts']!['owner_id'], 'ea_consortium');
    expect(byId['dior']!['former_names'], isEmpty);
    expect(byId['google']!['former_names'][0]['quiz_enabled'], isFalse);
    expect(sourceIds.length, sources.length);
    expect(ownerIds.length, owners.length);
    expect(brands.map((b) => b['id']).toSet().length, brands.length);
    for (final source in sources) {
      final uri = Uri.parse(source['url'] as String);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
      expect(DateTime.tryParse(source['checked_on'] as String), isNotNull);
    }
    void references(Map<String, dynamic> row) {
      final ids = row['source_ids'] as List;
      expect(ids, isNotEmpty);
      expect(
        ids.every(sourceIds.contains),
        isTrue,
        reason: '${row['id'] ?? row}',
      );
    }

    for (final owner in owners) {
      references(owner);
    }
    for (final brand in brands) {
      references(brand);
      expect(ownerIds, contains(brand['owner_id']));
      expect(
        DateTime.tryParse(brand['ownership_checked_on'] as String),
        isNotNull,
      );
      expect(brand['ownership_note_ru'], isNotEmpty);
      expect(brand['facts'], isNotEmpty);
      for (final key in ['facts', 'former_names', 'logo_history']) {
        for (final row in (brand[key] as List).cast<Map<String, dynamic>>()) {
          references(row);
        }
      }
    }
    expect(
      brands.where((b) => (b['former_names'] as List).isNotEmpty).length,
      greaterThanOrEqualTo(10),
    );
    expect(
      brands.where((b) => (b['logo_history'] as List).isNotEmpty).length,
      greaterThanOrEqualTo(10),
    );
    expect(
      brands.map((b) => b['sector_en']).toSet().length,
      greaterThanOrEqualTo(5),
    );
    expect(
      brands.map((b) => b['country_en']).toSet().length,
      greaterThanOrEqualTo(8),
    );
  });
}
