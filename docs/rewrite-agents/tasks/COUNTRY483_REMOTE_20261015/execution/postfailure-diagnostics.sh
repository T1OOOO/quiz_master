set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'COUNTRY483_DIAGNOSTICS'
import os,json,subprocess,sqlite3,hashlib,urllib.request,pathlib
usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=usage.f_bavail*usage.f_frsize;total=usage.f_blocks*usage.f_frsize
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
d=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
p=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
n=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items'][0]
with sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True) as db:
 rows=db.execute('select * from feedback_reports order by rowid').fetchall();opened=db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0]
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response:status=response.status
stage=pathlib.Path('/opt/quiz-master/releases/quiz-2026.10.15-country483-3c22818')
backup=pathlib.Path('/opt/quiz-master/backups/quiz-2026.10.15-country483-3c22818-cutover-20261015T210834Z.sqlite')
img=subprocess.run(['docker','image','inspect','quiz-master:quiz-2026.10.15-country483-3c22818','--format','{{.Id}}'],capture_output=True,text=True)
print(json.dumps(dict(available_bytes=free,total_bytes=total,strict20=free*5>total,minimum_bytes=total//5+1,headroom_bytes=free-(total//5+1),helm_revision=h['version'],helm_status=h['info']['status'],images=[c['image'] for c in d['spec']['template']['spec']['containers']],available_replicas=d['status'].get('availableReplicas'),pvc_uid=p['metadata']['uid'],pvc_phase=p['status']['phase'],node_conditions={c['type']:c['status'] for c in n['status']['conditions']},https_readiness_status=status,feedback_count=len(rows),feedback_open=opened,feedback_sha256=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest(),owned_stage_allocated_bytes=int(subprocess.check_output(['du','-s','-B1',str(stage)]).split()[0]),owned_backup_bytes=backup.stat().st_size,owned_backup_mode=oct(backup.stat().st_mode&0o777),candidate_image_inspect_exit=img.returncode,candidate_image=img.stdout.strip() or None,candidate_runtime_receipts=len(list(stage.glob('*-candidate-runtime.json'))),candidate_atlas_receipts=len(list(stage.glob('*-candidate-atlas.json'))),durable_image_exists=pathlib.Path('/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-country483-3c22818.tar').exists())))
COUNTRY483_DIAGNOSTICS
