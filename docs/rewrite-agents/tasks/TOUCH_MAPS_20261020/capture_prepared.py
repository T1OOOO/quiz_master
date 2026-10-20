import subprocess,json,hashlib
from pathlib import Path
r=Path('E:/Projects/quiz_master');o=r/'.run/touch_maps_20261020';d=r/'docs/rewrite-agents/tasks/TOUCH_MAPS_20261020'
code=r'''import subprocess,json,hashlib,os,socket,sqlite3
from pathlib import Path
run=lambda *a:subprocess.check_output(a,text=True)
assert socket.gethostname()=='racknerd-f0269d5'
build='quiz-2026.10.20-touch-b5863403';stage=Path('/opt/quiz-master/releases')/build
receipt=json.loads((stage/'prepared-receipt.json').read_text());assert receipt['build_id']==build
manifest=(stage/'release-inputs.json').read_bytes();assert receipt['input_sha256']==hashlib.sha256(manifest).hexdigest();m=json.loads(manifest)
dep=json.loads(run('kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'));assert dep['metadata']['annotations']['deployment.kubernetes.io/revision']=='73'
h=json.loads(run('helm','history','quiz-master','-n','quiz-master','-o','json'));assert str(h[-1]['revision'])=='75'
assert run('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={.metadata.uid}')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
v=json.loads((stage/'web/version.json').read_text());assert v['source_commit']=='b5863403a7ef6b638f2674704dcb39b4c9c0bfad' and v['frontend_only'] is True
api=(stage/'new-api-sha256.txt').read_text().strip();assert api==v['api_sha256']=='e2884077520a274a753cab0eff58c663aed159fd723c24e2b8f1e234c75539e4'
js=run('docker','run','--rm','--network=none','--read-only','--entrypoint','sha256sum','quiz-master:'+build,'/usr/share/nginx/html/main.dart.js').split()[0]
assert js==v['main_dart_js_sha256']==m['web']['main.dart.js']
assert len(m['web'])==574 and len(m['staged_web'])==24
assert m['staged_web']=={p:q for p,q in m['web'].items() if p.endswith('.json')}
cri=json.loads((stage/'canonical-cri.json').read_text());config=cri['status']['id'];engine=json.loads(run('docker','image','inspect','quiz-master:'+build))[0]['Id']
index_digest=receipt['image'].rsplit('@',1)[1];index=json.loads(run('k3s','ctr','-n','k8s.io','content','get',index_digest))
platform=next(x for x in index['manifests'] if x.get('platform',{}).get('os')=='linux' and x.get('platform',{}).get('architecture')=='amd64')
platform_doc=json.loads(run('k3s','ctr','-n','k8s.io','content','get',platform['digest']));assert platform_doc['config']['digest']==config
backup=Path('/opt/quiz-master/backups')/(build+'.sqlite')
c=sqlite3.connect(backup.as_uri()+'?mode=ro&immutable=1',uri=True);assert c.execute('pragma integrity_check').fetchone()[0]=='ok'
restored=sqlite3.connect(':memory:');c.backup(restored);assert restored.execute('pragma integrity_check').fetchone()[0]=='ok';restored.close();c.close()
integrity={'physical_backup':'ok','independent_full_memory_restore':'ok'}
proofs=[json.loads(p.read_text()) for p in stage.glob('sql-proof-prepare-*.json')];assert len(proofs)==2
restore=next(x for x in proofs if x['kind']=='restore');rehearsal=next(x for x in proofs if x['kind']=='rehearsal')
restore_sha=hashlib.sha256(backup.read_bytes()).hexdigest();assert restore['backup_sha256']==restore['restored_sha256']==restore_sha
assert rehearsal['backup_sha256']==restore_sha and rehearsal['integrity']=='ok'
assert rehearsal['http']['visible_banks']==105 and rehearsal['http']['visible_slots']==4520 and rehearsal['http']['article_refs']==241
for x in proofs:assert x['build_id']==build and x['input_sha256']==receipt['input_sha256'] and x['image_docker_id']==engine
check=subprocess.run(['findmnt','--mountpoint',str(stage/'volatile-checks')],capture_output=True);assert check.returncode==1
assert json.loads((stage/'prepare-unmount.json').read_text())['mounted'] is False
node=json.loads(run('kubectl','get','nodes','-o','json'))['items'][0];conditions={c['type']:c['status'] for c in node['status']['conditions']};assert conditions['Ready']=='True' and conditions['DiskPressure']=='False'
s=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
print(json.dumps({'receipt':receipt,'image_descriptor_types':{'index_digest':index_digest,'platform_digest':platform['digest'],'config_digest':config,'docker_inspect_id':engine},'api_sha256':api,'main_dart_js_sha256':js,'source_commit':v['source_commit'],'live_helm_revision':75,'live_deployment_revision':73,'pvc_unchanged':True,'integrity':integrity,'sql_proofs':proofs,'candidate_ram_unmounted':True,'restored_copy_sha256_matches_backup_before_rehearsal':restore_sha,'full_web_files':len(m['web']),'staged_json_files':len(m['staged_web']),'image_web_closure':json.loads((stage/'image-web-closure.json').read_text()),'quiz_source_closure':json.loads((stage/'quiz-source-closure.json').read_text()),'node_conditions':conditions,'imagefs_available_percent':s.f_bavail*100/s.f_blocks,'capacity_meets_20_percent':s.f_bavail*5>=s.f_blocks},indent=2))
'''
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','root@192.3.164.184','python3 -'],input=code.encode(),capture_output=True,timeout=60)
if p.returncode:raise RuntimeError(p.stderr.decode()[-2500:])
x=json.loads(p.stdout);plan=json.loads((o/'release-plan.json').read_text());expected=hashlib.sha256((json.dumps(plan['input_manifest'],sort_keys=True,indent=2)+'\n').encode()).hexdigest();assert x['receipt']['input_sha256']==expected
(d/'prepared-image-evidence.json').write_bytes(p.stdout)
(o/'prepared-receipt.json').write_text(json.dumps(x['receipt'],sort_keys=True),encoding='utf-8')
print(json.dumps(x,indent=2));assert x['capacity_meets_20_percent']
