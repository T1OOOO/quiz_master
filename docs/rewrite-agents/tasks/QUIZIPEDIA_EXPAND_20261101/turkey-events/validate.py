"""Validate turkey-events/delta.json against knowledge_atlas.json (in-memory merge). Run from repo root."""
import json, re, pathlib

HERE = pathlib.Path(__file__).parent
ATLAS = pathlib.Path('next/apps/quiz_app/assets/quizipedia/knowledge_atlas.json')
FIELDS = ['id', 'title_ru', 'title_en', 'what_ru', 'what_en', 'why_ru', 'why_en',
          'consequences_ru', 'consequences_en', 'source_url']
ld = lambda p: json.load(open(p, encoding='utf-8'))

atlas = ld(ATLAS)
new = ld(HERE / 'delta.json')['events']
eras = {e['era'] for e in atlas['events']}
iso2 = {c for e in atlas['events'] for c in e.get('country_ids', [])} | {'TR'}
# also known ISO2 from catalog
cat = ld(ATLAS.parent / 'catalog.json')
iso2 |= {c['id'] for c in cat['countries']}

merged = atlas['events'] + new
ids = [e['id'] for e in merged]
assert len(set(ids)) == len(ids), 'duplicate ids: %s' % {i for i in ids if ids.count(i) > 1}
cyr = re.compile('[А-Яа-яЁё]')
for e in new:
    for f in FIELDS:
        assert isinstance(e.get(f), str) and e[f].strip(), (e['id'], f)
    assert re.fullmatch(r'[a-z0-9_]+', e['id']), e['id']
    assert isinstance(e['year'], int) and not isinstance(e['year'], bool), e['id']
    if 'end_year' in e:
        assert isinstance(e['end_year'], int) and e['end_year'] >= e['year'], e['id']
    assert e['era'] in eras, (e['id'], e['era'])
    assert e['source_url'].startswith('https://'), e['id']
    for f in FIELDS[1:-1]:
        if f.endswith('_ru'):
            assert cyr.search(e[f]), (e['id'], f)
        else:
            assert not cyr.search(e[f]), (e['id'], f)
    c = e.get('country_ids')
    assert isinstance(c, list) and c and len(set(c)) == len(c), e['id']
    assert all(x in iso2 for x in c), (e['id'], c)
    assert set(e) <= set(FIELDS) | {'year', 'end_year', 'approximate', 'era', 'country_ids'}, (e['id'], set(e))
assert [e['year'] for e in new] == sorted(e['year'] for e in new), 'delta not sorted'
merged.sort(key=lambda e: e['year'])
years = [e['year'] for e in merged]
clash = sorted({e['id'] for e in new if years.count(e['year']) > 1})
print('ok: %d new, %d merged; year clashes with existing (no date question): %s' % (len(new), len(merged), clash or 'none'))
