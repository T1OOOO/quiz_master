#!/usr/bin/env python3
"""Release-70 candidate verifier for the reviewed minimum-20 catalog.

This script only talks to the supplied candidate URL.  It deliberately keeps
answer keys in the private source tree and never writes tokens, IDs, or keys.
"""
from __future__ import annotations
import argparse, hashlib, json, urllib.error, urllib.parse, urllib.request
from pathlib import Path

BANDS = ('easy', 'medium', 'hard', 'nightmare')
PUBLIC_FORBIDDEN = frozenset({'correct_answer', 'private_grading', 'source_key', 'answer_key'})
NONCATALOG_READER_REFS = {
 ('study-geography-countries','study-geography-countries-001'): '4f6f8946ad7c86d3a7e3076e00243321bdffeca8c2671f8a69f6b9b8ef456bb9',
 ('study-geography-countries','study-geography-countries-002'): '89ed172a4b2ebd6dd18857069a879e261cca05516a1a1b3deb4fe566eb2c44a6',
}

def call(base, path, body=None, token=None, statuses=(200,201)):
    headers={'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    req=urllib.request.Request(base+path, None if body is None else json.dumps(body).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            if response.status not in statuses: raise RuntimeError(f'unexpected HTTP {response.status} for {path}')
            return json.load(response)
    except urllib.error.HTTPError as e:
        if e.code in statuses: return json.load(e)
        raise RuntimeError(f'unexpected HTTP {e.code} for {path}') from e

def http_status(base, path, body=None, token=None):
    headers={'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    req=urllib.request.Request(base+path, None if body is None else json.dumps(body).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as r: return r.status
    except urllib.error.HTTPError as e: return e.code

def require_public_dto(value):
    if isinstance(value, dict):
        bad=PUBLIC_FORBIDDEN & value.keys()
        if bad: raise RuntimeError('public DTO exposes private grading fields')
        for v in value.values(): require_public_dto(v)
    elif isinstance(value, list):
        for v in value: require_public_dto(v)

def load_catalog(path):
    rows=json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(rows,list) or len(rows)!=105: raise RuntimeError('visible catalog must contain exactly 105 banks')
    ids=set(); total=0
    for row in rows:
        if not isinstance(row,dict) or not isinstance(row.get('quiz_id'),str) or row['quiz_id'] in ids: raise RuntimeError('visible catalog IDs are invalid')
        ids.add(row['quiz_id']); n=row.get('questions_count'); counts=row.get('difficulty_counts')
        if type(n) is not int or n<20 or not isinstance(counts,dict) or set(counts)!={'easy','medium','hard','nightmare','unknown'} or sum(counts.values())!=n:
            raise RuntimeError('visible catalog has invalid minimum-20 or difficulty counts')
        total+=n
    if total!=4520: raise RuntimeError('visible catalog must contain exactly 4520 slots')
    return rows

def load_aliases(path):
    evidence=json.loads(path.read_text(encoding='utf-8')); aliases=evidence.get('aliases')
    if not isinstance(aliases,dict) or len(aliases)!=56 or any(not isinstance(k,str) or not isinstance(v,str) for k,v in aliases.items()):
        raise RuntimeError('reviewed pool evidence must contain exactly 56 aliases')
    return aliases

def catalog_for(base, quiz_id, difficulty=None):
    q={'quiz_id':quiz_id}
    if difficulty: q['difficulty']=difficulty
    return call(base, '/v1/catalog?'+urllib.parse.urlencode(q))

def require_catalog_match(row, response):
    require_public_dto(response); quiz=response.get('quiz')
    questions=quiz.get('questions') if isinstance(quiz,dict) else None
    if not isinstance(questions,list) or len(questions)!=row['questions_count'] or not quiz.get('quiz_id'):
        raise RuntimeError('candidate catalog differs from visible catalog')
    ids=set()
    for q in questions:
        if not isinstance(q,dict) or not isinstance(q.get('question_id'),str) or q['question_id'] in ids or not isinstance(q.get('revision'),dict) or not q['revision'].get('sha256'):
            raise RuntimeError('candidate public question binding is invalid')
        ids.add(q['question_id'])
    return quiz

def require_aliases(base, aliases):
    for old,target in aliases.items():
        quiz=catalog_for(base,old).get('quiz',{})
        if quiz.get('quiz_id')!=target: raise RuntimeError('legacy alias does not resolve to its reviewed target')

def canonical_digest(attempt, snapshot, option_id):
    payload={'attempt_id':attempt['attempt_id'],'participant_id':attempt['participant_id'], 'question_id':snapshot['question_id'], 'question_revision':snapshot['question_revision'], 'answer':{'option_id':option_id}}
    return hashlib.sha256(json.dumps(payload,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def require_attempt_snapshots(base, token, quiz_id, catalog, difficulty):
    attempt=call(base,'/v1/attempts',{'quiz_id':quiz_id,'mode':'practice','difficulty':difficulty},token)
    snaps=attempt.get('question_snapshots'); questions=catalog['quiz']['questions']
    expected={q['question_id']:q['revision'] for q in questions}
    if not attempt.get('attempt_id') or not attempt.get('participant_id') or not isinstance(snaps,list) or len(snaps)!=len(expected): raise RuntimeError('difficulty attempt snapshot count differs')
    seen=set()
    for s in snaps:
        qid=s.get('question_id') if isinstance(s,dict) else None
        if qid not in expected or qid in seen or s.get('question_revision')!=expected[qid]: raise RuntimeError('difficulty attempt snapshot binding differs')
        seen.add(qid)
    if seen!=set(expected): raise RuntimeError('difficulty attempt snapshots are incomplete')

def require_difficulties(base, rows):
    guest=call(base,'/v1/guests',{'display_name':'release70-minimum20'})
    token=guest.get('token')
    if not isinstance(token,str) or not token: raise RuntimeError('candidate guest is invalid')
    started=short=0
    for row in rows:
        for band in BANDS:
            count=row['difficulty_counts'][band]
            query='/v1/catalog?'+urllib.parse.urlencode({'quiz_id':row['quiz_id'],'difficulty':band})
            body={'quiz_id':row['quiz_id'],'mode':'practice','difficulty':band}
            if count>=20:
                selected=call(base,query); require_public_dto(selected)
                if len(selected.get('quiz',{}).get('questions',[]))!=count: raise RuntimeError('difficulty catalog silently changes selection')
                require_attempt_snapshots(base,token,row['quiz_id'],selected,band); started+=1
            else:
                if http_status(base,query)==200 or http_status(base,'/v1/attempts',body,token) in (200,201): raise RuntimeError('short difficulty band silently falls back')
                short+=1
    return {'eligible_started':started,'short_bands_rejected':short}

def source_questions(private_root, pool_evidence):
    """Return accepted source questions for the 23 merged banks.

    The evidence records raw paths, so a candidate must provide the complete
    private quiz tree; no correct answer is inferred from the public DTO.
    """
    evidence=json.loads(pool_evidence.read_text(encoding='utf-8')); targets=evidence.get('targets')
    if not isinstance(targets,list) or len(targets)!=23: raise RuntimeError('pool evidence must list 23 merged banks')
    result={}
    for target in targets:
        qid=target.get('quiz_id'); raw=target.get('raw')
        path=private_root/raw if isinstance(raw,str) else None
        if not isinstance(qid,str) or path is None or not path.is_file(): raise RuntimeError('complete private quiz tree is required')
        data=json.loads(path.read_text(encoding='utf-8')); qs=data.get('questions') if isinstance(data,dict) else None
        if not isinstance(qs,list) or len(qs)!=target.get('questions'): raise RuntimeError('private pooled source differs from reviewed evidence')
        result[qid]=qs
    return result

def map_private_answers(private_questions, public_quiz):
    public={q.get('question_id'):q for q in public_quiz.get('questions',[]) if isinstance(q,dict)}
    by_stem={q.get('stem'):q for q in public.values()}
    if len(by_stem)!=len(public): raise RuntimeError('public whole-bank stems are not unique')
    mapped={}
    for source in private_questions:
        qid=source.get('id') if isinstance(source,dict) else None; options=source.get('options') if isinstance(source,dict) else None; answer=source.get('correct_answer') if isinstance(source,dict) else None
        q=by_stem.get(source.get('text'))
        public_id=q.get('question_id') if isinstance(q,dict) else None
        if not isinstance(qid,str) or not isinstance(public_id,str) or public_id in mapped or not isinstance(options,list) or type(answer) is not int or answer<0 or answer>=len(options) or not isinstance(q,dict) or q.get('stem')!=source.get('text'):
            raise RuntimeError('private/public whole-bank mapping is invalid')
        option_ids={o.get('text'):o.get('option_id') for o in q.get('options',[]) if isinstance(o,dict)}
        if set(option_ids)!=set(options) or not isinstance(option_ids.get(options[answer]),str): raise RuntimeError('private/public option mapping is invalid')
        mapped[public_id]=option_ids[options[answer]]
    if set(mapped)!=set(public): raise RuntimeError('private/public question mapping is incomplete')
    return mapped

def require_receipt_and_history(base, token, quiz_id, public_quiz, answers, label):
    """Grade supplied private keys without ever emitting them.

    A correct full-bank run proves the authoritative score and a separate
    deliberately wrong first answer proves the negative path, receipts, and
    persisted finish history.
    """
    expected={q['question_id']:q['revision'] for q in public_quiz['questions']}
    for wrong in (False, True):
        attempt=call(base,'/v1/attempts',{'quiz_id':quiz_id,'mode':'practice'},token)
        snapshots={s.get('question_id'):s for s in attempt.get('question_snapshots',[]) if isinstance(s,dict)}
        if set(snapshots)!=set(expected) or any(s.get('question_revision')!=expected[qid] for qid,s in snapshots.items()):
            raise RuntimeError('grading attempt does not retain pinned snapshots')
        selected=list(answers)
        for index,qid in enumerate(selected):
            option=answers[qid]
            if wrong:
                options={o.get('option_id') for q in public_quiz['questions'] if q['question_id']==qid for o in q.get('options',[]) if isinstance(o,dict)}
                option=next((candidate for candidate in options if candidate!=option),None)
                if not isinstance(option,str): raise RuntimeError('wrong-answer fixture has no alternate public option')
            snap=snapshots[qid]; digest=canonical_digest(attempt,snap,option)
            receipt=call(base,f"/v1/attempts/{attempt['attempt_id']}/answers",{'question_id':qid,'question_revision':snap['question_revision'],'answer':{'option_id':option},'idempotency_key':f'release70-{label}-{int(wrong)}-{index}','payload_digest':digest},token)
            require_public_dto(receipt)
            if receipt.get('attempt_id')!=attempt['attempt_id'] or receipt.get('participant_id')!=attempt['participant_id'] or receipt.get('question_id')!=qid or receipt.get('question_revision')!=snap['question_revision'] or not receipt.get('receipt_id'):
                raise RuntimeError('answer receipt differs from pinned attempt')
        finish=call(base,f"/v1/attempts/{attempt['attempt_id']}/finish",{},token); history=finish.get('history')
        score=0 if wrong else len(answers)
        if finish.get('server_score')!=score or not isinstance(history,list) or len(history)!=len(selected): raise RuntimeError('authoritative grading or history differs')
        for entry in history:
            qid=entry.get('question_id') if isinstance(entry,dict) else None
            if qid not in selected or entry.get('question_revision')!=expected[qid] or not entry.get('receipt_id'):
                raise RuntimeError('finish history differs from submitted receipt')

def require_private_grading(base, private_root, public):
    guest=call(base,'/v1/guests',{'display_name':'release70-private-grading'}); token=guest.get('token')
    if not isinstance(token,str) or not token: raise RuntimeError('private grading guest is invalid')
    evidence=private_root/'quizzes/Preparation/prep_books_modern.json'
    if not evidence.is_file(): raise RuntimeError('private full quiz tree lacks the books-42 source')
    books=json.loads(evidence.read_text(encoding='utf-8'))
    if books.get('id')!='preparation-books-modern' or len(books.get('questions',[]))!=42 or 'preparation-books-modern' not in public:
        raise RuntimeError('books-42 source contract differs')
    require_receipt_and_history(base,token,'preparation-books-modern',public['preparation-books-modern'],map_private_answers(books['questions'],public['preparation-books-modern']),'books42')

def normalized_sha256(data):
    return hashlib.sha256(data.replace(b'\r\n',b'\n').replace(b'\r',b'\n')).hexdigest()

def new_question_manifest(private_root):
    """Derive, rather than hand-copy, the 38 accepted imported question IDs."""
    task=Path(__file__).parent; manifest={}
    for evidence_name in ('import20-evidence.json','import18-evidence.json'):
        evidence=json.loads((task/evidence_name).read_text(encoding='utf-8'))
        for name,record in evidence['packs'].items():
            source=private_root/record['source']; raw=source.read_bytes()
            if normalized_sha256(raw)!=record['canonical']['source_sha256']:
                raise RuntimeError('accepted import source SHA differs')
            source_doc=json.loads(raw); question_ids=set(record['canonical']['private_grading_verified_for_new_ids'])
            draft_name={'planets':'feedback43-planets-extra-20261019.json','games':'feedback43-games-extra-20261019.json','harry_potter':'feedback43-harrypotter-extra-20261019.json','cats':'feedback43-animal-extras-20261019.json','dogs':'feedback43-animal-extras-20261019.json'}[name]
            draft=private_root/'study/drafts'/draft_name
            if normalized_sha256(draft.read_bytes())!=record['accepted_draft_sha256']:
                raise RuntimeError('accepted import draft SHA differs')
            accepted={'planets':'planets-acceptance.json','games':'games-acceptance.json','harry_potter':'harrypotter-acceptance.json','cats':'animal-extras-acceptance.json','dogs':'animal-extras-acceptance.json'}[name]
            receipt=json.loads((task/accepted).read_text(encoding='utf-8'))
            if receipt.get('decision')!='ACCEPT EXACTDRAFT' or receipt.get('draft_sha256')!=record['accepted_draft_sha256']:
                raise RuntimeError('accepted import receipt differs')
            actual={q.get('id') for q in source_doc.get('questions',[]) if isinstance(q,dict)}
            if not question_ids <= actual: raise RuntimeError('accepted imported IDs are absent from private source')
            quiz_id=source_doc.get('id')
            if not isinstance(quiz_id,str): raise RuntimeError('accepted imported source has no quiz ID')
            manifest[quiz_id]=(source_doc,question_ids)
    if sum(len(ids) for _,ids in manifest.values())!=38: raise RuntimeError('accepted import manifest must contain exactly 38 questions')
    return manifest

def require_new_question_grading(base, private_root, public):
    guest=call(base,'/v1/guests',{'display_name':'release70-new-question-grading'}); token=guest.get('token')
    if not isinstance(token,str) or not token: raise RuntimeError('new-question grading guest is invalid')
    manifest=new_question_manifest(private_root)
    for quiz_id,(source_doc,ids) in manifest.items():
        public_id=quiz_id if quiz_id in public else quiz_id.replace('_','-')
        if public_id not in public: raise RuntimeError('accepted imported quiz is absent from visible catalog')
        answers=map_private_answers(source_doc['questions'],public[public_id])
        selected={qid:answers[qid] for qid in ids}
        # The generic receipt checker intentionally accepts a subset: it proves
        # every imported ID's correct and wrong grading without grading keys
        # being taken from the public DTO.
        require_receipt_and_history(base,token,public_id,public[public_id],selected,'new-'+public_id)
    return sum(len(ids) for _,ids in manifest.values())

def require_article_bindings(web_root, base):
    refs=[]
    for path in web_root.rglob('*.json'):
        try: value=json.loads(path.read_text(encoding='utf-8'))
        except json.JSONDecodeError: continue
        rows=value.get('articles',[]) if isinstance(value,dict) else value
        if isinstance(rows,list): refs += [ref for row in rows if isinstance(row,dict) for ref in row.get('question_refs',[]) if isinstance(ref,dict)]
    if len(refs)!=241: raise RuntimeError('candidate must contain exactly 241 article references')
    cached={}; source_cached={}; fallbacks=set()
    for ref in refs:
        quiz,qid,sha=ref.get('quiz_id'),ref.get('question_id'),ref.get('revision_sha256')
        if (quiz,qid) in NONCATALOG_READER_REFS:
            if sha!=NONCATALOG_READER_REFS[(quiz,qid)]: raise RuntimeError('pinned noncatalog reference differs')
            continue
        if not all(isinstance(v,str) and v for v in (quiz,qid,sha)): raise RuntimeError('article reference is incomplete')
        if quiz not in cached:
            try: cached[quiz]={q['question_id']:q['revision']['sha256'] for q in catalog_for(base,quiz)['quiz']['questions']}
            except RuntimeError: cached[quiz]={}
        if cached[quiz].get(qid)==sha: continue
        # A legacy alias can return its playable derived pool successfully while
        # its historical article still names a source revision.  That is a
        # hash mismatch, not permission to accept a stale playable response.
        if quiz not in source_cached:
            source_cached[quiz]={q['question_id']:q['revision']['sha256'] for q in call(base,'/v1/source-catalog?quiz_id='+urllib.parse.quote(quiz))['quiz']['questions']}
        if source_cached[quiz].get(qid)!=sha: raise RuntimeError('article reference differs from exact candidate revision')
        fallbacks.add(quiz)
    return {'article_refs':len(refs),'archival_fallback_quizzes':len(fallbacks)}

def main():
 p=argparse.ArgumentParser(); p.add_argument('--base-url',required=True); p.add_argument('--catalog-json',type=Path,required=True); p.add_argument('--pool-evidence',type=Path,required=True); p.add_argument('--private-quizzes-root',type=Path,required=True); p.add_argument('--web-root',type=Path); p.add_argument('--skip-article-verification',action='store_true'); p.add_argument('--require-real-http-grading',action='store_true'); p.add_argument('--require-article-revision-binding',action='store_true'); a=p.parse_args()
 if not(a.require_real_http_grading and a.require_article_revision_binding): raise SystemExit('both release rehearsal gates are required')
 base=a.base_url.rstrip('/'); rows=load_catalog(a.catalog_json); aliases=load_aliases(a.pool_evidence)
 public={row['quiz_id']: require_catalog_match(row,catalog_for(base,row['quiz_id'])) for row in rows}; require_aliases(base,aliases)
 private=source_questions(a.private_quizzes_root,a.pool_evidence)
 for quiz_id,questions in private.items():
  map_private_answers(questions,public[quiz_id])
 new_questions=require_new_question_grading(base,a.private_quizzes_root,public)
 require_private_grading(base,a.private_quizzes_root,public)
 grading_guest=call(base,'/v1/guests',{'display_name':'release70-pooled-grading'}); grading_token=grading_guest.get('token')
 if not isinstance(grading_token,str) or not grading_token: raise RuntimeError('pooled grading guest is invalid')
 for quiz_id in (sorted(private)[0],sorted(private)[-1]):
  require_receipt_and_history(base,grading_token,quiz_id,public[quiz_id],map_private_answers(private[quiz_id],public[quiz_id]),'pooled-'+quiz_id)
 difficulty=require_difficulties(base,rows)
 if a.skip_article_verification:
  articles={'article_verification':'skipped_local_no_candidate_web'}
 elif a.web_root:
  articles=require_article_bindings(a.web_root,base)
 else:
  raise RuntimeError('candidate web root is required unless article verification is explicitly skipped')
 print(json.dumps({'visible_banks':105,'visible_slots':4520,'aliases':56,'private_pooled_banks':len(private),'new_questions_graded':new_questions,**difficulty,**articles}))
if __name__=='__main__': main()
