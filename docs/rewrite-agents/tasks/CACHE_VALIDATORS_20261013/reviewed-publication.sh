set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
exec 9>/opt/quiz-master/DEPLOY.lock
flock -n 9
quiz_stage=/opt/quiz-master/releases/cache-20261013T082020Z-d851284
quiz_image=docker.io/library/quiz-master@sha256:fa00bc8e559ec5a02ed62903f7ed91c00540f11de0a16b0cddc5b15717f5317f
quiz_baseline=docker.io/library/quiz-master@sha256:3079779783215975b119ef6a187a325ced1fd807a31b15b0c4cd090d0d2298d5
test "$(readlink -f "$quiz_stage")" = "$quiz_stage"
cd "$quiz_stage"
sha256sum -c inputs.sha256
printf '%s  candidate-values.json\n%s  candidate-rendered.yaml\n%s  candidate-application.sha256\n' b36ef2bccee6f9af852b854f8aa13d219f574212c91fd271310911f0a8292e8b 8178d2c1b64605eef80766d313b7874d9fb8bd3e834726d4e10d50737b971478 c75c12dcd9984678e83b84e543565ead35c5532dcb73bb8db173e9085ef26a40 | sha256sum -c -
sha256sum -c durable-image.sha256
printf '%s  %s\n' 7412fd73558e81be73bece09b3330720018d507cb80ef624c435b7e503bf923b /var/lib/rancher/k3s/agent/images/quiz-master:cache-20261013T082020Z-d851284.tar | sha256sum -c -
test "$(k3s ctr images ls | awk -v ref="$quiz_image" '$1==ref {print $3}')" = sha256:fa00bc8e559ec5a02ed62903f7ed91c00540f11de0a16b0cddc5b15717f5317f
python3 - <<'PY'
import json,subprocess,shutil
def call(*args):return subprocess.check_output(args,text=True)
d=json.loads(call('kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'))
assert d['status']['readyReplicas']==1 and d['status']['availableReplicas']==1
assert all(c['image']=='docker.io/library/quiz-master@sha256:3079779783215975b119ef6a187a325ced1fd807a31b15b0c4cd090d0d2298d5' for c in d['spec']['template']['spec']['containers'])
assert len(d['spec']['template']['spec']['containers'])==2
p=json.loads(call('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','json'));assert p['metadata']['uid']=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and p['status']['phase']=='Bound'
h=json.loads(call('helm','list','-n','quiz-master','-o','json'));q=next(x for x in h if x['name']=='quiz-master');assert q['revision']=='46' and q['status']=='deployed'
for n in json.loads(call('kubectl','get','nodes','-o','json'))['items']:
 for c in n['status']['conditions']:
  if c['type']=='Ready':assert c['status']=='True'
  if c['type'].endswith('Pressure'):assert c['status']=='False'
assert shutil.disk_usage('/var/lib/rancher/k3s').free>4000000000
PY
helm template quiz-master chart -n quiz-master -f candidate-values.json > publication-rendered.yaml
cmp candidate-rendered.yaml publication-rendered.yaml
kubectl apply --dry-run=server -n quiz-master -f publication-rendered.yaml
# SQLite backup is read-only at the source. No database restoration/migration is performed in this release.
python3 - <<'PY'
import sqlite3,json,os
from pathlib import Path
p=Path('/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db');assert p.resolve()==p
backup=Path('prepublication.sqlite');assert not backup.exists() and not backup.is_symlink()
fd=os.open(backup,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600);os.close(fd)
source=sqlite3.connect('file:'+str(p)+'?mode=ro',uri=True);target=sqlite3.connect(backup);source.backup(target)
assert target.execute('pragma integrity_check').fetchone()==('ok',)
counts=target.execute('select status,count(*) from feedback_reports group by status').fetchall()
target.close();source.close();print(json.dumps({'backup_integrity':'ok','feedback_status_counts_at_backup':counts}))
PY
quiz_started=0
rollback_on_failure() {
 quiz_exit=$?
 trap - ERR
 if test "$quiz_started" = 1; then
  quiz_current=$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')
  quiz_revision=$(helm list -n quiz-master -o json | python3 -c 'import json,sys;print(next(x["revision"] for x in json.load(sys.stdin) if x["name"]=="quiz-master"))')
  if test "$quiz_current" = "$quiz_image" && test "$quiz_revision" = 47; then
   helm rollback quiz-master 46 -n quiz-master --wait --timeout 180s
   test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "$quiz_baseline"
  elif test "$quiz_current" != "$quiz_baseline"; then
   echo 'Rollback skipped: deployment is not this hotfix or baseline; preserve state and investigate.' >&2
  fi
 fi
 exit "$quiz_exit"
}
trap rollback_on_failure ERR
quiz_started=1
helm upgrade quiz-master chart -n quiz-master -f candidate-values.json --atomic --wait --timeout 180s
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = "$quiz_image"
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
python3 - <<'PY'
import hashlib,json,urllib.request,subprocess
from pathlib import Path
m=json.loads(Path('prepared.json').read_text())
d=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'],text=True))
assert d['status']['readyReplicas']==1 and d['status']['availableReplicas']==1
assert all(c['image']==m['image'] for c in d['spec']['template']['spec']['containers'])
expected=Path('/opt/quiz-master/releases/quiz-2026.10.13-culture-e437661/web')
checks=[]
for path in ['version.json','main.dart.js','assets/assets/catalog.json']:
 content=(expected/path).read_bytes();tag='"0-'+format(len(content),'x')+'"'
 for headers in [{'If-None-Match':tag},{'If-Modified-Since':'Thu, 01 Jan 1970 00:00:00 GMT'},{'If-None-Match':tag,'If-Modified-Since':'Thu, 01 Jan 1970 00:00:00 GMT'}]:
  with urllib.request.urlopen(urllib.request.Request('https://quiz.kotopedia.org/'+path,headers=headers),timeout=15) as res:
   body=res.read();assert res.status==200 and body==content
   assert res.headers.get('ETag') is None
   assert res.headers['Cache-Control']=='no-cache'
   assert res.headers['X-Content-Type-Options']=='nosniff'
   checks.append({'path':path,'headers':headers,'status':res.status,'sha256':hashlib.sha256(body).hexdigest()})
for route in ['health/live','health/ready']:
 with urllib.request.urlopen('https://quiz.kotopedia.org/'+route,timeout=15) as res:assert res.status==200
result={'actual_publication':True,'image':m['image'],'helm_revision':47,'conditional_checks':checks,
        'application_build_id':m['application_build_id'],'ready':1,'available':1,'database_migration':False}
Path('published.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
PY
trap - ERR
