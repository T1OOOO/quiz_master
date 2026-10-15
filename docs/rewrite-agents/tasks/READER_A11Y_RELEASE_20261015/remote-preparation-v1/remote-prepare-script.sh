set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys; x=json.load(sys.stdin); version=x["version"];status=x["info"]["status"];assert version==58 and status=="deployed"'
test "$(hostname)" = racknerd-f0269d5
python3 - <<'QUIZ_PREFLIGHT'
import json,os,subprocess,urllib.request
helm=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
assert helm['version']==58 and helm['info']['status']=='deployed'
deploy=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
images=[c['image'] for c in deploy['spec']['template']['spec']['containers']]
assert len(images)==2 and set(images)=={'docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50'}
assert deploy['status'].get('availableReplicas')==1
pvc=json.loads(subprocess.check_output(['kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json']))
assert pvc['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
nodes=json.loads(subprocess.check_output(['kubectl','get','nodes','-o','json']))['items']
assert len(nodes)==1
node=nodes[0];conditions={c['type']:c['status'] for c in node['status']['conditions']}
assert conditions.get('Ready')=='True' and conditions.get('DiskPressure')=='False'
assert not node.get('spec',{}).get('unschedulable',False)
assert not any(t.get('effect') in ('NoSchedule','NoExecute') for t in node.get('spec',{}).get('taints',[]))
usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
assert usage.f_bavail*usage.f_frsize*5>=usage.f_blocks*usage.f_frsize
with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready',timeout=15) as response: assert response.status==200
QUIZ_PREFLIGHT
test ! -e /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795
test ! -e /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795.tar.gz
echo 'e253eeecfbb84f199e947e5e4a2ffc7db48450b1982e2f871dd37edf8becf8b0  /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795.tar.gz.upload-1d88c56468144be58c5896c951443e61' | sha256sum -c -
test ! -L /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795.tar.gz.upload-1d88c56468144be58c5896c951443e61
mv -- /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795.tar.gz.upload-1d88c56468144be58c5896c951443e61 /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795.tar.gz
mkdir /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795
test "$(readlink -f /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795)" = /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795
tar -xzf /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795
cd /opt/quiz-master/releases/quiz-2026.10.15-reader-6384795
sha256sum -c checksums.txt > candidate-checksums.log
test -f runtime-public-baseline.json
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(),"rehearse.py","exec"); compile(Path("verify_candidate_runtime.py").read_text(),"verify_candidate_runtime.py","exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
