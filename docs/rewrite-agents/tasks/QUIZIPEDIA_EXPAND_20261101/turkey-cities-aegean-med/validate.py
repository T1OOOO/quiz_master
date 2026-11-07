"""Validate delta.json against next/apps/quiz_app/assets/quizipedia/country_links.json.

Run: python validate.py   (from any directory)
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]  # E:/Projects/quiz_master
MAIN = ROOT / 'next/apps/quiz_app/assets/quizipedia/country_links.json'
KINDS = {'fact', 'landmark', 'wonder', 'filming_location', 'scientist', 'food',
         'bridge', 'desert', 'sports_team', 'resource'}
FIELDS = ['id', 'kind', 'name_en', 'name_ru', 'relation_en', 'relation_ru', 'source_id']
CYR = re.compile('[А-Яа-яЁё]')

main = json.loads(MAIN.read_text(encoding='utf-8'))
delta = json.loads((HERE / 'delta.json').read_text(encoding='utf-8'))
errs = []

if set(delta) != {'sources', 'countries'}:
    errs.append(f'top-level keys {sorted(delta)}')
if list(delta['countries']) != ['TR']:
    errs.append(f'countries must be only TR, got {list(delta["countries"])}')

old_src = {s['id'] for s in main['sources']}
new_src = {}
for s in delta['sources']:
    if set(s) != {'id', 'title', 'url'}:
        errs.append(f'source keys {s}')
    if not s['id'].startswith('trae-'):
        errs.append(f'source id prefix {s["id"]}')
    if s['id'] in old_src or s['id'] in new_src:
        errs.append(f'duplicate source id {s["id"]}')
    if not s['url'].startswith('https://') or not s['title'].strip():
        errs.append(f'bad source {s["id"]}')
    new_src[s['id']] = s

old_ids, old_names = set(), set()
for rows in main['countries'].values():
    for r in rows:
        old_ids.add(r['id'])
        for k in ('name_en', 'name_ru'):
            old_names.add(r[k].strip().casefold())

seen_ids, seen_names, used_src = set(), set(), set()
items = delta['countries']['TR']
for r in items:
    if list(r) != FIELDS:
        errs.append(f'{r.get("id")}: field order/keys {list(r)}')
    for f in FIELDS:
        if not str(r.get(f, '')).strip():
            errs.append(f'{r.get("id")}: empty {f}')
    if not re.fullmatch(r'trae-[a-z0-9]+(-[a-z0-9]+)*', r['id']):
        errs.append(f'{r["id"]}: id not kebab trae-')
    if r['id'] in old_ids or r['id'] in seen_ids:
        errs.append(f'{r["id"]}: duplicate id')
    seen_ids.add(r['id'])
    if r['kind'] not in KINDS:
        errs.append(f'{r["id"]}: kind {r["kind"]}')
    for k in ('name_en', 'name_ru'):
        n = r[k].strip().casefold()
        if n in old_names or n in seen_names:
            errs.append(f'{r["id"]}: duplicate {k} {r[k]}')
        seen_names.add(n)
    for k in ('name_ru', 'relation_ru'):
        if not CYR.search(r[k]):
            errs.append(f'{r["id"]}: no Cyrillic in {k}')
    if CYR.search(r['name_en'] + r['relation_en']):
        errs.append(f'{r["id"]}: Cyrillic in English field')
    if len(r['relation_en']) > 190:
        errs.append(f'{r["id"]}: relation_en {len(r["relation_en"])} chars')
    if len(r['relation_ru']) > 215:
        errs.append(f'{r["id"]}: relation_ru {len(r["relation_ru"])} chars')
    if r['source_id'] not in new_src and r['source_id'] not in old_src:
        errs.append(f'{r["id"]}: unresolved source {r["source_id"]}')
    used_src.add(r['source_id'])

for sid in new_src:
    if sid not in used_src:
        errs.append(f'unused new source {sid}')

if errs:
    print('\n'.join(errs))
    sys.exit(1)
kinds = {}
for r in items:
    kinds[r['kind']] = kinds.get(r['kind'], 0) + 1
print(f'OK: {len(items)} items, {len(new_src)} new sources, kinds {kinds}')
