"""Controlled editorial metadata. This directory is never a public asset."""

import argparse
import hashlib
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TASK = ROOT / 'docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005'
STUDY_IDS = ('nature', 'geography-countries', 'history', 'greek-mythology',
             'nature-evolution', 'geography-maps')
ANNOTATION_FIELDS = {'provider', 'pack_id', 'question_id', 'difficulty_level',
                     'editorial_tag_ids', 'context_tag_ids', 'rationale', 'confidence', 'editorial_flags'}
PRIVATE_FACETS = {'country', 'place', 'ingredient', 'cuisine', 'person'}


def read_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def compact(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode('utf-8')


def digest(value):
    return hashlib.sha256(compact(value)).hexdigest()


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(temporary, path)


def taxonomy_hash(taxonomy):
    return digest({key: value for key, value in taxonomy.items() if key != 'taxonomy_sha256'})


def validate_taxonomy(taxonomy):
    if taxonomy.get('schema_version') != 'qm-taxonomy/v1' or taxonomy.get('taxonomy_id') != 'qm-tags-v1':
        raise ValueError('taxonomy identity')
    if taxonomy.get('taxonomy_sha256') != taxonomy_hash(taxonomy):
        raise ValueError('taxonomy hash')
    facets = [item['id'] for item in taxonomy['facets']]
    if len(facets) != len(set(facets)):
        raise ValueError('duplicate facet')
    tags = {}
    for tag in taxonomy['tags']:
        identifier = tag['id']
        prefix = identifier.split(':')[0] if isinstance(identifier, str) else ''
        expected_facet = {'ingredient-family': 'ingredient', 'skill': 'knowledge_skill'}.get(prefix, prefix)
        if (not isinstance(identifier, str) or not re.fullmatch(r'[a-z][a-z_-]*:[a-z0-9][a-z0-9-]*', identifier)
                or identifier in tags or tag['facet'] not in facets
                or expected_facet != tag['facet']):
            raise ValueError('tag id/facet')
        if any(not isinstance(tag.get(key), str) or not tag[key].strip() for key in ('label_ru', 'label_en')):
            raise ValueError('tag label')
        if type(tag.get('player_safe')) is not bool:
            raise ValueError('tag visibility')
        if tag['facet'] in PRIVATE_FACETS and tag['player_safe']:
            raise ValueError('private tag visibility')
        for key in ('aliases_ru', 'aliases_en', 'parent_ids'):
            values = tag.get(key)
            if (not isinstance(values, list) or any(not isinstance(v, str) or not v.strip() for v in values)
                    or len(values) != len(set(values))):
                raise ValueError('tag list')
        tags[identifier] = tag
    visited, visiting = set(), set()

    def visit(identifier):
        if identifier not in tags:
            raise ValueError('unknown parent')
        if identifier in visiting:
            raise ValueError('parent cycle')
        if identifier in visited:
            return
        visiting.add(identifier)
        for parent in tags[identifier]['parent_ids']:
            visit(parent)
        visiting.remove(identifier)
        visited.add(identifier)
    for identifier in tags:
        visit(identifier)
    collections = set()
    for collection in taxonomy.get('collections', []):
        if collection['id'] in collections:
            raise ValueError('duplicate collection')
        collections.add(collection['id'])
        for key in ('all_tag_ids', 'any_tag_ids', 'excluded_tag_ids'):
            values = collection[key]
            if not isinstance(values, list) or len(values) != len(set(values)) or any(v not in tags for v in values):
                raise ValueError('collection tags')
    return tags


def band(level):
    if type(level) is not int or not 1 <= level <= 10:
        raise ValueError('difficulty must be integer 1..10')
    return 'easy' if level <= 3 else 'medium' if level <= 6 else 'hard' if level <= 8 else 'nightmare'


def matches_tags(tags, all_tag_ids=(), any_tag_ids=(), excluded_tag_ids=()):
    tags = set(tags)
    return (set(all_tag_ids) <= tags and (not any_tag_ids or bool(tags.intersection(any_tag_ids)))
            and not tags.intersection(excluded_tag_ids))


def validate_annotation(record, tags):
    if set(record) != ANNOTATION_FIELDS:
        raise ValueError('annotation fields')
    if record['provider'] not in ('quiz', 'study'):
        raise ValueError('annotation provider')
    for key in ('pack_id', 'question_id', 'rationale'):
        if not isinstance(record[key], str) or not record[key].strip():
            raise ValueError('annotation text')
    band(record['difficulty_level'])
    for key in ('editorial_tag_ids', 'context_tag_ids'):
        values = record[key]
        if (not isinstance(values, list) or any(not isinstance(v, str) or v not in tags for v in values)
                or values != sorted(set(values))):
            raise ValueError('unknown, duplicate or unsorted annotation tag')
    editorial, context = set(record['editorial_tag_ids']), set(record['context_tag_ids'])
    if not context <= editorial or any(not tags[tag]['player_safe'] or
                                      tags[tag]['facet'] in PRIVATE_FACETS for tag in context):
        raise ValueError('unsafe context tag')
    if not any(tags[tag]['facet'] == 'domain' for tag in editorial):
        raise ValueError('missing domain')
    if not any(tags[tag]['facet'] in ('topic', 'franchise') for tag in editorial):
        raise ValueError('missing specific topic')
    if record['confidence'] not in ('high', 'medium', 'low'):
        raise ValueError('confidence')
    flags = record['editorial_flags']
    if not isinstance(flags, list) or any(not isinstance(f, str) or not f.strip() for f in flags):
        raise ValueError('editorial flags')


def without_metadata(question):
    value = {key: item for key, item in question.items()
             if key not in ('difficulty_level', 'editorial_tag_ids', 'context_tag_ids', 'taxonomy_ref')}
    if 'difficulty' in value and not isinstance(value['difficulty'], str):
        value.pop('difficulty')
    return value


def source_records(root=ROOT):
    """Read published sources only; no traversal into draft Study directories."""
    records = []
    for path in sorted((root / 'quizzes').rglob('*.json')):
        pack = read_json(path)
        for question in pack['questions']:
            records.append({'provider': 'quiz', 'pack_id': pack['id'], 'question_id': question['id'],
                            'title': pack['title'], 'category': pack.get('category', ''),
                            'path': path.relative_to(root).as_posix(), 'question': question})
    for module_id in STUDY_IDS:
        directory = root / 'study/modules' / module_id
        candidate = read_json(directory / 'questions.candidate.json')
        key = read_json(directory / 'questions.key.json')
        keyed = {item['id']: item for item in key['records']}
        if len(keyed) != len(key['records']) or set(keyed) != {q['id'] for q in candidate['questions']}:
            raise ValueError('Study key coverage')
        for question in candidate['questions']:
            records.append({'provider': 'study', 'pack_id': candidate['id'], 'question_id': question['id'],
                            'title': candidate['title'], 'category': candidate.get('category', ''),
                            'path': (directory / 'questions.key.json').relative_to(root).as_posix(),
                            'question': {**question, **keyed[question['id']]}})
    keys = [(r['provider'], r['pack_id'], r['question_id']) for r in records]
    if len(keys) != len(set(keys)):
        raise ValueError('duplicate source question')
    return records


def identity(record):
    return record['provider'], record['pack_id'], record['question_id']


def load_annotations(paths, tags, taxonomy):
    records = {}
    expected_ref = {key: taxonomy[key] for key in ('taxonomy_id', 'taxonomy_sha256')}
    for path in paths:
        value = read_json(path)
        if (not isinstance(value, dict) or
                value.get('schema_version') != 'qm-question-annotations/v1' or
                value.get('taxonomy_ref') != expected_ref or
                not isinstance(value.get('records'), list)):
            raise ValueError('annotation schema/taxonomy mismatch: ' + str(path))
        rows = value['records']
        for row in rows:
            validate_annotation(row, tags)
            key = identity(row)
            if key in records:
                raise ValueError('duplicate annotation ' + '/'.join(key))
            records[key] = row
    return records


def check_integrity(inventory, sources):
    expected = {(r['provider'], r['pack_id'], r['question_id']): r['semantic_sha256']
                for r in inventory['question_integrity']}
    actual = {identity(r): digest(without_metadata(r['question'])) for r in sources}
    if actual != expected:
        differences = sum(actual.get(key) != expected.get(key) for key in set(actual) | set(expected))
        raise ValueError(f'source integrity/coverage changed: {differences}')


def check_annotations(inventory, sources, annotations, partial=False):
    check_integrity(inventory, sources)
    source_ids = {identity(r) for r in sources}
    if not set(annotations) <= source_ids:
        raise ValueError('annotation has foreign question ID')
    if not partial and set(annotations) != source_ids:
        raise ValueError(f'incomplete annotations: {len(annotations)}/{len(source_ids)}')


def apply_annotations(inventory, sources, annotations, taxonomy, root=ROOT):
    check_annotations(inventory, sources, annotations)
    ref = {key: taxonomy[key] for key in ('taxonomy_id', 'taxonomy_sha256')}
    prepared = []
    for relative in sorted({r['path'] for r in sources}):
        path = root / relative
        value = read_json(path)
        provider = 'quiz' if relative.startswith('quizzes/') else 'study'
        pack_id = value['id'] if provider == 'quiz' else value['pack_id']
        for question in value['questions'] if provider == 'quiz' else value['records']:
            row = annotations[(provider, pack_id, question['id'])]
            question['difficulty' if provider == 'quiz' else 'difficulty_level'] = row['difficulty_level']
            question['editorial_tag_ids'] = row['editorial_tag_ids']
            question['context_tag_ids'] = row['context_tag_ids']
        value['taxonomy_ref'] = ref
        prepared.append((path, value))
    for path, value in prepared:
        write_json(path, value)
    check_integrity(inventory, source_records(root))
    return len(prepared)


def make_index(sources, annotations, taxonomy):
    rows = []
    for source in sources:
        row = annotations[identity(source)]
        rows.append({**{key: source[key] for key in ('provider', 'pack_id', 'question_id', 'title', 'category', 'path')},
                     **{key: row[key] for key in ('difficulty_level', 'editorial_tag_ids', 'context_tag_ids',
                                                  'rationale', 'confidence', 'editorial_flags')},
                     'difficulty': band(row['difficulty_level']), 'text': source['question']['text']})
    rows.sort(key=lambda r: identity(r))
    return {'schema_version': 'qm-question-index/v1', 'taxonomy_ref': {
                key: taxonomy[key] for key in ('taxonomy_id', 'taxonomy_sha256')},
            'difficulty_basis': 'editorial_estimate', 'questions_count': len(rows), 'questions': rows}


def query_index(index, tags, query='', all_tags=(), any_tags=(), exclude_tags=(), minimum=1, maximum=10, selected_band=None):
    band(minimum)
    band(maximum)
    if minimum > maximum or selected_band not in (None, 'easy', 'medium', 'hard', 'nightmare'):
        raise ValueError('invalid difficulty filter')
    if any(identifier not in tags for identifier in (*all_tags, *any_tags, *exclude_tags)):
        raise ValueError('unknown filter tag')
    rows = []
    for record in index['questions']:
        if not minimum <= record['difficulty_level'] <= maximum or (selected_band and record['difficulty'] != selected_band):
            continue
        if not matches_tags(record['editorial_tag_ids'], all_tags, any_tags, exclude_tags):
            continue
        terms = [record['text'], record['title'], record['category']]
        for identifier in record['editorial_tag_ids']:
            tag = tags[identifier]
            terms.extend([identifier, tag['label_ru'], tag['label_en'], *tag['aliases_ru'], *tag['aliases_en']])
        if query.casefold() not in ' '.join(terms).casefold():
            continue
        rows.append(record)
    return rows


def make_catalog(sources, annotations, tags):
    frozen_ids = {pack['id']: pack['canonical_quiz_id'] for pack in read_json(TASK / 'INVENTORY.json')['packs']}
    packs = {}
    for source in sources:
        if source['provider'] != 'quiz':
            continue
        identifier = source['pack_id']
        if identifier not in packs:
            raw = read_json(ROOT / source['path'])
            packs[identifier] = {'quiz_id': frozen_ids[identifier], 'title': raw['title'], 'description': raw['description'],
                                 'category': raw['category'], 'questions_count': 0,
                                 'difficulty_counts': dict.fromkeys(('easy', 'medium', 'hard', 'nightmare'), 0),
                                 'context_search_terms': set()}
        pack = packs[identifier]
        row = annotations[identity(source)]
        pack['questions_count'] += 1
        pack['difficulty_counts'][band(row['difficulty_level'])] += 1
        for tag_id in row['context_tag_ids']:
            tag = tags[tag_id]
            pack['context_search_terms'].update([tag['label_ru'], tag['label_en'], *tag['aliases_ru'], *tag['aliases_en']])
    for pack in packs.values():
        pack['context_search_terms'] = sorted(pack['context_search_terms'])
    return sorted(packs.values(), key=lambda p: p['quiz_id'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--taxonomy', type=Path, default=ROOT / 'metadata/tags.v1.json')
    sub = parser.add_subparsers(dest='command', required=True)
    for name in ('check', 'apply', 'build'):
        command = sub.add_parser(name)
        command.add_argument('annotations', type=Path, nargs='+')
        command.add_argument('--inventory', type=Path, default=TASK / 'INVENTORY.json')
        if name == 'check':
            command.add_argument('--partial', action='store_true')
    search = sub.add_parser('search')
    search.add_argument('--index', type=Path, default=ROOT / 'metadata/question-index.v1.json')
    search.add_argument('--text', default='')
    for key in ('all', 'any', 'exclude'):
        search.add_argument('--' + key, action='append', default=[])
    search.add_argument('--min', type=int, default=1)
    search.add_argument('--max', type=int, default=10)
    search.add_argument('--band', choices=('easy', 'medium', 'hard', 'nightmare'))
    search.add_argument('--ids-only', action='store_true')
    search.add_argument('--output', type=Path)
    args = parser.parse_args()
    taxonomy = read_json(args.taxonomy)
    tags = validate_taxonomy(taxonomy)
    if args.command == 'search':
        index = read_json(args.index)
        if index['taxonomy_ref'] != {key: taxonomy[key] for key in ('taxonomy_id', 'taxonomy_sha256')}:
            raise ValueError('index taxonomy mismatch')
        rows = query_index(index, tags, args.text, args.all, args.any, args.exclude, args.min, args.max, args.band)
        if args.ids_only:
            rows = [{key: row[key] for key in ('provider', 'pack_id', 'question_id')} for row in rows]
        if args.output:
            write_json(args.output, rows)
        else:
            print(json.dumps(rows, ensure_ascii=False, indent=2))
        return
    inventory = read_json(args.inventory)
    sources = source_records()
    annotations = load_annotations(args.annotations, tags, taxonomy)
    check_annotations(inventory, sources, annotations, getattr(args, 'partial', False))
    if args.command == 'apply':
        count = apply_annotations(inventory, sources, annotations, taxonomy)
        print(f'Applied metadata to {count} source files; all non-metadata fields preserved.')
    elif args.command == 'build':
        write_json(ROOT / 'metadata/question-index.v1.json', make_index(sources, annotations, taxonomy))
        write_json(ROOT / 'next/apps/quiz_app/assets/catalog.json', make_catalog(sources, annotations, tags))
        print(f'Private index: {len(annotations)}; public discovery: 126 quiz packs, safe terms only.')
    else:
        print(f'Validated {len(annotations)}/{len(sources)} annotations; source integrity preserved.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError) as error:
        raise SystemExit(str(error))
