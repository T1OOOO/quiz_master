set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'PY'
import json,subprocess,os,urllib.request
tag='quiz-master:quiz-2026.10.15-reader-06dfa0b'
expected='docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50'
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
d=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
assert h['version']==58 and h['info']['status']=='deployed' and d['status'].get('availableReplicas')==1
assert set(c['image'] for c in d['spec']['template']['spec']['containers'])=={expected}
stored=subprocess.check_output(['k3s','ctr','images','ls','-q'],text=True).splitlines();assert expected in stored
from pathlib import Path
import hashlib
candidate='docker.io/library/quiz-master@sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af'
assert candidate in stored
assert hashlib.sha256(Path('/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar').read_bytes()).hexdigest()=='b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684'
inspection=subprocess.run(['docker','image','inspect','--format','{{json .Id}}',tag],capture_output=True,text=True)
if inspection.returncode:
 print(json.dumps({'status':'NO_DUPLICATE_DOCKER_TAG','tag':tag,'production_helm':58}));raise SystemExit(0)
image=json.loads(inspection.stdout)
assert not subprocess.check_output(['docker','ps','-aq','--filter','ancestor='+image],text=True).strip()
u=os.statvfs('/var/lib/rancher/k3s/agent/containerd');before=u.f_bavail*u.f_frsize
subprocess.run(['docker','image','rm',tag],capture_output=True,check=True)
assert {expected,candidate} <= set(subprocess.check_output(['k3s','ctr','images','ls','-q'],text=True).splitlines())
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as ready:assert ready.status==200
u=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
print(json.dumps({'status':'REMOVED_ONLY_UNUSED_DOCKER_DUPLICATE_TAG','tag':tag,'docker_image_id':image,'dependent_docker_containers':0,'production_k3s_image_preserved':expected,'disk_available_before':before,'disk_available_after':u.f_bavail*u.f_frsize,'disk_total':u.f_blocks*u.f_frsize,'https_ready':200,'production_helm':58,'rollback_archives_and_backups_preserved':True,'shared_cache_pruned':False,'other_projects_changed':False}))
PY
