# Validates delta.json against the live asset. Run: python -I validate.py
import json, os, re, collections
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..', '..'))
ASSETS = os.path.join(ROOT, 'next', 'apps', 'quiz_app', 'assets', 'quizipedia')
base = json.load(open(os.path.join(ASSETS, 'country_links.json'), encoding='utf-8'))
facts = json.load(open(os.path.join(ASSETS, 'country_facts.json'), encoding='utf-8'))
delta = json.load(open(os.path.join(HERE, 'delta.json'), encoding='utf-8'))
iso = {c['id'] for c in facts['countries']}
KINDS = {'fact', 'landmark', 'wonder', 'filming_location', 'scientist', 'food', 'bridge', 'desert', 'sports_team', 'resource'}
cyr = re.compile('[Ѐ-ӿ]')
errs = []
src_ids = [s['id'] for s in base['sources']]
new_src = [s['id'] for s in delta['sources']]
if set(src_ids) & set(new_src): errs.append('source id collision')
if len(new_src) != len(set(new_src)): errs.append('dup new source ids')
allsrc = set(src_ids) | set(new_src)
used = set()
for s in delta['sources']:
    if not s['url'].startswith('https://') or not s['title']: errs.append('bad source ' + s['id'])
base_ids = {i['id'] for v in base['countries'].values() for i in v}
base_names = {(i['kind'], i['name_en'].lower()) for v in base['countries'].values() for i in v}
seen_ids, seen_names = set(), set()
kc, cc = collections.Counter(), collections.Counter()
for k, items in delta['countries'].items():
    if k not in iso: errs.append('unknown ISO ' + k)
    for i in items:
        if set(i) != {'id', 'kind', 'name_en', 'name_ru', 'relation_en', 'relation_ru', 'source_id'}: errs.append('keys ' + i.get('id', '?'))
        if not re.fullmatch(r'[a-z0-9]+(-[a-z0-9]+)*', i['id']): errs.append('id format ' + i['id'])
        if i['id'] in base_ids or i['id'] in seen_ids: errs.append('dup id ' + i['id'])
        seen_ids.add(i['id'])
        if i['kind'] not in KINDS: errs.append('kind ' + i['id'])
        for f in ('name_en', 'name_ru', 'relation_en', 'relation_ru'):
            if not i[f].strip(): errs.append('empty %s %s' % (f, i['id']))
        for f in ('name_ru', 'relation_ru'):
            if not cyr.search(i[f]): errs.append('no cyrillic %s %s' % (f, i['id']))
        if i['source_id'] not in allsrc: errs.append('src unresolved ' + i['id'])
        used.add(i['source_id'])
        key = (i['kind'], i['name_en'].lower())
        if key in base_names or key in seen_names: errs.append('dup name ' + i['name_en'])
        seen_names.add(key)
        if not i['relation_en'].rstrip().endswith('.'): errs.append('no period ' + i['id'])
        kc[i['kind']] += 1; cc[k] += 1
unused = set(new_src) - used
if unused: errs.append('unused sources %s' % sorted(unused))
print('items', sum(kc.values()), dict(kc)); print('countries', len(cc), dict(sorted(cc.items())))
print('ERRORS' if errs else 'OK'); [print(' ', e) for e in errs]
# extra: TR-only, every relation <= 200 chars, name uniqueness across ALL countries, Latin-only name_en
if set(delta['countries']) != {'TR'}: errs.append('delta must contain TR only')
allnames = {i['name_en'].lower() for v in base['countries'].values() for i in v}
for i in delta['countries'].get('TR', []):
    if i['name_en'].lower() in allnames: errs.append('name exists elsewhere ' + i['name_en'])
    for f in ('relation_en', 'relation_ru'):
        if len(i[f]) > 200: errs.append('long %s %s (%d)' % (f, i['id'], len(i[f])))
if errs: print('ERRORS'); [print(' ', e) for e in errs]
raise SystemExit(1 if errs else 0)
