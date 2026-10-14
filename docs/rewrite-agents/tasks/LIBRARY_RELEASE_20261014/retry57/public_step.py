from pathlib import Path
import subprocess,json,datetime,sys
r=Path('C:/ap/quiz_master');pack=sys.argv[1];name=sys.argv[2];assert pack in ['lotr','mixed'];assert name.replace('-','').isalnum();args=sys.argv[3:];script=args[1] if args and args[0]=='eval' else None; actual_args=['eval','--stdin'] if script is not None else args;d=r/'docs/rewrite-agents/tasks/LIBRARY_RELEASE_20261014/published-browser'/pack;d.mkdir(exist_ok=True)
raw=d/(name+'-raw.txt')
with raw.open('w',encoding='utf8') as stream:
 p=subprocess.Popen(['agent-browser.cmd','--session','library-09b19cc-public58-'+pack,'--namespace','quiz-master',*actual_args],stdin=subprocess.PIPE if script is not None else None,stdout=stream,stderr=subprocess.STDOUT,cwd=r)
 if script is not None:p.stdin.write(script.encode('utf8'));p.stdin.close()
 try:code=p.wait(timeout=30)
 except subprocess.TimeoutExpired:p.kill();code=p.wait(timeout=5)
text=raw.read_text(encoding='utf8',errors='replace')
x={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':args,'actual_exit':code,'stdout':text,'stderr':''};(d/(name+'.json')).write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf8');print(json.dumps(x,ensure_ascii=False));raise SystemExit(code)
