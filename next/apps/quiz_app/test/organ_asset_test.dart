import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('shipped anatomy covers major organs and named gland groups', () async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/quizipedia/organ_atlas.json'),
    ) as Map<String, dynamic>;
    final rows = (data['organs'] as List).cast<Map<String, dynamic>>();
    final ids = rows.map((r) => r['id']).toSet();
    expect(ids.length, rows.length);
    expect(
      ids,
      containsAll([
        'bones',
        'skeletal_muscles',
        'brain',
        'spinal_cord',
        'eyes',
        'ears',
        'lungs',
        'heart',
        'liver',
        'stomach',
        'small_intestine',
        'large_intestine',
        'kidneys',
        'bladder',
        'spleen',
        'skin',
        'hypothalamus',
        'pituitary',
        'pineal',
        'thyroid',
        'parathyroids',
        'adrenals',
        'pancreas',
        'ovaries',
        'testes',
        'thymus',
        'parotid',
        'submandibular',
        'sublingual',
        'lacrimal',
        'eccrine_sweat',
        'apocrine_sweat',
        'sebaceous',
        'mammary',
        'prostate',
        'seminal_vesicles',
        'bulbourethral',
        'greater_vestibular',
        'gastric_glands',
        'intestinal_glands',
      ]),
    );
    expect(rows.length, greaterThanOrEqualTo(45));
    expect(
      rows.expand((r) => (r['system_ids'] as List).cast<String>()).toSet(),
      containsAll([
        'nervous',
        'endocrine',
        'digestive',
        'respiratory',
        'cardiovascular',
        'urinary',
        'reproductive',
        'lymphatic',
        'integumentary',
        'sensory',
        'musculoskeletal',
      ]),
    );
    for (final id in ['pancreas', 'ovaries', 'testes']) {
      final row = rows.singleWhere((r) => r['id'] == id);
      expect(
        row['kind'],
        id == 'pancreas'
            ? equals('mixed_gland')
            : anyOf('mixed_gland', 'endocrine_gland'),
      );
      if (id != 'pancreas') expect(row['system_ids'], contains('reproductive'));
      expect(row['system_ids'], contains('endocrine'));
    }
    final questions = (data['questions'] as List).cast<Map<String, dynamic>>();
    expect(questions.length, greaterThanOrEqualTo(24));
    expect(
      questions.map((q) => q['topic']).toSet(),
      containsAll(['function', 'secretion', 'location', 'fact']),
    );
    for (final q in questions) {
      expect((q['option_ids'] as List).toSet().length, 6);
      expect(
        (q['option_ids'] as List).where((id) => id == q['correct_id']).length,
        1,
      );
      expect(q['source_ids'], isNotEmpty);
    }
    expect(data['coverage_note_en'], isNotEmpty);
    expect(data['coverage_note_ru'], isNotEmpty);
  });
}
