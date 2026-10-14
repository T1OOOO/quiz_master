from pathlib import Path
import json,hashlib,re,subprocess,runpy,sys
r=Path('C:/ap/quiz_master');w=Path(__file__).parent;d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_RELEASE_20261014';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert json.loads((d/'remote-prepare-exit.json').read_text())['actual_exit']==0
m=json.loads((d/'package-current.json').read_text());log=(d/'remote-prepare-log.txt').read_text();b=m['metadata']['buildId'];match=re.search(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare',log);assert match and match[1]==b
durable='/var/lib/rancher/k3s/agent/images/'+b+'.tar';found=re.search(r'([a-f0-9]{64})  '+re.escape(durable),log);assert found
run=match[3].removesuffix('-values.yaml');assert re.fullmatch(re.escape(b)+r'-cutover-\d{8}T\d{6}Z',run)
remote=f'''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import pathlib,json,hashlib,sqlite3,stat,shutil,datetime
root=pathlib.Path('/opt/quiz-master/releases/{b}');run='{run}';backup=pathlib.Path('/opt/quiz-master/backups')/(run+'.sqlite')
def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
reh=root/(run+'-rehearsal.json');a=json.loads(reh.read_text());assert a['migration']=='ok' and a['original_rows_preserved'] and a['integrity']=='ok' and a['feedback_lifecycle']=='ok' and a['old_api_rollback']=='ok'
assert a['post_migration_counts'][3]-a['original_counts'][3]==135
assert a['canonical_packs']==12 and a['canonical_questions']==160 and a['total_graded']==215 and a['practice_finished']==13
c=sqlite3.connect('file:'+str(backup)+'?mode=ro',uri=True);assert c.execute('pragma integrity_check').fetchone()[0]=='ok';assert stat.S_IMODE(backup.stat().st_mode)==0o600
db=root/('rehearsal-'+run)/'quiz.sqlite';c=sqlite3.connect('file:'+str(db)+'?mode=ro',uri=True);practice=c.execute('select count(*),sum(server_score) from attempts where participant_id in (select id from participants where display_name="Release rehearsal") and status="finished"').fetchone();assert practice[0]==13 and practice[1]==215
out={{'backup_path':str(backup),'backup_sha256':h(backup),'backup_mode':'0600','backup_integrity':'ok','copied_db_rehearsal':a,'copied_db_rehearsal_sha256':h(reh),'copy_rehearsal_finished_trials':practice[0],'copy_rehearsal_score_sum':practice[1],'helm_dryrun_sha256':h(root/(run+'-rendered.yaml')),'durable_archive_sha256':h(pathlib.Path('{durable}')),'disk_free_bytes':shutil.disk_usage('/opt/quiz-master').free,'checked_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}}
assert out['disk_free_bytes']>4000000000
print(json.dumps(out))
PY
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{{.spec.template.spec.containers[0].image}}')" = docker.io/library/quiz-master@sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961
'''
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -s'],input=remote.encode(),stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=60);assert p.returncode==0,p.stdout.decode();a=json.loads(p.stdout);assert a['durable_archive_sha256']==found[1]
(d/'remote-preparation-verification.json').write_bytes(json.dumps(a,indent=2).encode()+b'\n')
e={'build_id':b,'source_commit':m['metadata']['commit'],'package_sha256':m['archive_sha256'],'image':match[2],'values':match[3],'remote_prepare_exit':0,'remote_log':'remote-prepare-log.txt','remote_log_sha256':sha(d/'remote-prepare-log.txt'),'durable_archive':durable,'durable_archive_sha256':found[1],'backup_sha256':a['backup_sha256'],'copied_db_rehearsal_sha256':a['copied_db_rehearsal_sha256'],'df_sha256':hashlib.sha256(json.dumps({'disk_free_bytes':a['disk_free_bytes'],'checked_utc':a['checked_utc']},sort_keys=True).encode()).hexdigest(),'helm_dryrun_sha256':a['helm_dryrun_sha256'],'local_browser_evidence_sha256':sha(d/'browser-proof.json'),'publisher_controller_sha256':sha(d/'worker-resumed/publish_prepared.py'),'prepare_controller_sha256':sha(d/'worker-resumed/prepare_remote.py'),'actual_copy_rehearsal':{'canonical_packs':12,'canonical_questions':160,'newyear_questions':55,'total_graded':215,'practice_finished':13,'old_rows_preserved':True,'feedback_lifecycle_copy_only':'PASS','old_api_rollback':'PASS'},'limits':['Only preparation executed; publication and public verification remain separate.','No all-bank factual/Android certification or real feedback closure.']}
stage=Path(m['stage']);sys.path.insert(0,str(d/'worker-resumed'));import prepare_remote;prepare_remote.initialize(d);pub=runpy.run_path(str(d/'worker-resumed/publish_prepared.py'));prefix=(stage/'cutover.sh').read_text().split('quiz_image="quiz-master:$quiz_build"')[0];shell=pub['publish_script'](m,e,stage,prefix,verify_hash=False);assert 'docker build' not in shell
e['publish_script_sha256']=hashlib.sha256(shell.encode()).hexdigest();(d/'publish-prepared-preview.sh').write_bytes(shell.encode());(d/'execution-packet.json').write_bytes(json.dumps(e,indent=2).encode()+b'\n')
subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','bash -n'],input=shell.encode(),check=True,timeout=30)
print(json.dumps(e))
