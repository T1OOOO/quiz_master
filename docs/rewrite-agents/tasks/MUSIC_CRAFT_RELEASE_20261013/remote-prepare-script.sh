set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:6d2a206a6994b792bcc08fb0c05b5f36cbcb8c6983a6b76088a63471ab75daa6
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
test ! -e /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:6d2a206a6994b792bcc08fb0c05b5f36cbcb8c6983a6b76088a63471ab75daa6
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
echo 'ae4768f4a73d94976066f24bc80dcc31636d449428660706a91154c84930f9f7  /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e.tar.gz' | sha256sum -c -
mkdir /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e
test "$(readlink -f /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e)" = /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e
tar -xzf /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e
cd /opt/quiz-master/releases/quiz-2026.10.13-music-craft-f79555e
sha256sum -c checksums.txt > candidate-checksums.log
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(), "rehearse.py", "exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
