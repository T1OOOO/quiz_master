set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:b94a399359f87024f5b00a53c47852a3e8f90f1ba6f4bb861385e9c2655f17d7
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
test ! -e /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:b94a399359f87024f5b00a53c47852a3e8f90f1ba6f4bb861385e9c2655f17d7
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
echo '9d9fdb8dff8ec88b51c8adcd987a093a3a10150cb7c6f7e667c89f416933c934  /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5.tar.gz' | sha256sum -c -
mkdir /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5
test "$(readlink -f /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5)" = /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5
tar -xzf /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5
cd /opt/quiz-master/releases/quiz-2026.10.14-acting-craft-83748f5
sha256sum -c checksums.txt > candidate-checksums.log
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(), "rehearse.py", "exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
