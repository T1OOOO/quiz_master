from pathlib import Path
import json,hashlib,subprocess,importlib.util,copy
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/HOME_ALONE_BINDING_20261013';w=r/'.run/home_alone_binding_20261013';script=d/'prepare_reader.py';output=w/'reader244-v1.json';exe='C:/Users/Alexey_Matvienko/tools/agent-hub/.venv/Scripts/python.exe'
assert not output.exists();cases=[]
def run(label,args,expected,absent=None):
 p=subprocess.run([exe,str(script),*args],cwd=r,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
 assert (p.returncode==0)==expected,(label,p.stdout.decode(errors='replace'))
 if absent:assert not absent.exists()
 (w/(label+'.log')).write_bytes(p.stdout);cases.append({'case':label,'actual_exit':p.returncode,'output':p.stdout.decode(errors='replace')[-700:]})
run('reader-dry-run',['--output',str(output),'--dry-run'],True,output)
run('reader-positive',['--output',str(output)],True)
raw=output.read_bytes();x=json.loads(raw);baseline=json.loads((r/'next/apps/quiz_app/assets/study/question-articles.json').read_text());draft=json.loads((r/'docs/rewrite-agents/tasks/HOME_ALONE_ARTICLES_20261013/writer-v3.json').read_text());assert x['articles'][:242]==baseline['articles'] and len(x['articles'])==244
for actual,src in zip(x['articles'][242:],draft['articles']):assert actual==dict(src,status='accepted')
run('reader-overwrite',['--output',str(output)],False);assert output.read_bytes()==raw
wrong=w/'old-git-ref-output.json';run('reader-old-git-bundle',['--output',str(wrong),'--published-bundle',str(r/'next/content/home-alone-1-part-1/bundle.json')],False,wrong)
spec=importlib.util.spec_from_file_location('reader',script);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
y=copy.deepcopy(x);y['articles'][-1]['id']=y['articles'][-2]['id']
try:m.validate_output_schema(y);raise AssertionError('Duplicate accepted')
except ValueError as e:cases.append({'case':'duplicate-article-validator','rejected':True,'reason':str(e)})
y=copy.deepcopy(x);y['articles'][-1]['question_refs']=y['articles'][-2]['question_refs']
try:m.validate_output_schema(y);raise AssertionError('Duplicate ref accepted')
except ValueError as e:cases.append({'case':'duplicate-question-ref-validator','rejected':True,'reason':str(e)})
p={'producer_sha256':hashlib.sha256(script.read_bytes()).hexdigest(),'output_sha256':hashlib.sha256(raw).hexdigest(),'prior242_preserved':True,'new_rows_only_status_changed':True,'counts':244,'cases':cases,'limits':['Non-runtime generated Reader fixture, no app asset import/build/browser/DB/image/publication gate','Old original task state not rewritten; exact V3 independent source acceptance separately retained']}
(d/'reader-root-proof.json').write_bytes(json.dumps(p,ensure_ascii=False,indent=2).encode()+b'\n');print(json.dumps(p,ensure_ascii=False))
