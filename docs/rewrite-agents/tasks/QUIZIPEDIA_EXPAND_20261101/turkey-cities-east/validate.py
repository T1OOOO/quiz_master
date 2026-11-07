# Validates delta.json against the live asset. Run: python -I validate.py
import json, os, re, collections
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..'))
ASSETS = os.path.join(ROOT, 'next', 'apps', 'quiz_app', 'assets', 'quizipedia')
base = json.load(open(os.path.join(ASSETS, 'country_links.json'), encoding='utf-8'))
delta = json.load(open(os.path.join(HERE, 'delta.json'), encoding='utf-8'))
KINDS = {'fact', 'landmark', 'wonder', 'filming_location', 'scientist', 'food', 'bridge', 'desert', 'sports_team', 'resource'}
cyr = re.compile('[Ѐ-ӿ]')
errs = []
if set(delta) != {'sources', 'countries'}: errs.append('top-level keys')
if set(delta['countries']) != {'TR'}: errs.append('delta must contain TR only')
base_src = {s['id'] for s in base['sources']}
new_src = [s['id'] for s in delta['sources']]
if base_src & set(new_src): errs.append('source id collision')
if len(new_src) != len(set(new_src)): errs.append('dup new source ids')
allsrc = base_src | set(new_src)
used = set()
for s in delta['sources']:
    if set(s) != {'id', 'title', 'url'}: errs.append('source keys ' + s.get('id', '?'))
    if not s['id'].startswith('tre-'): errs.append('source prefix ' + s['id'])
    if not s['url'].startswith('https://') or not s['title'].strip(): errs.append('bad source ' + s['id'])
base_ids = {i['id'] for v in base['countries'].values() for i in v}
base_names = {i['name_en'].lower() for v in base['countries'].values() for i in v}
base_names_ru = {i['name_ru'].lower() for v in base['countries'].values() for i in v}
seen_ids, seen_names, seen_ru = set(), set(), set()
kc = collections.Counter()
for i in delta['countries']['TR']:
    if set(i) != {'id', 'kind', 'name_en', 'name_ru', 'relation_en', 'relation_ru', 'source_id'}: errs.append('keys ' + i.get('id', '?')); continue
    if not re.fullmatch(r'tre-[a-z0-9]+(-[a-z0-9]+)*', i['id']): errs.append('id format ' + i['id'])
    if i['id'] in base_ids or i['id'] in seen_ids: errs.append('dup id ' + i['id'])
    seen_ids.add(i['id'])
    if i['kind'] not in KINDS: errs.append('kind ' + i['id'])
    for f in ('name_en', 'name_ru', 'relation_en', 'relation_ru'):
        if not i[f].strip(): errs.append('empty %s %s' % (f, i['id']))
    for f in ('name_ru', 'relation_ru'):
        if not cyr.search(i[f]): errs.append('no cyrillic %s %s' % (f, i['id']))
    if i['source_id'] not in allsrc: errs.append('src unresolved ' + i['id'])
    used.add(i['source_id'])
    n = i['name_en'].lower()
    if n in base_names or n in seen_names: errs.append('dup name_en ' + i['name_en'])
    if i['name_ru'].lower() in base_ru if False else (i['name_ru'].lower() in base_names_ru or i['name_ru'].lower() in seen_ru): errs.append('dup name_ru ' + i['name_ru'])
    seen_names.add(n); seen_ru.add(i['name_ru'].lower())
    if not i['relation_en'].rstrip().endswith('.') or not i['relation_ru'].rstrip().endswith('.'): errs.append('no period ' + i['id'])
    for f in ('relation_en', 'relation_ru'):
        if len(i[f]) > 200: errs.append('long %s %s (%d)' % (f, i['id'], len(i[f])))
    kc[i['kind']] += 1
unused = set(new_src) - used
if unused: errs.append('unused sources %s' % sorted(unused))
print('items', sum(kc.values()), dict(kc), 'sources', len(new_src))
print('ERRORS' if errs else 'OK')
for e in errs: print(' ', e)
raise SystemExit(1 if errs else 0)
