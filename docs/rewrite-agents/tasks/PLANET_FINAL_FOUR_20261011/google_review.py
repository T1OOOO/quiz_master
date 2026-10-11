from pathlib import Path
import json,hashlib,subprocess,os,re
r=Path('C:/ap/quiz_master'); d=r/'.run/planet_final_four_20261011'
draft=json.loads((r/'study/question_articles/drafts/planet-final-four-20261011.json').read_text(encoding='utf-8-sig'))
assert len(draft['articles'])==4
hashes={a['id']:hashlib.sha256(json.dumps(a,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest() for a in draft['articles']}
prompt='You are an independent factual and editorial reviewer. Read-only, no tools. Supplied sources were actually opened by native writer/checker; do not pretend you fetched them. Check every factual claim and meaningful teaching quality in four Russian astronomy miniarticles, exact question revision bindings, source relevance, ambiguity, hypothesis qualifiers, Venus solar vs sidereal time, gas giant pressure/phase/core distinctions and Triton orbit vs axial rotation. No generic quiz-option/source-verification meta prose. Return ONLY JSON: verdict accept/revise; articles array of article_id, article_sha256 from supplied map, verdict, findings; limitations. Accept only supported factual claims and clear useful 150–210word articles. Do not grant publication or claim runtime checks.\nHASHES '+json.dumps(hashes)+'\nDRAFT '+json.dumps(draft,ensure_ascii=False)+'\nSOURCE EVIDENCE\n'+(d/'source-evidence.json').read_text(encoding='utf-8-sig')+'\nNATIVE FACT REVIEW\n'+(r/'study/question_articles/reviews/planet-final-four-20261011-review.json').read_text(encoding='utf-8-sig')
with (d/'google.jsonl').open('w',encoding='utf-8') as f:
    p=subprocess.run(['agy','--input-format','stream-json','--output-format','stream-json','--mode','plan','--sandbox','--model','gemini-3.8-flash-medium'],input=json.dumps({'event':'user','message':{'content':prompt}})+'\n',encoding='utf-8',stdout=f,stderr=subprocess.PIPE,env=dict(os.environ,AGENT_HUB_NO_MCP='1'),cwd=r,timeout=180)
assert p.returncode==0,p.stderr[-1000:]
events=[json.loads(s) for s in (d/'google.jsonl').read_text().splitlines() if s.startswith('{')]
final=next(x for x in reversed(events) if x.get('event')=='result'); (d/'google.result.json').write_text(json.dumps(final,indent=2),encoding='utf-8')
response=re.sub(r'^```(?:json)?\s*|\s*```$','',final['result']['response'].strip()); verdict=json.loads(response)
print(json.dumps(verdict,ensure_ascii=False,indent=2))
assert verdict['verdict']=='accept'
assert {a['article_id']:a['article_sha256'] for a in verdict['articles']}==hashes
assert all(a['verdict']=='accept' for a in verdict['articles'])
