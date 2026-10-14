from pathlib import Path
import subprocess,json,re,sys,time
r=Path('C:/ap/quiz_master');w=r/'.run/library_release_20261014';pack=sys.argv[1];assert pack in ['lotr','mixed'];d=r/'docs/rewrite-agents/tasks/LIBRARY_RELEASE_20261014/published-browser'/pack;d.mkdir(exist_ok=True);prefix=sys.argv[2];counter=0;logs=[]
bundle=json.loads((w/'qa-lotr-targets-bundle.json' if pack=='lotr' else r/'docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/mixed-runtime-bundle.json').read_bytes());reader=json.loads((r/'next/apps/quiz_app/assets/study/question-articles.json').read_bytes())['articles'];seen=sys.argv[3].split(',') if len(sys.argv)>3 else []
def run(*args):
 global counter
 counter+=1;file=d/f'{prefix}-{counter:03d}.txt';assert not file.exists();a=list(args);script=a[1] if a[0]=='eval' else None;a=['eval','--stdin'] if script is not None else a
 with file.open('w',encoding='utf8') as f:
  p=subprocess.Popen(['agent-browser.cmd','--session','library-09b19cc-public58-'+pack,'--namespace','quiz-master',*a],stdin=subprocess.PIPE if script is not None else None,stdout=f,stderr=subprocess.STDOUT,cwd=r)
  if script is not None:p.stdin.write(script.encode());p.stdin.close()
  code=p.wait(timeout=25)
 text=file.read_text(encoding='utf8',errors='replace');logs.append({'command':list(args),'actual_exit':code,'artifact':str(file.relative_to(r))});(d/(prefix+'-commands.json')).write_text(json.dumps(logs,indent=2)+'\n');assert code==0,text;return text

def buttons(text):return [(label,ref) for label,ref in re.findall(r'button "(.*)" \[ref=(e\d+)\]',text)]
def click_label(text,label):
 matches=[ref for name,ref in buttons(text) if name==label];assert len(matches)==1,(label,buttons(text));run('click','@'+matches[0])
while len(seen)<len(bundle['quiz']['questions']):
 text=run('snapshot');matches=[q for q in bundle['quiz']['questions'] if q['stem'] in text];assert len(matches)==1,text;q=matches[0];assert q['question_id'] not in seen
 correct_id=bundle['private_grading'][q['question_id']]['correct_option_id'];correct_text=next(x['text'] for x in q['options'] if x['option_id']==correct_id)
 run('screenshot',str(d/(prefix+'-'+q['question_id']+'.png')))
 matches=[ref for name,ref in buttons(text) if name==correct_text];assert len(matches)==1
 # Pause in one native browser batch: separate CLI round trips can outlast the 2s timer.
 run('batch','--bail','click @'+matches[0],"wait --text 'Пауза'","find role button click --name 'Пауза'")
 feedback=run('snapshot');assert 'Продолжить автоматически' in feedback,feedback
 if q['question_id'] in {'pub-connections-003','pub-connections-007','pub-connections-008','pub-connections-009','pub-connections-013','pub-connections-017'}:
  click_label(feedback,'Узнать больше');expected=next(a for a in reader if a['id']=='question:'+q['question_id']);run('wait','--text',expected['title_ru']);article=run('snapshot');assert expected['title_ru'] in article,article
  controls=[name for name,ref in buttons(article) if any(s['title'] in name for s in expected['source_links'])];assert len(controls)==len(expected['source_links'])
  nodes=json.loads(json.loads(run('eval','JSON.stringify(Array.from(document.querySelectorAll("*")).filter(e=>e.scrollHeight>e.clientHeight+50&&e.clientHeight>0).map(e=>e.id))')));assert len(nodes)==1,nodes
  run('scroll','down','700','--selector','#'+nodes[0]);run('screenshot',str(d/(prefix+'-article-'+q['question_id']+'-footer.png')));click_label(run('snapshot'),'Закрыть статью');feedback=run('snapshot')
 follow=[name for name,ref in buttons(feedback) if name.startswith('Продолжить') or name.startswith('Следующий')]
 if follow:
  click_label(feedback,follow[0])
  if follow[0]=='Продолжить автоматически':time.sleep(3.5)
 seen.append(q['question_id']);print('UI correct text submitted',q['question_id'],flush=True)
 # If no paused modal remains, let the ordinary timer advance before next UI read.
 if not follow:time.sleep(3)
text=run('snapshot');click_label(text,'Завершить викторину');final=run('snapshot');assert 'Счёт: '+str(len(seen)) in final,final;run('screenshot',str(d/(prefix+'-result.png')));(d/(prefix+'-summary.json')).write_text(json.dumps({'answered_question_ids':seen,'selected_by_correct_text_not_position':True,'expected_score':len(seen),'visible_result_score_confirmed':True,'scope':'Actual native browser UI on compiledfrozenWeb; controlledLOT2/fullmixed20, realGo, not rawimage proof'},indent=2)+'\n');print('Actual visible result',len(seen),'of',len(seen),flush=True)
