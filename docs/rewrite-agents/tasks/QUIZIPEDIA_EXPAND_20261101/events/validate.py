import json, re, os
from collections import Counter
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.abspath(os.path.join(here, '../../../../..'))
A = os.path.join(root, 'next/apps/quiz_app/assets/quizipedia')
atlas = json.load(open(os.path.join(A, 'knowledge_atlas.json'), encoding='utf-8'))
facts = json.load(open(os.path.join(A, 'country_facts.json'), encoding='utf-8'))
cat = json.load(open(os.path.join(A, 'catalog.json'), encoding='utf-8'))
iso = {c['id'] for c in facts['countries']}
geom = {c['id'] for c in cat['countries'] if c['polygons']}
delta = json.load(open(os.path.join(here, 'delta.json'), encoding='utf-8'))['events']
ERAS = {'prehistory', 'ancient', 'medieval', 'early_modern', 'modern', 'contemporary'}
REQ = ['id','year','era','title_ru','title_en','what_ru','what_en','why_ru','why_en','consequences_ru','consequences_en','source_url','country_ids']
cyr = re.compile('[А-Яа-яЁё]')
err = []
old = atlas['events']
ids = [e['id'] for e in old + delta]
for k, v in Counter(ids).items():
    if v > 1: err.append('dup id ' + k)
titles = {e['title_en'].lower() for e in old}
for e in delta:
    for f in REQ:
        if e.get(f) in (None, '', []): err.append(f"{e['id']}: empty {f}")
    if set(e) - set(REQ) - {'approximate', 'end_year'}: err.append(e['id'] + ': extra keys')
    if not isinstance(e['year'], int): err.append(e['id'] + ': year')
    if 'end_year' in e and e['end_year'] < e['year']: err.append(e['id'] + ': end<year')
    if e['era'] not in ERAS: err.append(e['id'] + ': era')
    if not e['source_url'].startswith('https://'): err.append(e['id'] + ': src')
    for f in ('title','what','why','consequences'):
        if not cyr.search(e[f + '_ru']): err.append(f"{e['id']}: {f}_ru no cyrillic")
        if cyr.search(e[f + '_en']): err.append(f"{e['id']}: {f}_en has cyrillic")
    for c in e['country_ids']:
        if c not in iso: err.append(f"{e['id']}: bad iso {c}")
        if c not in geom: err.append(f"{e['id']}: no geometry {c}")
    if len(set(e['country_ids'])) != len(e['country_ids']): err.append(e['id'] + ': dup country')
    if e['title_en'].lower() in titles: err.append(e['id'] + ': dup title')
    for f in ('what','why','consequences'):
        if len(e[f+'_en']) > 190 or len(e[f+'_ru']) > 190: err.append(f"{e['id']}: {f} long {len(e[f+'_en'])}/{len(e[f+'_ru'])}")
merged = sorted(old + delta, key=lambda e: e['year'])
assert all(a['year'] <= b['year'] for a, b in zip(merged, merged[1:]))
ys = Counter(e['year'] for e in merged)
print('delta', len(delta), 'merged', len(merged))
print('year collisions with existing/new:', [y for y, n in ys.items() if n > 1])
print('eras', dict(Counter(e['era'] for e in delta)))
print('countries', dict(Counter(c for e in delta for c in e['country_ids'])))
print('ERRORS' if err else 'OK'); [print(' ', x) for x in err]
