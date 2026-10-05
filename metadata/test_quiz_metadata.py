import copy
import json
import unittest
import tempfile
from pathlib import Path

import quiz_metadata as qm


class MetadataTest(unittest.TestCase):
    def setUp(self):
        self.taxonomy = json.loads(Path(__file__).with_name('tags.v1.json').read_text(encoding='utf-8'))
        self.tags = qm.validate_taxonomy(self.taxonomy)

    def test_annotation_file_requires_exact_taxonomy_identity(self):
        ref = {k: self.taxonomy[k] for k in ('taxonomy_id', 'taxonomy_sha256')}
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'annotations.json'
            qm.write_json(path, {'schema_version': 'qm-question-annotations/v1',
                                'taxonomy_ref': ref, 'records': []})
            self.assertEqual(qm.load_annotations([path], self.tags, self.taxonomy), {})
            for bad in [[], {'records': []},
                        {'schema_version': 'other', 'taxonomy_ref': ref, 'records': []},
                        {'schema_version': 'qm-question-annotations/v1',
                         'taxonomy_ref': {**ref, 'taxonomy_sha256': '0' * 64}, 'records': []}]:
                qm.write_json(path, bad)
                with self.subTest(bad=bad), self.assertRaises(ValueError):
                    qm.load_annotations([path], self.tags, self.taxonomy)

    def test_bands_and_invalid_values(self):
        self.assertEqual([qm.band(n) for n in range(1, 11)],
                         ['easy'] * 3 + ['medium'] * 3 + ['hard'] * 2 + ['nightmare'] * 2)
        for value in [0, 11, 2.5, True, '3', None]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                qm.band(value)

    def test_hash_duplicates_and_parent_cycle_are_rejected(self):
        for transform in [lambda d: d['tags'][0].update(label_ru='Changed'),
                          lambda d: d['tags'].append(copy.deepcopy(d['tags'][0]))]:
            altered = copy.deepcopy(self.taxonomy)
            transform(altered)
            with self.assertRaises(ValueError):
                qm.validate_taxonomy(altered)
        altered = copy.deepcopy(self.taxonomy)
        altered['tags'][0]['parent_ids'] = [altered['tags'][0]['id']]
        altered['taxonomy_sha256'] = qm.taxonomy_hash(altered)
        with self.assertRaises(ValueError):
            qm.validate_taxonomy(altered)

    def test_all_any_exclusion_and_cross_culture_rice(self):
        predicate = {'all_tag_ids': ['ingredient:rice'], 'any_tag_ids': [], 'excluded_tag_ids': []}
        self.assertTrue(qm.matches_tags(['ingredient:rice', 'cuisine:italian'], **predicate))
        self.assertFalse(qm.matches_tags(['cuisine:japanese'], **predicate))
        self.assertTrue(qm.matches_tags(['country:it'], any_tag_ids=['country:it', 'cuisine:italian']))
        self.assertFalse(qm.matches_tags(['country:it', 'ingredient:rice'],
                                        any_tag_ids=['country:it'], excluded_tag_ids=['ingredient:rice']))

    def test_annotation_cannot_publish_answer_country(self):
        record = {'provider': 'quiz', 'pack_id': 'sample', 'question_id': 'q1',
                  'difficulty_level': 4, 'editorial_tag_ids': ['country:it', 'domain:geography', 'topic:capital-city'],
                  'context_tag_ids': ['domain:geography', 'topic:capital-city'],
                  'rationale': 'Обычное знание столицы с близкими альтернативами.',
                  'confidence': 'high', 'editorial_flags': []}
        qm.validate_annotation(record, self.tags)
        bad = copy.deepcopy(record)
        bad['context_tag_ids'].append('country:it')
        with self.assertRaises(ValueError):
            qm.validate_annotation(bad, self.tags)
        bad = copy.deepcopy(record)
        bad['editorial_tag_ids'].append('ingredient:unknown')
        with self.assertRaises(ValueError):
            qm.validate_annotation(bad, self.tags)

    def test_rehashed_dictionary_cannot_declassify_private_entities(self):
        for facet in ('country', 'place', 'ingredient', 'cuisine', 'person'):
            altered = copy.deepcopy(self.taxonomy)
            entity = next(tag for tag in altered['tags'] if tag['facet'] == facet)
            entity['player_safe'] = True
            altered['taxonomy_sha256'] = qm.taxonomy_hash(altered)
            with self.subTest(facet=facet), self.assertRaises(ValueError):
                qm.validate_taxonomy(altered)

    def test_annotation_rejects_private_entities_even_with_mutated_safety_flag(self):
        tags = copy.deepcopy(self.tags)
        tags['country:it']['player_safe'] = True
        record = {'provider': 'quiz', 'pack_id': 'sample', 'question_id': 'q1',
                  'difficulty_level': 4,
                  'editorial_tag_ids': ['country:it', 'domain:geography', 'topic:capital-city'],
                  'context_tag_ids': ['country:it', 'domain:geography', 'topic:capital-city'],
                  'rationale': 'Recall among plausible capitals.', 'confidence': 'high', 'editorial_flags': []}
        with self.assertRaises(ValueError):
            qm.validate_annotation(record, tags)

    def test_semantic_answer_preservation(self):
        original = {'id': 'q1', 'text': 'Question', 'options': ['a', 'b'], 'correct_answer': 1,
                    'difficulty': 5, 'explanation': 'Keep'}
        changed = copy.deepcopy(original)
        changed.update(difficulty=3, editorial_tag_ids=['domain:geography'], context_tag_ids=[])
        self.assertEqual(qm.without_metadata(original), qm.without_metadata(changed))
        changed['options'].reverse()
        self.assertNotEqual(qm.without_metadata(original), qm.without_metadata(changed))

    def test_null_source_difficulty_can_be_replaced_without_losing_other_fields(self):
        original = {'id': 'q1', 'text': 'Question', 'difficulty': None, 'correct_answer': 1}
        changed = {**original, 'difficulty': 4}
        self.assertEqual(qm.without_metadata(original), qm.without_metadata(changed))
        study = {'id': 'q2', 'difficulty': 'начальный', 'correct_answer': 2}
        self.assertEqual(qm.without_metadata(study), study)

    def test_public_catalog_retains_canonical_pack_identity(self):
        source = {'provider': 'quiz', 'pack_id': 'lotr_fellowship_100', 'question_id': 'lotr_f_1',
                  'path': 'quizzes/Cinema/LOTR/lotr_fellowship_100.json'}
        # Discover the actual frozen path rather than duplicate a guessed file path.
        source['path'] = next(p['path'] for p in qm.read_json(qm.TASK / 'INVENTORY.json')['packs']
                              if p['id'] == source['pack_id'])
        row = {'difficulty_level': 4, 'context_tag_ids': ['domain:screen', 'franchise:middle-earth']}
        catalog = qm.make_catalog([source], {qm.identity(source): row}, self.tags)
        self.assertEqual(catalog[0]['quiz_id'], 'lotr-fellowship-100')
        self.assertEqual(catalog[0]['difficulty_counts']['medium'], 1)
        self.assertNotIn('editorial_tag_ids', catalog[0])

    def test_private_search_matches_labels_aliases_and_both_providers(self):
        rows = [dict(provider=p, pack_id=p, question_id=p, title='T', category='C', text='Q',
                     difficulty_level=4, difficulty='medium', editorial_tag_ids=['country:it'])
                for p in ('quiz', 'study')]
        index = {'questions': rows}
        self.assertEqual(len(qm.query_index(index, self.tags, query='Италия')), 2)
        self.assertEqual(len(qm.query_index(index, self.tags, all_tags=['country:it'], maximum=3)), 0)
        with self.assertRaises(ValueError):
            qm.query_index(index, self.tags, all_tags=['country:unknown'])
        with self.assertRaises(ValueError):
            qm.query_index(index, self.tags, minimum=7, maximum=2)


if __name__ == '__main__':
    unittest.main()
