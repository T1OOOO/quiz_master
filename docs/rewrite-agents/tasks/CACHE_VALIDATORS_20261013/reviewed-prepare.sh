set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
quiz_stage=/opt/quiz-master/releases/cache-20261013T082020Z-d851284
quiz_tag=quiz-master:cache-20261013T082020Z-d851284
quiz_base=quiz-master:quiz-2026.10.13-culture-e437661
quiz_baseline=docker.io/library/quiz-master@sha256:3079779783215975b119ef6a187a325ced1fd807a31b15b0c4cd090d0d2298d5
test "$(readlink -f "$quiz_stage")" = "$quiz_stage"
cd "$quiz_stage"
sha256sum -c inputs.sha256
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "$quiz_baseline"
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
test "$(docker image inspect --format '{{.Id}}' "$quiz_base")" = sha256:3079779783215975b119ef6a187a325ced1fd807a31b15b0c4cd090d0d2298d5
test "$(df --output=avail -B1 /opt/quiz-master | tail -1)" -gt 4000000000
test "$(helm list -n quiz-master -o json | python3 -c 'import json,sys;print(next(x["revision"] for x in json.load(sys.stdin) if x["name"]=="quiz-master"))')" = 46
helm get values quiz-master -n quiz-master -o json > baseline-values.json
python3 - <<'PY'
import json
from pathlib import Path
v=json.loads(Path('baseline-values.json').read_text())
assert v['image']=='docker.io/library/quiz-master@sha256:3079779783215975b119ef6a187a325ced1fd807a31b15b0c4cd090d0d2298d5'
assert v['buildId']=='quiz-2026.10.13-culture-e437661'
assert v['feedbackAdminSecret']=='quiz-feedback-admin'
assert set(v)=={'image','buildId','feedbackAdminSecret'},set(v)
PY
docker build --network=none --pull=false --build-arg BASE_IMAGE="$quiz_base" -f Dockerfile.cache-hotfix -t "$quiz_tag" .
test "$(docker image inspect --format '{{.Id}}' "$quiz_base")" = sha256:3079779783215975b119ef6a187a325ced1fd807a31b15b0c4cd090d0d2298d5
docker run --rm --network=none --read-only --tmpfs /tmp --entrypoint nginx "$quiz_tag" -t
for quiz_pair in baseline candidate; do
 quiz_image="$quiz_base"; if test "$quiz_pair" = candidate; then quiz_image="$quiz_tag"; fi
 docker run --rm --network=none --read-only --entrypoint sh "$quiz_image" -c 'find /app /usr/share/nginx/html -type f -exec sha256sum {} \; | sort' > "$quiz_pair-application.sha256"
done
cmp baseline-application.sha256 candidate-application.sha256
docker run --rm --network=none --read-only --entrypoint cat "$quiz_tag" /etc/nginx/nginx.conf > candidate-nginx.conf
cmp nginx.conf candidate-nginx.conf
quiz_archive="/var/lib/rancher/k3s/agent/images/$quiz_tag.tar"
# A tag contains ':'; the archive remains one explicitly named file in the verified image directory.
test "$(readlink -f /var/lib/rancher/k3s/agent/images)" = /var/lib/rancher/k3s/agent/images
test ! -e "$quiz_archive"
docker save "$quiz_tag" | tee "$quiz_archive" | k3s ctr images import -
sha256sum "$quiz_archive" > durable-image.sha256
quiz_digest=$(k3s ctr images ls | awk -v tag="docker.io/library/$quiz_tag" '$1==tag {print $3}')
[[ "$quiz_digest" =~ ^sha256:[a-f0-9]{64}$ ]]
k3s ctr images tag --force "docker.io/library/$quiz_tag" "docker.io/library/quiz-master@$quiz_digest"
QUIZ_DIGEST="$quiz_digest" python3 - <<'PY'
import json,os
from pathlib import Path
v=json.loads(Path('baseline-values.json').read_text());v['image']='docker.io/library/quiz-master@'+os.environ['QUIZ_DIGEST']
Path('candidate-values.json').write_text(json.dumps(v,indent=2)+'\n')
PY
quiz_prior=/opt/quiz-master/releases/quiz-2026.10.13-culture-e437661
(cd "$quiz_prior" && sha256sum -c checksums.txt > "$quiz_stage/baseline-package-check.log")
cp -a "$quiz_prior/chart" chart
helm lint --strict chart -n quiz-master -f candidate-values.json
helm template quiz-master chart -n quiz-master -f baseline-values.json > baseline-rendered.yaml
helm template quiz-master chart -n quiz-master -f candidate-values.json > candidate-rendered.yaml
QUIZ_BASELINE="$quiz_baseline" QUIZ_DIGEST="$quiz_digest" python3 - <<'PY'
from pathlib import Path
import os
a=Path('baseline-rendered.yaml').read_text();b=Path('candidate-rendered.yaml').read_text()
assert a.count(os.environ['QUIZ_BASELINE'])==2
assert b==a.replace(os.environ['QUIZ_BASELINE'],'docker.io/library/quiz-master@'+os.environ['QUIZ_DIGEST'])
PY
kubectl apply --dry-run=server -n quiz-master -f candidate-rendered.yaml
QUIZ_STAGE="$quiz_stage" QUIZ_TAG="$quiz_tag" QUIZ_DIGEST="$quiz_digest" QUIZ_ARCHIVE="$quiz_archive" python3 - <<'PY'
import json,os,hashlib
from pathlib import Path
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
data={'stage':os.environ['QUIZ_STAGE'],'tag':os.environ['QUIZ_TAG'],'image':'docker.io/library/quiz-master@'+os.environ['QUIZ_DIGEST'],
      'durable_archive':os.environ['QUIZ_ARCHIVE'],'durable_archive_sha256':Path('durable-image.sha256').read_text().split()[0],
      'nginx_sha256':sha('nginx.conf'),'application_manifest_sha256':sha('candidate-application.sha256'),
      'application_file_count':len(Path('candidate-application.sha256').read_text().splitlines()),
      'values_sha256':sha('candidate-values.json'),'rendered_sha256':sha('candidate-rendered.yaml'),
      'source_commit':Path('source-commit.txt').read_text().strip(),'baseline_helm_revision':46,'application_build_id':'quiz-2026.10.13-culture-e437661',
      'checks':['base image hash before/after','Nginx syntax','all API/Web file hashes identical','exact canonical config','durable import','strict Helm lint','only two rendered image references changed','server dry-run'],
      'limits':['No publication performed','No database migration or new Flutter/API build']}
Path('prepared.json').write_text(json.dumps(data,indent=2)+'\n');print(json.dumps(data))
PY
