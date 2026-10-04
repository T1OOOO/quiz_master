import hashlib
import json
import pathlib
import re
import urllib.error
import urllib.request
import uuid

ROOT = pathlib.Path('C:/ap/quiz_master')
BASE = 'https://quiz.kotopedia.org'
def request(path, body=None, token=None, expected=200):
    headers = {'Content-Type':'application/json'}
    if token: headers['Authorization'] = 'Bearer '+token
    raw = None if body is None else json.dumps(body,ensure_ascii=False,separators=(',',':')).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(BASE+path,data=raw,headers=headers),timeout=30) as response:
            code, data = response.status, response.read()
    except urllib.error.HTTPError as error:
        code, data = error.code, error.read()
    assert code==expected,(path,code,expected)
    return json.loads(data) if data else None

def solve(attempt, public, originals, token):
    path = '/v1/attempts/'+attempt['attempt_id']
    request(path+'/reveals',token=token,expected=404)
    for snapshot in attempt['question_snapshots']:
        qid = snapshot['question_id']
        q, original = public[qid], originals[qid]
        assert q['stem']==original['text']
        assert [o['text'] for o in q['options']]==original['options']
        option = q['options'][original['correct_answer']]['option_id']
        assert option in snapshot['option_order']
        answer = {'option_id':option}
        payload = {'answer':answer,'attempt_id':attempt['attempt_id'],
            'participant_id':attempt['participant_id'],'question_id':qid,
            'question_revision':snapshot['question_revision']}
        digest = hashlib.sha256(json.dumps(payload,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
        request(path+'/answers',{'question_id':qid,'question_revision':snapshot['question_revision'],
            'answer':answer,'idempotency_key':str(uuid.uuid4()),'payload_digest':digest},token)
    finished = request(path+'/finish',{},token)
    count = len(attempt['question_snapshots'])
    assert finished['status']=='finished' and finished['server_score']==count
    assert len(finished['history'])==count
    reveals = request(path+'/reveals',token=token)
    assert len(reveals)==count
    for reveal in reveals:
        original = originals[reveal['question_id']]
        assert reveal['correct_answer']['text']==original['options'][original['correct_answer']]
        assert reveal['explanation']==original['explanation']
    return {'questions':count,'score':finished['server_score'],'reveals':len(reveals)}

expected = json.loads((ROOT/'.run/lotr-audit/release/web/version.json').read_text(encoding='utf-8'))
assert request('/version.json')==expected
request('/health/ready')
catalog = request('/assets/assets/catalog.json')
assert len(catalog)==126 and sum(p['questions_count'] for p in catalog)==3958
assert all(set(p)=={'quiz_id','title','description','category','questions_count'} for p in catalog)
guest = request('/v1/guests',{'display_name':'LOTR253 release verification'},expected=201)
results = []
for pack_id in ['lotr','lotr-fellowship-100','lotr-two-towers-lore-100','lotr-return-king-bts-100']:
    manifest = json.loads((ROOT/'next/content'/pack_id/'manifest.json').read_text(encoding='utf-8'))
    source = json.loads((ROOT/manifest['source_path']).read_text(encoding='utf-8'))
    raw = {q['id']:q for q in source['questions']}
    originals = {m['canonical_id']:raw[m['source_id']] for m in manifest['questions']}
    selected = request('/v1/catalog?quiz_id='+pack_id)
    questions = selected['quiz']['questions']
    assert len(questions)==len(originals)
    assert all(not any(k in q for k in ['grading','correct_answer','explanation']) for q in questions)
    public = {q['question_id']:q for q in questions}
    assert set(public)==set(originals)
    seen = set()
    for round_num in range((len(questions)+19)//20):
        attempt = request('/v1/attempts',{'quiz_id':pack_id,'round':round_num},guest['token'],expected=201)
        assert attempt['bundle_sha256']==selected['bundle_sha256']
        ids = {q['question_id'] for q in attempt['question_snapshots']}
        assert not seen.intersection(ids)
        seen.update(ids)
        outcome = solve(attempt,public,originals,guest['token'])
        results.append(dict(outcome,pack=pack_id,round=round_num))
        (ROOT/'.run/lotr-audit/live-progress.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
        print(json.dumps(results[-1]),flush=True)
    assert seen==set(originals)
assert sum(r['questions'] for r in results)==253
# Finish a pre-release attempt using its old, immutable answer/explanation snapshots.
old = json.loads((ROOT/'.run/lotr-audit/old-attempt-private.json').read_text(encoding='utf-8'))
public = {q['question_id']:q for q in old['quiz']['quiz']['questions']}
originals = {re.sub('[^a-z0-9-]+','-',q['id'].lower()).strip('-'):q for q in old['original']['questions']}
assert old['attempt']['bundle_sha256']!=request('/v1/catalog?quiz_id=lotr')['bundle_sha256']
# The pre-release attempt expired unanswered during editorial work.
# Empty attempts cannot finish; verify that guard, then require the separate
# read-only database comparison against the checked pre-release backup.
old_path = '/v1/attempts/'+old['attempt']['attempt_id']
request(old_path+'/reveals',token=old['guest']['token'],expected=404)
error = request(old_path+'/finish',{},old['guest']['token'],expected=400)
assert error['code']=='validation_failed'
proof = json.loads((ROOT/'.run/lotr-audit/historical-db-proof.json').read_text(encoding='utf-8-sig'))
assert proof['old_bundle_sha256']==old['attempt']['bundle_sha256']
assert proof['old_keys_and_explanations_preserved'] and proof['checked_questions']==3
old_result = proof
summary = {'build':expected['buildId'],'live_questions_checked':253,'rounds':results,
           'private_fields_before_finish':'absent','old_attempt_snapshot_preserved':old_result}
(ROOT/'.run/lotr-audit/smoke-result.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False))
