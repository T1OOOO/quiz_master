from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4]
here=Path(__file__).resolve().parent
report=json.loads((here/'triage.json').read_text(encoding='utf-8'))
assert len(report['source_sha256'])==report['packs']==131
packs={p:json.loads((root/p).read_text(encoding='utf-8-sig')) for p in report['source_sha256']}
assert sum(len(p['questions']) for p in packs.values())==report['questions']==4008
assert all(hashlib.sha256((root/p).read_bytes()).hexdigest()==h for p,h in report['source_sha256'].items())
errors=[];flags=0
for path,pack in packs.items():
 for q in pack['questions']:
  opts=q['options'];key=q['correct_answer']
  assert isinstance(key,int) and not isinstance(key,bool) and 0<=key<len(opts)
  if len({o.strip().casefold() for o in opts})!=len(opts):errors.append(q['id'])
  a=opts[key];other=[len(o) for i,o in enumerate(opts) if i!=key]
  if ('(' in a and sum('(' in o for o in opts)==1) or (other and len(a)>=35 and len(a)>max(other)*1.8):flags+=1
assert sorted(errors)==sorted(e['question_id'] for e in report['structural_errors'])
assert flags==len(report['heuristic_flags'])==666
for repair in json.loads((here/'proposed-duplicate-repair.json').read_text(encoding='utf-8')):
 old=repair['before'];new=repair['proposed']
 assert new['options'][new['correct_answer']]==old['options'][old['correct_answer']]
 assert len(set(new['options']))==len(new['options'])
 assert all(new[k]==old[k] for k in old if k not in ['options','correct_answer'])
print('PASS:131 packs/4008 questions;666 heuristic flags;3 duplicate-label records; draft repairs retain key meaning. No runtime edits or factual verification.')

public=json.loads((here/'production-duplicates.json').read_text(encoding='utf-8'))['questions']
normalized={k.replace(chr(92),'/'):v for k,v in packs.items()}
assert len(public)==len(report['structural_errors'])==3
for e,live in zip(report['structural_errors'],public):
 q=normalized[e['path']]['questions'][e['index']]
 assert live['source']['uri']=='/app/'+e['path']
 assert live['question_id']==q['id'].replace('_','-')
 assert live['stem']==q['text'] and [o['text'] for o in live['options']]==q['options']
print('PASS:3 exact source/public URI, ID, stem and option crosswalks.')
