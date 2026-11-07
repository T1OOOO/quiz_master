"""Merge the 5 agent deltas into the Quizipedia assets. Run from repo root. Idempotent guard: refuses if ids exist."""
import json, re, sys
T = 'docs/rewrite-agents/tasks/QUIZIPEDIA_EXPAND_20261101/'
A = 'next/apps/quiz_app/assets/quizipedia/'
ld = lambda p: json.load(open(p, encoding='utf-8'))

def dump_atlas(d):
    s = json.dumps(d, ensure_ascii=False, indent=2)
    # existing file keeps country_ids inline
    s = re.sub(r'"country_ids": \[\s*((?:"[A-Z]{2}",?\s*)+)\]',
               lambda m: '"country_ids": [' + ', '.join(re.findall(r'"([A-Z]{2})"', m.group(1))).join(['"', '"']).replace('"', '', 2) + ']'
               if False else '"country_ids": [' + ', '.join('"%s"' % c for c in re.findall(r'"([A-Z]{2})"', m.group(1))) + ']', s)
    return s + '\n'

if __name__ == '__main__':
    check = '--check' in sys.argv
    # knowledge atlas
    ka = ld(A + 'knowledge_atlas.json')
    if check:
        assert dump_atlas(ka) == open(A + 'knowledge_atlas.json', encoding='utf-8').read(), 'formatter differs'
        print('formatter reproduces file exactly'); sys.exit()
    ev = ld(T + 'events/delta.json')['events']
    dr, bk = ld(T + 'directors/delta.json'), ld(T + 'books/delta.json')
    for key, new in (('events', ev), ('works', dr['works'] + bk['works']), ('people', dr['people'] + bk['people'])):
        have = {x['id'] for x in ka[key]}
        ids = [x['id'] for x in new]
        assert len(set(ids)) == len(ids) and not have & set(ids), (key, set(ids) & have)
        ka[key] += new
    ka['events'].sort(key=lambda e: e['year'])   # stable
    ka['works'].sort(key=lambda w: w['year'])
    open(A + 'knowledge_atlas.json', 'w', encoding='utf-8', newline='\n').write(dump_atlas(ka))
    # country links
    cl = ld(A + 'country_links.json')
    sids = {s['id'] for s in cl['sources']}
    iids = {i['id'] for v in cl['countries'].values() for i in v}
    for n in ('countries-west', 'countries-east'):
        d = ld(T + n + '/delta.json')
        for s in d['sources']:
            assert s['id'] not in sids, s['id']; sids.add(s['id']); cl['sources'].append(s)
        for c, items in d['countries'].items():
            for i in items:
                assert i['id'] not in iids, i['id']; iids.add(i['id'])
                assert i['source_id'] in sids
            cl['countries'].setdefault(c, []).extend(items)
    open(A + 'country_links.json', 'w', encoding='utf-8', newline='\n').write(json.dumps(cl, ensure_ascii=False, indent=2) + '\n')
    print('merged')
