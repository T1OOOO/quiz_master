from pathlib import Path
import json,hashlib,re
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/HOME_ALONE_ARTICLES_20261013'
raw=(d/'writer-v1.json').read_bytes();x=json.loads(raw);assert x['status']=='DRAFT_REQUIRES_INDEPENDENT_REVIEW'
rows=x['articles'];assert len(rows)==2
questions=json.loads((d/'candidate-input.json').read_text())['questions'];expected={q['question_id']:q for q in questions}
existing=json.loads((r/'next/apps/quiz_app/assets/study/question-articles.json').read_text())['articles'];assert len(existing)==242
ids={a['id'] for a in existing};refs={(q['quiz_id'],q['question_id']) for a in existing for q in a['question_refs']}
proof=[];seen=set()
for a in rows:
 assert a['status']=='draft' and a['id'] not in ids and a['id'] not in seen;seen.add(a['id'])
 assert len(a['question_refs'])==1;ref=a['question_refs'][0];q=expected[ref['question_id']]
 assert ref=={'quiz_id':q['quiz_id'],'question_id':q['question_id'],'revision_sha256':q['revision']['sha256']}
 assert (ref['quiz_id'],ref['question_id']) not in refs
 assert a['id']=='question:'+ref['question_id'] and a['target_refs']==[] and a['tag_ids']==[]
 assert isinstance(a['title_ru'],str) and a['title_ru'].strip()
 count=len(re.findall(r'\b[\w]+(?:[-’][\w]+)*\b',a['body_ru'],re.UNICODE));assert 140<=count<=210,(a['id'],count)
 links=a['source_links'];assert len(links)>=2 and len({s['url'] for s in links})==len(links)
 for s in links:
  assert s['url'].startswith('https://') and s['title'].strip() and s['supports'].strip() and s['accessed']=='2026-10-13'
 proof.append({'id':a['id'],'question_id':ref['question_id'],'revision_sha256':ref['revision_sha256'],'word_count':count,'source_count':len(links)})
assert {p['question_id'] for p in proof}==set(expected)
result={'input_sha256':hashlib.sha256(raw).hexdigest(),'records':proof,'existing_reader_count_unchanged':242,'limits':['Structural gate only, not factual or binding/export/runtime acceptance','References are exact published runtime hashes, not obsolete Git canonical hashes']}
(d/'structural-v1.json').write_bytes(json.dumps(result,indent=2).encode()+b'\n');print(json.dumps(result))
