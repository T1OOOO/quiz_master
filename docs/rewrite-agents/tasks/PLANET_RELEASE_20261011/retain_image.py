from pathlib import Path
import subprocess
r=Path('C:/ap/quiz_master/.run/planet_release_20261011')
script='''set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:0c6ba082bf21b85298c5743e88ba1f3d74f696c91038b02228055798241f2fa0
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
quiz_archive=/var/lib/rancher/k3s/agent/images/quiz-master-d228c9e-0c6b.tar
test ! -e "$quiz_archive"
docker save quiz-master:quiz-2026.10.11-planets-d228c9e > /opt/quiz-master/releases/quiz-2026.10.11-planets-d228c9e/durable-image.partial
mv /opt/quiz-master/releases/quiz-2026.10.11-planets-d228c9e/durable-image.partial "$quiz_archive"
sha256sum "$quiz_archive"
stat -c '%s bytes' "$quiz_archive"
kubectl get pods -n quiz-master -l app.kubernetes.io/name=quiz-master
'''
p=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184',script],text=True,capture_output=True)
(r/'retained-image.txt').write_text(p.stdout+p.stderr,encoding='utf-8')
print(p.stdout,p.stderr)
assert p.returncode==0
