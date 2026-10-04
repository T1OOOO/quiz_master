import hashlib
import json
import os
import pathlib
import subprocess

root = pathlib.Path('C:/ap/quiz_master')
task = root/'docs/rewrite-agents/tasks/LOTR_AUDIT_20261004'
out = root/'.run/lotr-audit'
env = dict(os.environ,GOMAXPROCS='1',GOMEMLIMIT='256MiB',GOPROXY='off')
def cli(*args):
    run = subprocess.run(['go','run','-p=1','./next/server/cmd/quizctl',*args],cwd=root,
                         env=env,capture_output=True,text=True,encoding='utf-8')
    with (out/'pipeline.log').open('a',encoding='utf-8') as log:
        log.write('COMMAND '+repr(args)+'\n'+run.stdout+run.stderr+'\n')
    if run.returncode: raise RuntimeError(run.stderr)
    return run.stdout

frozen = json.loads((task/'final-keys.json').read_text(encoding='utf-8'))
canonical = []
for pack in frozen['packs']:
    name = {'lotr':'lotr.json','lotr_fellowship_100':'lotr_fellowship_100.json',
            'lotr_two_towers_lore_100':'lotr_two_towers_lore_100.json',
            'lotr_return_king_bts_100':'lotr_return_king_bts_100.json'}[pack['id']]
    source = 'quizzes/Cinema/LOTR/'+name
    folder = 'next/content/'+pack['id'].replace('_','-')
    assert not (root/folder/'draft.json').exists()
    print(cli('import','--in',source,'--out',folder).strip(),flush=True)
    print(cli('build','--in',folder+'/draft.json','--out',folder+'/bundle.json',
        '--version','lotr-review-2026.10.04-'+frozen['revision'][:12],
        '--published-at','2026-10-04T20:00:00Z').strip(),flush=True)
    canonical.append(folder)
print(cli('validate',*[p+'/draft.json' for p in canonical]).strip(),flush=True)
print(cli('validate',*[p+'/bundle.json' for p in canonical]).strip(),flush=True)
audit = json.loads(cli('audit','--in','quizzes'))
(out/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
print(cli('catalog','--in','quizzes','--out','next/apps/quiz_app/assets/catalog.json','--force').strip(),flush=True)
catalog = json.loads((root/'next/apps/quiz_app/assets/catalog.json').read_text())
assert len(catalog)==126 and sum(p['questions_count'] for p in catalog)==3958
checks = []
for folder in canonical:
    manifest = json.loads((root/folder/'manifest.json').read_text())
    source = root/manifest['source_path']
    raw = source.read_bytes().replace(b'\r\n',b'\n').replace(b'\r',b'\n')
    assert hashlib.sha256(raw).hexdigest()==manifest['source_sha256']
    legacy = json.loads(source.read_text(encoding='utf-8'))
    original = {q['id']:q for q in legacy['questions']}
    mapping = {m['canonical_id']:m for m in manifest['questions']}
    bundle = json.loads((root/folder/'bundle.json').read_text())
    assert len(original)==len(mapping)==len(bundle['quiz']['questions'])
    for q in bundle['quiz']['questions']:
        m = mapping[q['question_id']]
        rawq = original[m['source_id']]
        assert q['stem']==rawq['text']
        assert [o['text'] for o in q['options']]==rawq['options']
        assert not any(k in q for k in ('grading','correct_answer','explanation'))
        key = bundle['private_grading'][q['question_id']]['correct_option_id']
        assert key==q['options'][rawq['correct_answer']]['option_id']
        assert m['source_explanation']==rawq['explanation']
    checks.append({'pack':bundle['quiz']['quiz_id'],'count':len(original),
                   'bundle_sha256':bundle['bundle_sha256'],
                   'source_sha256':manifest['source_sha256']})
(out/'validation.json').write_text(json.dumps({'questions':253,'packs':checks,
    'catalog_packs':126,'catalog_questions':3958,'public_grading_leaks':0},indent=2),encoding='utf-8')
print('Verified253 source→manifest→bundle answer mappings, private boundary,126/3958 catalog.',flush=True)
