"""Freeze editorial drafts, then apply only an independently accepted revision."""
import argparse
import copy
import hashlib
import json
import random
from collections import Counter
from pathlib import Path

TASK = Path(__file__).resolve().parent
ROOT = TASK.parents[3]
SOURCES = {
    'lotr.json': 'revised-root',
    'lotr_fellowship_100.json': 'revised-root',
    'lotr_two_towers_lore_100.json': 'revised-two-towers',
    'lotr_return_king_bts_100.json': 'revised-return-king',
}
COUNTS = [3, 50, 100, 100]


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2)+'\n').encode())


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                    separators=(',', ':')).encode()).hexdigest()


def freeze():
    packs = []
    originals = []
    for (name, folder), count in zip(SOURCES.items(), COUNTS):
        pack = read(TASK/folder/name)
        original = read(ROOT/'quizzes/Cinema/LOTR'/name)
        assert pack['id'] == original['id']
        assert len(pack['questions']) == len(original['questions']) == count
        assert [q['id'] for q in pack['questions']] == [q['id'] for q in original['questions']]
        for q in pack['questions']:
            options = q['options']
            assert q['type'] == 'choice' and type(q['correct_answer']) is int
            assert 0 <= q['correct_answer'] < len(options)
            assert len(options) >= 4 and len(options) == len(set(options))
            assert all(o.strip() == o and o and '(' not in o and ')' not in o for o in options)
            assert q['text'].strip() and q['explanation'].strip()
        packs.append(pack)
        originals.append({'file': name, 'sha256': digest(original)})
    revision = digest(packs)
    save(TASK/'final-keys.json', {'revision': revision, 'packs': packs})
    candidates = [dict(p, questions=[{k:q[k] for k in ('id','text','options')}
                                     for q in p['questions']]) for p in packs]
    save(TASK/'final-candidates.json', {'revision': revision, 'packs': candidates})
    save(TASK/'original-revisions.json', originals)
    print(json.dumps({'frozen_revision': revision, 'questions': 253}))


def apply():
    frozen = read(TASK/'final-keys.json')
    packs = frozen['packs']
    assert digest(packs) == frozen['revision']
    review = read(TASK/'final-review/review.json')
    assert review['revision'] == frozen['revision']
    records = review['records']
    qids = [q['id'] for p in packs for q in p['questions']]
    assert len(records) == len(qids) == len(set(qids)) == 253
    assert {r['id'] for r in records} == set(qids)
    assert all(r['verdict'] == 'accept' and r['reason'] and r['source'] for r in records)
    # Verify all inputs before the first production file is changed.
    for original in read(TASK/'original-revisions.json'):
        assert digest(read(ROOT/'quizzes/Cinema/LOTR'/original['file'])) == original['sha256']
    changes = []
    distributions = []
    output = []
    for name, reviewed in zip(SOURCES, packs):
        pack = copy.deepcopy(reviewed)
        rng = random.Random('LOTR-review-20261004/'+pack['id'])
        # Assign shuffled, balanced slots separately for each option count.
        groups = {}
        for q in pack['questions']:
            groups.setdefault(len(q['options']), []).append(q)
        for n, questions in groups.items():
            slots = [i % n for i in range(len(questions))]
            rng.shuffle(slots)
            for q, slot in zip(questions, slots):
                before = copy.deepcopy(q)
                correct = q['options'][q['correct_answer']]
                distractors = [o for i,o in enumerate(q['options']) if i != q['correct_answer']]
                rng.shuffle(distractors)
                distractors.insert(slot, correct)
                q['options'], q['correct_answer'] = distractors, slot
                assert q['options'][slot] == correct
                assert set(q['options']) == set(before['options'])
                assert {k:v for k,v in q.items() if k not in ('options','correct_answer')} == {
                    k:v for k,v in before.items() if k not in ('options','correct_answer')}
                changes.append({'id':q['id'], 'correct_text':correct,
                                'before_slot':before['correct_answer'], 'after_slot':slot})
            histogram = Counter(q['correct_answer'] for q in questions)
            assert max(histogram.get(i,0) for i in range(n))-min(histogram.get(i,0) for i in range(n)) <= 1
            distributions.append({'pack':pack['id'], 'option_count':n,
                                  'correct_slots':[histogram.get(i,0) for i in range(n)]})
        output.append((name, pack))
    for name, pack in output:
        save(ROOT/'quizzes/Cinema/LOTR'/name, pack)
    save(TASK/'answer-mapping.json', {'editorial_revision':frozen['revision'],
                                    'distributions':distributions, 'records':changes})
    print(json.dumps({'applied_questions':len(changes), 'distributions':distributions}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['freeze','apply'])
    getattr(__import__(__name__), parser.parse_args().action)()
