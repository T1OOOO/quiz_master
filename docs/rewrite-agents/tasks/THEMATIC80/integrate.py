"""Import only independently accepted thematic pilots; verify answer mapping."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TASK = Path(__file__).resolve().parent
PACKS = {
    'theme-terminator': ('franchises', 'terminator'),
    'theme-harry-potter': ('franchises', 'harry_potter'),
    'theme-game-of-thrones': ('franchises', 'game_of_thrones'),
    'theme-star-wars': ('franchises', 'star_wars'),
    'theme-pixar': ('screen-games', 'pixar'),
    'theme-dreamworks': ('screen-games', 'dreamworks'),
    'theme-tv-series': ('screen-games', 'tv_series'),
    'theme-game-worlds': ('screen-games', 'game_worlds'),
}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def by_id(records):
    result = {r['id']: r for r in records}
    assert len(result) == len(records), 'duplicate editorial ID'
    return result


def source_path(slug):
    return ROOT / 'quizzes/Cinema/Thematic80' / (slug + '.json')


def accepted():
    all_ids = set()
    results = []
    for pack, (group, slug) in PACKS.items():
        candidate_path = TASK / group / (pack + '.candidate.json')
        key_path = TASK / group / (pack + '.key.json')
        candidate, key = read(candidate_path), read(key_path)
        assert candidate['id'] == pack and key['pack_id'] == pack
        questions, keys = candidate['questions'], by_id(key['records'])
        assert len(questions) == len(keys) == 10
        review_dir = TASK / ('review-franchises-final' if group == 'franchises' else 'review-screen-games')
        reviews = by_id(read(review_dir / 'review.json')['records'])
        blind = by_id(read(review_dir / 'blind.json')['records'])
        hashes = read(review_dir / 'input-sha256.json')
        for p in [candidate_path, key_path]:
            assert hashes[p.name] == hashlib.sha256(p.read_bytes()).hexdigest(), 'review input changed'
        assert set(keys) == {q['id'] for q in questions}
        legacy = {k: candidate[k] for k in ['id', 'title', 'description', 'category']}
        legacy['questions'] = []
        for q in questions:
            qid = q['id']
            assert qid not in all_ids, 'duplicate question across packs'
            all_ids.add(qid)
            assert set(q) == {'id', 'type', 'text', 'options'} and q['type'] == 'choice'
            assert len(q['options']) == len(set(q['options'])) == 4
            assert all(isinstance(o, str) and o.strip() for o in q['options'])
            k, r = keys[qid], reviews[qid]
            assert qid in blind and r['verdict'] == 'accept' and r['sources_checked']
            assert type(k['correct_answer']) is int and 0 <= k['correct_answer'] < 4
            assert k['explanation'].strip() and k['source'].startswith('https://')
            assert len(k['distractors']) == 3 and all(k['distractors'])
            legacy['questions'].append(dict(q, correct_answer=k['correct_answer'], explanation=k['explanation']))
        results.append((pack, source_path(slug), legacy))
    assert len(all_ids) == 80
    return results


def verify(results):
    catalog = read(ROOT / 'next/apps/quiz_app/assets/catalog.json')
    assert len(catalog) == 126 and sum(p['questions_count'] for p in catalog) == 3958
    assert all(set(p) == {'quiz_id', 'title', 'description', 'category', 'questions_count'} for p in catalog)
    for pack, path, expected in results:
        assert read(path) == expected, 'accepted editorial prose or answer changed'
        base = ROOT / 'next/content' / pack
        draft, manifest, bundle = [read(base / f) for f in ['draft.json', 'manifest.json', 'bundle.json']]
        # quizctl preserves source bytes, normalizing only transport line endings.
        canonical_bytes = path.read_bytes().replace(b'\r\n', b'\n').replace(b'\r', b'\n')
        assert manifest['source_sha256'] == hashlib.sha256(canonical_bytes).hexdigest()
        assert manifest['source_path'] == path.relative_to(ROOT).as_posix()
        assert draft['quiz_id'] == bundle['quiz']['quiz_id'] == manifest['canonical_quiz_id'] == pack
        assert len(draft['questions']) == len(manifest['questions']) == len(bundle['quiz']['questions']) == 10
        for original, q, mapping in zip(expected['questions'], draft['questions'], manifest['questions']):
            qid = original['id']
            assert q['question_id'] == mapping['source_id'] == mapping['canonical_id'] == qid
            assert q['stem'] == original['text']
            assert [o['text'] for o in q['options']] == original['options']
            assert [o['source_index'] for o in mapping['options']] == list(range(4))
            assert [o['canonical_id'] for o in mapping['options']] == [o['option_id'] for o in q['options']]
            assert q['grading']['correct_option_id'] == q['options'][original['correct_answer']]['option_id']
            assert mapping['source_explanation'] == original['explanation']
            published = next(p for p in bundle['quiz']['questions'] if p['question_id'] == qid)
            assert published['stem'] == q['stem'] and published['options'] == q['options']
            assert not any(k in published for k in ['grading', 'correct_answer', 'explanation'])
            assert bundle['private_grading'][qid] == q['grading']
        assert [p for p in catalog if p['quiz_id'] == pack][0]['questions_count'] == 10
    print('PASS: 80 accepted questions, source hashes, option/key mappings, explanations and metadata-only 126/3958 catalog')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['assemble', 'verify'])
    args = parser.parse_args()
    accepted_results = accepted()
    if args.mode == 'assemble':
        for _, path, legacy in accepted_results:
            assert not path.exists(), f'refusing overwrite: {path}'
        for _, path, legacy in accepted_results:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(legacy, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print('Assembled 8 independently accepted source packs / 80 questions')
    else:
        verify(accepted_results)
