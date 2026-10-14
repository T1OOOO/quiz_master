from pathlib import Path
import subprocess,json,hashlib,sys,importlib.util
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_RELEASE_20261014';e=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014';w=Path(__file__).parent
sys.path.insert(0,str(d/'worker-resumed'));import prepare_remote as remote
remote.initialize(d);package,stage=remote.reviewed_package(d);guard,script=remote.remote_scripts(package)
target='/opt/quiz-master/releases/'+remote.BUILD_ID+'.tar.gz';key=remote.KEY;host=remote.TARGET
inspect=guard.replace('test ! -e '+target+'\n','test -f '+target+'\n')+f'''test "$(readlink -f {target})" = {target}
python3 - <<'PY'
from pathlib import Path
import hashlib,json
p=Path('{target}');assert not p.is_symlink()
print(json.dumps({{'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}}))
PY
'''
p=subprocess.run(['ssh','-i',key,host,'bash -s'],input=inspect.encode(),capture_output=True,timeout=40);assert p.returncode==0,p.stdout.decode(errors='replace')
partial=json.loads(p.stdout);local=Path(package['archive']);assert 0<=partial['size']<=local.stat().st_size
with local.open('rb') as f:assert hashlib.sha256(f.read(partial['size'])).hexdigest()==partial['sha256'],'Own interrupted transfer prefix differs; stop rather than overwrite'
record={'original_scp_exit':'timeout90s','cutover_started_by_failed_wrapper':False,'own_partial_prefix_verified':partial,'local_size':local.stat().st_size,'scope':'Resume only this exact reviewed own candidate archive with official SFTP reput; unchanged reviewed prepare script after full digest verification.'}
(e/'interrupted-transfer.json').write_text(json.dumps(record,indent=2)+'\n')
if partial['sha256']!=package['archive_sha256']:
 batch=w/'resume-own-transfer.sftp';batch.write_text('reput "'+local.as_posix()+'" "'+target+'"\n',encoding='utf8')
 p=subprocess.run(['sftp','-i',key,'-b',str(batch),host],capture_output=True,text=True,timeout=180);record['resume_actual_exit']=p.returncode;record['resume_stdout']=p.stdout;record['resume_stderr']=p.stderr
 (e/'interrupted-transfer.json').write_text(json.dumps(record,indent=2)+'\n');assert p.returncode==0,record
assert hashlib.sha256(script.encode()).hexdigest()=='733706cf1928deeed64e88e2c284bb7c563ec9926380c440de759a0687a11e05'
(d/'remote-prepare-script.sh').write_bytes(script.encode())
p=subprocess.run(['ssh','-i',key,host,'bash -s'],input=script.encode(),capture_output=True,timeout=600)
(d/'remote-prepare-log.txt').write_bytes(p.stdout+p.stderr);(d/'remote-prepare-exit.json').write_text(json.dumps({'actual_exit':p.returncode,'scope':'Unchanged reviewed prepare script after verified official SFTP resume; original SCP timeout preserved.'})+'\n')
print((p.stdout+p.stderr).decode(errors='replace')[-3500:]);assert p.returncode==0,'Preparation failed; preserve artifacts, never publish'
