set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(hostname)" = racknerd-f0269d5
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:2d1ea6bcb0f92bf62b7173bb23ff0133cfd457ebd4746f08cbcdd73e3f221727
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys; x=json.load(sys.stdin); version=x["version"];status=x["info"]["status"];assert version==53 and status=="deployed"'
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
test ! -e /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce
test ! -e /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz
echo '052791b502cc068c57831473ff200cbd8fdc756018942c500508ca81a0b7f872  /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz.upload-e84899b4b6f547da8d448b421593f928' | sha256sum -c -
test ! -L /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz.upload-e84899b4b6f547da8d448b421593f928
mv -- /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz.upload-e84899b4b6f547da8d448b421593f928 /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz
mkdir /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce
test "$(readlink -f /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce)" = /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce
tar -xzf /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz --no-same-owner --strip-components=1 -C /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce
cd /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce
sha256sum -c checksums.txt > candidate-checksums.log
test -f runtime-public-baseline.json
bash -n cutover.sh
python3 -c 'from pathlib import Path; compile(Path("rehearse.py").read_text(),"rehearse.py","exec"); compile(Path("verify_candidate_runtime.py").read_text(),"verify_candidate_runtime.py","exec")'
flock -u 8
exec 8>&-
bash cutover.sh prepare 2>&1 | tee prepare.log
