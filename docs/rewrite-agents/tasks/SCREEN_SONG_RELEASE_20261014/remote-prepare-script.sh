set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
test ! -e /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:039474ddb2feac0986908a7681c18fcf39cb716428e9c8acf199e8f9e044c961
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
echo '64e50bf9f49bd1287b0964f234cb9545508b878315e8fd577c262dc5c5ade6df  /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608.tar.gz' | sha256sum -c -
mkdir /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608
test "$(readlink -f /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608)" = /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608
tar -xzf /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608
cd /opt/quiz-master/releases/quiz-2026.10.14-screen-song-6866608
sha256sum -c checksums.txt > candidate-checksums.log
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(), "rehearse.py", "exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
