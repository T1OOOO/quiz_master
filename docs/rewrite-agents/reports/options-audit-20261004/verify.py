"""Verify frozen editorial evidence without editing sources or exporting keys."""
import collections
import hashlib
import json
import re
import statistics
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
LEGACY = dict(zip(
    ['сыры_и_молочные_продукты', 'техника_приготовления', 'напитки_и_алкоголь',
     'фрукты_и_овощи', 'мясо_и_рыба', 'специи_и_ингредиенты',
     'сладости_и_десерты', 'традиции_и_этикет'],
    ['cheeses-and-dairy', 'cooking-techniques', 'drinks-and-alcohol',
     'fruits-and-vegetables', 'meat-and-fish', 'spices-and-ingredients',
     'sweets-and-desserts', 'traditions-and-etiquette']))

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def require(condition, message):
    if not condition:
        raise ValueError(message)

def stable(value):
    if value.startswith('gastronomy_') and value[11:] in LEGACY:
        return 'gastronomy-' + LEGACY[value[11:]]
    value = re.sub('[^a-z0-9-]+', '-', value.lower()).strip('-')
    return 'id-' + value if value and (len(value) < 3 or not value[0].isalpha()) else value

def main():
    inventory = read(HERE / 'inventory.json')
    questions, keys, flags = {}, {}, {}
    for source, expected in inventory['source_sha256'].items():
        path = ROOT / source
        require(hashlib.sha256(path.read_bytes()).hexdigest() == expected, f'Source changed: {source}')
        data = read(path)
        if not isinstance(data, dict) or 'questions' not in data:
            continue
        kind = 'ranked' if source.startswith('quizzes/') else 'study'
        pack = stable(data['id']) if kind=='ranked' else data['id']
        private = ({q['id']:q for q in data['questions']} if kind=='ranked'
                   else {q['id']:q for q in read(path.parent/'questions.key.json')['records']})
        for q in data['questions']:
            uid = f"{kind}/{pack}/{q['id']}"
            require(uid not in questions, f'Duplicate {uid}')
            questions[uid] = dict(source=source, **q)
            key = private[q['id']]
            keys[uid] = key.get('correct_multi') or [key['correct_answer']]
            opts = q['options']
            require(all(isinstance(i,int) and 0 <= i < len(opts) for i in keys[uid]), f'Invalid key {uid}')
            lengths = [len(re.sub(r'\s+', ' ', re.sub(r'[*`]', '', o)).strip()) for o in opts]
            longest = max(lengths)
            median = statistics.median(sorted(lengths)[:-1])
            flags[uid] = dict(parentheses=any('(' in o or ')' in o for o in opts),
                length_outlier=longest>=48 and longest>=1.7*max(median,1) and longest-median>=18,
                longest_index=lengths.index(longest))
    counts = inventory['counts']
    require(len(questions)==counts['total_questions']==3998, 'Corpus count mismatch')
    require(sum(uid.startswith('ranked/') for uid in questions)==counts['ranked_questions']==3878, 'Ranked count mismatch')
    require(sum(uid.startswith('study/') for uid in questions)==counts['study_questions']==120, 'Study count mismatch')
    require(sum(f['parentheses'] for f in flags.values())==counts['parentheses']==734, 'Parentheses count mismatch')
    require(sum(f['length_outlier'] for f in flags.values())==counts['length_outlier']==259, 'Length count mismatch')
    candidates = {uid for uid,f in flags.items() if f['parentheses'] or f['length_outlier']}
    require(len(candidates)==counts['flagged_questions']==913, 'Candidate count mismatch')
    unique = [uid for uid,q in questions.items() if sum('(' in o for o in q['options'])==1]
    actual_metrics = dict(single_parenthesis_count=len(unique),
        single_parenthesis_key_matches=sum(next(i for i,o in enumerate(questions[uid]['options']) if '(' in o) in keys[uid] for uid in unique),
        length_outlier_count=259,
        length_outlier_key_matches=sum(f['longest_index'] in keys[uid] for uid,f in flags.items() if f['length_outlier']))
    require(actual_metrics==inventory['metrics'], 'Catalogue metrics mismatch')
    structural, manual = set(), set()
    for name, expected in [('a',469), ('b',468)]:
        folder = HERE/f'audit-{name}'
        for prefix, expected_size in [('',expected), ('manual.',43 if name=='a' else 42)]:
            blind = read(folder/f'{prefix}blind.json')
            reviewed = read(folder/f'{prefix}review.json')
            uids = [r['uid'] for r in blind]
            require(len(uids)==len(set(uids))==expected_size, f'{name}/{prefix} coverage')
            require(uids==[r['uid'] for r in reviewed], f'{name}/{prefix} changed order/IDs')
            target = manual if prefix else structural
            require(not target.intersection(uids), f'{name}/{prefix} duplicate batch')
            target.update(uids)
            for b,r in zip(blind,reviewed):
                uid = b['uid']
                require(uid in questions, f'Unknown {uid}')
                require(b['verdict'] in {'cue','balanced','necessary_qualifier','uncertain'}, f'Unreviewed {uid}')
                require(b['reason'].strip() and b['proposed_action'].strip(), f'Empty reason {uid}')
                require(all(r[k]==v for k,v in b.items()), f'Blind record changed {uid}')
                index = b['signal_index']
                require(index is None or isinstance(index,int) and 0<=index<len(questions[uid]['options']), f'Signal {uid}')
                match = index in keys[uid] if index is not None else None
                require(r['signal_matches_key']==match, f'Key comparison {uid}')
                require(r['confirmed_cue']==(b['verdict']=='cue' and match is True), f'Cue formula {uid}')
        inputs = read(HERE/f'manual-{name}.blind.json')
        require({q['uid'] for q in inputs}=={r['uid'] for r in read(folder/'manual.blind.json')}, f'Manual input coverage {name}')
        for q in inputs:
            original = questions[q['uid']]
            require(all(q[k]==original[k] for k in ('source','text','type','options')), f'Input changed {q["uid"]}')
    require(candidates <= structural and len(structural-candidates)==24, 'Missing candidates or controls')
    lead = read(HERE/'lead-review.json')
    require(len(lead)==85 and {r['uid'] for r in lead}==manual, 'Lead coverage')
    require(all(r['lead_reason'].strip() and r['source']==questions[r['uid']]['source'] for r in lead), 'Lead evidence')
    require(dict(collections.Counter(r['status'] for r in lead))==inventory['lead_verdict_counts'], 'Lead counts')
    print('PASS: 3998 immutable source questions; 913 candidates + 24 controls; 85 semantic records; key comparisons and lead decisions consistent.')

if __name__ == '__main__':
    main()
