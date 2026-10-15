"""Fixed baseline61 preflight shared by this release's generated shell controls."""

def preflight_shell():
    return '''test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request,sqlite3,hashlib
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==61 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:0f24677d8e499df9d21e80ce1dd50b8e830b37608c4c86e1c38e76ccc30d3228'}
assert deploy['status'].get('availableReplicas')==1
pvc=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert pvc['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and pvc['status']['phase']=='Bound'
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items']
assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']}
assert conditions.get('Ready')=='True' and conditions.get('DiskPressure')=='False'
assert not node.get('spec',{}).get('unschedulable',False)
assert not any(t.get('effect') in ('NoSchedule','NoExecute') for t in node.get('spec',{}).get('taints',[]))
usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
assert usage.f_bavail*usage.f_frsize*5>usage.f_blocks*usage.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response: assert response.status==200
db_path='file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro'
with sqlite3.connect(db_path,uri=True) as db:
 rows=db.execute('select * from feedback_reports order by rowid').fetchall()
 assert len(rows)==29 and db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]==29
 assert hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest()=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e'
QUIZ_PREFLIGHT'''
