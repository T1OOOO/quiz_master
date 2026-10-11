"""Finish the real published browser attempt using observed accessibility refs."""
from pathlib import Path
import json,re,subprocess,time
d=Path('.run/planet_release_20261011');m=json.loads((d/'package.json').read_text());b=json.loads((Path(m['stage'])/'next/content/planet-paradoxes-20261010/bundle.json').read_text());session='quiz-planet-published-d228c9e'
def command(*args):return subprocess.check_output(['node','C:/Users/Alexey_Matvienko/AppData/Roaming/npm/node_modules/agent-browser/bin/agent-browser.js','--session',session,*args],text=True,encoding='utf-8')
evidence=[]
for q in b['quiz']['questions']:
 answer=b['private_grading'][q['question_id']]['correct_option_id'];deadline=time.monotonic()+20
 while True:
  snapshot=command('snapshot','-i');lines=[s for s in snapshot.splitlines() if answer in s and '[disabled' not in s]
  if lines:break
  assert time.monotonic()<deadline,'Expected question not available: '+q['question_id'];time.sleep(.3)
 assert len(lines)==1;ref=re.search(r'\[ref=(e\d+)\]',lines[0]).group(1)
 command('click','@'+ref);evidence.append({'question_id':q['question_id'],'observed_ref':ref,'choice':answer})
snapshot=command('snapshot','-i')
finish=[line for line in snapshot.splitlines() if 'Завершить викторину' in line]
assert len(finish)==1
command('click','@'+re.search(r'\[ref=(e\d+)\]',finish[0]).group(1))
deadline=time.monotonic()+20
while True:
 result=command('snapshot','-c')
 if 'Счёт: 10' in result:break
 assert time.monotonic()<deadline,'Finished score not visible';time.sleep(.3)
(d/'browser-answers.json').write_text(json.dumps({'scope':'Actual published UI, new full attempt after stale EXE version mismatch; official installed Node CLI entry used consistently','answers':evidence,'result_snapshot':result},ensure_ascii=False,indent=2));print(result)
