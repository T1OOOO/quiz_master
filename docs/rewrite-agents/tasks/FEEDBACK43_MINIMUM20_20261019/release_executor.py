#!/usr/bin/env python3
"""Prepare an immutable, review-gated release-70 package; it never runs remotely by default."""
from __future__ import annotations
import argparse, hashlib, json, re, shlex, shutil, subprocess, sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

HOST='racknerd-f0269d5'; HOST_IP='192.3.164.184'; NAMESPACE=RELEASE='quiz-master'
BASE_REVISION='69'; BASE_DEPLOYMENT_REVISION='67'; BASE_BUILD_ID='quiz-2026.10.19-bones-36e0b68c'
BASE_DIGEST='sha256:54a3455a7efac04ab6ee6f9ffb5a053d3ce2ca431ee938557d4ab2aed928d54a'
BASE_IMAGE=f'quiz-master:{BASE_BUILD_ID}@{BASE_DIGEST}'; BASE_LOCAL_TAG=f'quiz-master:{BASE_BUILD_ID}'
BASE_API_SHA256='208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa'
BASE_SOURCE_REVISION='36e0b68c64d1b6647923b5e5ddcc70d34e7edd60'; PVC_UID='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
DB_PATH='/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db'
LOCK_PATH='/opt/quiz-master/DEPLOY.lock'; RELEASE_PARENT='/opt/quiz-master/releases'; BACKUP_PARENT='/opt/quiz-master/backups'; K3S_IMAGEFS='/var/lib/rancher/k3s/agent/containerd'; MIN_FIXED_HEADROOM=512*1024*1024
BUILD_RE=re.compile(r'^quiz-[a-z0-9][a-z0-9.-]{5,100}$')
EXPECTED_MUTATED=frozenset({
'Cinema/People/cinema_people_20261011.json','Cinema/Thematic80/tv_series.json','Gastronomy/gastronomy_general_facts_1.json','MusicPeople/music_people_20261011.json','Philias/philias_nature.json','Psychology/phobias_general.json',
'Cinema/Thematic80/game_worlds.json','Cinema/Thematic80/harry_potter.json','Nature/Cats/cats_behavior_and_psychology.json','Nature/Dogs/dogs_science_and_experiments.json','Science/planet_paradoxes_20261010.json'})
SUPPORT=('rehearse.py','pool-materialization-evidence.json','import20-evidence.json','import18-evidence.json','planets-acceptance.json','games-acceptance.json','harrypotter-acceptance.json','animal-extras-acceptance.json')
DOCKERFILE=f'''ARG BASE_IMAGE={BASE_LOCAL_TAG}\nFROM ${{BASE_IMAGE}}\nUSER 0:0\nCOPY --chown=10001:10001 api /app/api\nCOPY --chown=10001:10001 quizzes/ /app/quizzes/\nRUN find /usr/share/nginx/html -mindepth 1 -maxdepth 1 -exec rm -rf -- {{}} +\nCOPY --chown=10001:10001 web/ /usr/share/nginx/html/\nUSER 10001:10001\n'''
class GuardError(RuntimeError): pass
@dataclass(frozen=True)
class Inputs: package:Path; web:Path; chart:Path; version:Path; manifest:dict[str,Any]
def sha256_file(path:Path)->str:
 h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
 return h.hexdigest()
def hash_tree(root:Path)->dict[str,str]:
 if not root.is_dir() or root.is_symlink(): raise GuardError(f'required non-symlink directory missing: {root}')
 result={}
 for p in sorted(root.rglob('*')):
  if p.is_symlink(): raise GuardError(f'symlink is forbidden in release input: {p}')
  if p.is_file(): result[p.relative_to(root).as_posix()]=sha256_file(p)
 if not result: raise GuardError(f'required directory is empty: {root}')
 return result
def validate_node_status(node:dict[str,Any])->None:
 c={x.get('type'):x.get('status') for x in node.get('status',{}).get('conditions',[])}
 if c.get('Ready')!='True' or c.get('DiskPressure')!='False' or node.get('spec',{}).get('unschedulable') or any(x.get('effect') in ('NoSchedule','NoExecute') for x in node.get('spec',{}).get('taints',[])): raise GuardError('node must be schedulable, Ready=True and DiskPressure=False')
def validate_imagefs_blocks(avail:int,blocks:int)->None:
 if blocks<=0 or avail<0 or avail*5<blocks: raise GuardError('k3s image filesystem has less than 20% available blocks')
def validate_build_id(build:str)->None:
 if not BUILD_RE.fullmatch(build) or not build.startswith('quiz-2026.10.19-minimum20-') or build==BASE_BUILD_ID: raise GuardError('invalid immutable minimum20 build ID')
def validate_ssh_target(target:str)->None:
 if target not in {HOST,HOST_IP,'root@'+HOST,'root@'+HOST_IP}: raise GuardError('SSH target must be pinned production host')
def read_preflight(path:Path)->None:
 raw=path.read_text(encoding='utf-8'); dec=json.JSONDecoder(); deployment,pos=dec.raw_decode(raw); version,_=dec.raw_decode(raw[pos:].lstrip())
 if deployment.get('hostname')!=HOST or str(deployment.get('revision'))!=BASE_REVISION or deployment.get('deployment_revision')!=BASE_DEPLOYMENT_REVISION or deployment.get('pvc_uid')!=PVC_UID: raise GuardError('preflight deployment/PVC differs from baseline 69')
 if {x.get('image') for x in deployment.get('containers',[])}!={BASE_IMAGE} or version.get('buildId')!=BASE_BUILD_ID or version.get('api_sha256')!=BASE_API_SHA256: raise GuardError('preflight image/API baseline differs')
def validate_quiz_closure(closure:dict[str,Any], candidate:dict[str,str])->None:
 base=closure.get('base'); expected=closure.get('expected_mutated');
 if not isinstance(base,dict) or len(base)!=148 or set(expected or [])!=EXPECTED_MUTATED or closure.get('candidate')!=candidate: raise GuardError('quiz closure lock is incomplete')
 if len(candidate)!=165 or not set(base)<=set(candidate) or len(set(candidate)-set(base))!=17: raise GuardError('candidate must contain 165 files: baseline 148 plus 17 new')
 changed={k for k in base if base[k]!=candidate[k]}
 if changed!=EXPECTED_MUTATED: raise GuardError('existing quiz source closure differs outside exact 11 approved files')
def collect_inputs(package:Path)->Inputs:
 package=package.resolve(); web,chart,quizzes=package/'web',package/'chart',package/'quizzes'; version=web/'version.json'; api=package/'api'
 for p in (version,chart/'Chart.yaml',api,package/'quiz-closure.json',package/'catalog.json',*map(lambda n:package/n,SUPPORT)):
  if not p.is_file() or p.is_symlink(): raise GuardError(f'missing/symlinked package input: {p}')
 if api.read_bytes()[:4]!=b'\x7fELF': raise GuardError('candidate API must be Linux ELF')
 target_api=sha256_file(api)
 if target_api==BASE_API_SHA256: raise GuardError('minimum20 API must differ from baseline API')
 v=json.loads(version.read_text(encoding='utf-8'))
 if v.get('api_sha256')!=target_api or v.get('packs')!=105 or v.get('questions')!=4520 or v.get('quizipedia_facts')!=13588 or v.get('question_articles')!=305 or v.get('question_article_references')!=241 or not re.fullmatch(r'[0-9a-f]{40}',str(v.get('source_commit',''))) or v.get('frontend_only') is True: raise GuardError('candidate version contract differs')
 js=web/'main.dart.js'
 if not js.is_file() or v.get('main_dart_js_sha256')!=sha256_file(js): raise GuardError('candidate web JS hash differs')
 flags=list((web/'flags').glob('*.png'))
 if len(flags)!=195 or any(not p.read_bytes().startswith(b'\x89PNG\r\n\x1a\n') or p.name!=sha256_file(p)+'.png' for p in flags): raise GuardError('195 content-addressed PNG flags required')
 qhash=hash_tree(quizzes); closure=json.loads((package/'quiz-closure.json').read_text(encoding='utf-8')); validate_quiz_closure(closure,qhash)
 manifest={'baseline':{'deployed_image':BASE_IMAGE,'local_image':BASE_LOCAL_TAG,'api_sha256':BASE_API_SHA256,'revision':BASE_REVISION},'target_api_sha256':target_api,'web':hash_tree(web),'chart':hash_tree(chart),'quizzes':qhash,'quiz_closure_sha256':sha256_file(package/'quiz-closure.json'),'catalog_sha256':sha256_file(package/'catalog.json'),'support':{n:sha256_file(package/n) for n in SUPPORT},'version_sha256':sha256_file(version),'dockerfile_sha256':hashlib.sha256(DOCKERFILE.encode()).hexdigest()}
 return Inputs(package,web,chart,version,manifest)
def validate_package_identity(inputs:Inputs,build:str)->None:
 validate_build_id(build); v=json.loads(inputs.version.read_text(encoding='utf-8'))
 if v.get('buildId')!=build: raise GuardError('version build ID differs')
def write_local_manifest(inputs:Inputs)->Path:
 p=inputs.package/'release-inputs.json'
 if p.exists(): raise GuardError('refusing to overwrite release manifest')
 p.write_text(json.dumps(inputs.manifest,sort_keys=True,indent=2)+'\n',encoding='utf-8',newline='\n'); return p
def remote_stage_script(build:str)->str:
 stage=f'{RELEASE_PARENT}/{build}'
 return f'''set -euo pipefail\numask 077\ntest "$(hostname)" = {shlex.quote(HOST)}\nexec 9>{shlex.quote(LOCK_PATH)}; flock -n 9\npython3 - <<'PY'\nimport os\ns=os.statvfs({K3S_IMAGEFS!r}); assert s.f_bavail*5>=s.f_blocks\nPY\ntest ! -e {shlex.quote(stage)}; mkdir -m 700 {shlex.quote(stage)}; trap 'rm -rf -- {shlex.quote(stage)}' ERR\ntar -xf - -C {shlex.quote(stage)} --no-same-owner --no-same-permissions\n'''
def remote_script(build:str,target_api:str,phase:str)->str:
 if not re.fullmatch(r'[0-9a-f]{64}',target_api) or phase not in ('prepare','publish'): raise GuardError('invalid remote request')
 stage=f'{RELEASE_PARENT}/{build}'; tag=f'quiz-master:{build}'; backup=f'{BACKUP_PARENT}/{build}.sqlite'
 return f'''#!/usr/bin/env bash\nset -Eeuo pipefail\numask 077\nstage={shlex.quote(stage)}; tag={shlex.quote(tag)}; backup={shlex.quote(backup)}; phase={shlex.quote(phase)}\nexec 9>{shlex.quote(LOCK_PATH)}; flock -n 9\ntest "$(hostname)" = {shlex.quote(HOST)}\nnode=$(kubectl get nodes -o jsonpath='{{.items[0].metadata.name}}'); kubectl get node "$node" -o json | python3 -c 'import json,sys; n=json.load(sys.stdin); c={{x["type"]:x["status"] for x in n["status"].get("conditions",[])}}; assert c.get("Ready")=="True" and c.get("DiskPressure")=="False" and not n["spec"].get("unschedulable",False)'\npython3 -c "import os;s=os.statvfs('{K3S_IMAGEFS}');assert s.f_bavail*5>=s.f_blocks"\ntest "$(helm history {RELEASE} -n {NAMESPACE} -o json | python3 -c 'import json,sys;print(json.load(sys.stdin)[-1]["revision"])')" = {BASE_REVISION}\ntest "$(kubectl get deploy {RELEASE} -n {NAMESPACE} -o jsonpath='{{.metadata.annotations.deployment\\.kubernetes\\.io/revision}}')" = {BASE_DEPLOYMENT_REVISION}\ntest "$(kubectl get pvc quiz-data -n {NAMESPACE} -o jsonpath='{{.metadata.uid}}')" = {PVC_UID}\nimages=$(kubectl get deploy {RELEASE} -n {NAMESPACE} -o jsonpath='{{range .spec.template.spec.containers[*]}}{{.image}}{{"\\n"}}{{end}}'); test "$images" = "$(printf '%s\\n%s' {shlex.quote(BASE_IMAGE)} {shlex.quote(BASE_IMAGE)})"\ntest -f "$stage/release-inputs.json"; test "$(sha256sum "$stage/api"|awk '{{print $1}}')" = {target_api}\nif [ "$phase" = prepare ]; then\n test ! -e "$backup"; test ! -e "$(docker image inspect "$tag" >/dev/null 2>&1 && echo yes)"\n base=$(docker create {shlex.quote(BASE_LOCAL_TAG)}); new=''; rehearsal=''\n cleanup() {{ docker rm -f "$base" ${{new:+"$new"}} ${{rehearsal:+"$rehearsal"}} >/dev/null 2>&1 || true; }}; trap cleanup EXIT\n docker cp "$base:/app/api" "$stage/base.api"; test "$(sha256sum "$stage/base.api"|awk '{{print $1}}')" = {BASE_API_SHA256}\n docker cp "$base:/etc/nginx/nginx.conf" "$stage/base.nginx.conf"\n docker build --network=none --pull=false --build-arg BASE_IMAGE={shlex.quote(BASE_LOCAL_TAG)} -t "$tag" "$stage"\n docker run --rm --network=none --read-only --tmpfs /tmp "$tag" nginx -t\n new=$(docker create "$tag"); docker cp "$new:/app/api" "$stage/new.api"; docker cp "$new:/etc/nginx/nginx.conf" "$stage/new.nginx.conf"\n test "$(sha256sum "$stage/new.api"|awk '{{print $1}}')" = {target_api}; test "$(sha256sum "$stage/new.api"|awk '{{print $1}}')" != {BASE_API_SHA256}; cmp -s "$stage/base.nginx.conf" "$stage/new.nginx.conf"\n docker cp "$base:/app/quizzes" "$stage/base-quizzes"; docker cp "$new:/app/quizzes" "$stage/candidate-quizzes"\n python3 - "$stage" <<'PY'\nimport hashlib,json,pathlib,sys\nr=pathlib.Path(sys.argv[1]); lock=json.load(open(r/'quiz-closure.json'))\ndef tree(p): return {{x.relative_to(p).as_posix():hashlib.sha256(x.read_bytes()).hexdigest() for x in p.rglob('*') if x.is_file() and not x.is_symlink()}}\na,b=tree(r/'base-quizzes'),tree(r/'candidate-quizzes'); assert a==lock['base'] and b==lock['candidate']; assert len(a)==148 and len(b)==165\nPY\n python3 - {shlex.quote(DB_PATH)} "$stage/feedback-before.json" <<'PY'
import hashlib,json,sqlite3,sys
db=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True); cols=[x[1] for x in db.execute('pragma table_info(feedback_reports)')]; assert 'id' in cols; i=cols.index('id'); json.dump({{hashlib.sha256(str(r[i]).encode()).hexdigest():hashlib.sha256(repr(tuple(r)).encode()).hexdigest() for r in db.execute('select * from feedback_reports order by id')}},open(sys.argv[2],'w'),sort_keys=True)
PY
 sqlite3 {shlex.quote(DB_PATH)} ".backup '$backup'"; test "$(sqlite3 "$backup" 'pragma integrity_check')" = ok; cp --reflink=auto "$backup" "$stage/restore-proof.sqlite"\n install -d -m 700 "$stage/rehearsal-data"; cp "$stage/restore-proof.sqlite" "$stage/rehearsal-data/quiz.db"; chown -R 10001:10001 "$stage/rehearsal-data"\n rehearsal=$(docker run -d --network=host --read-only --tmpfs /tmp --user 10001:10001 --entrypoint /app/api -e QM_LISTEN_ADDR=127.0.0.1:18088 -e QM_DATABASE_URL=sqlite:../data/quiz.db -e QM_CONTENT_BUNDLE_PATH=/app/quizzes -e QM_CONTENT_MANIFEST_PATH=/app/next/content/home-alone-1-part-1/manifest.json --mount type=bind,src="$stage/rehearsal-data",dst=/data "$tag")\n ready=0; for n in $(seq 1 45); do if docker exec "$rehearsal" /bin/busybox wget -q -O /dev/null http://127.0.0.1:18088/health/ready; then ready=1; break; fi; sleep 1; done; test "$ready" = 1\n python3 "$stage/rehearse.py" --base-url http://127.0.0.1:18088 --catalog-json "$stage/catalog.json" --pool-evidence "$stage/pool-materialization-evidence.json" --private-quizzes-root "$stage/private" --web-root "$stage/web" --require-real-http-grading --require-article-revision-binding\n docker save "$tag" | k3s ctr -n k8s.io images import -\n digest=$(k3s ctr -n k8s.io images ls|awk -v t="$tag" '$1==t || $1=="docker.io/library/"t{{print $3}}'); [[ "$digest" =~ ^sha256:[0-9a-f]{{64}}$ ]]; candidate="docker.io/library/quiz-master@$digest"\n k3s ctr -n k8s.io images tag "docker.io/library/$tag" "$candidate" 2>/dev/null || true; k3s crictl inspecti "$candidate" > "$stage/canonical-cri.json"\n helm get values {RELEASE} -n {NAMESPACE} -a -o yaml > "$stage/live-values.yaml"; helm lint --strict "$stage/chart" -n {NAMESPACE} -f "$stage/live-values.yaml"\n helm template {RELEASE} "$stage/chart" -n {NAMESPACE} -f "$stage/live-values.yaml" --set-string image="$candidate" --set-string buildId={shlex.quote(build)} > "$stage/rendered-target.yaml"; kubectl apply --dry-run=server -n {NAMESPACE} -f "$stage/rendered-target.yaml"\n python3 - "$stage/prepared-receipt.json" "$stage/release-inputs.json" "$candidate" <<'PY'\nimport hashlib,json,sys\njson.dump({{'build_id':{build!r},'input_sha256':hashlib.sha256(open(sys.argv[2],'rb').read()).hexdigest(),'image':sys.argv[3]}},open(sys.argv[1],'w'),sort_keys=True)\nPY\n exit 0\nfi\ntest -f "$stage/reviewed-receipt.json"; cmp -s "$stage/prepared-receipt.json" "$stage/reviewed-receipt.json"\ncandidate=$(python3 -c 'import json;print(json.load(open("'"$stage"'/prepared-receipt.json"))["image"])')\nsqlite3 {shlex.quote(DB_PATH)} ".backup '$backup'"; test "$(sqlite3 "$backup" 'pragma integrity_check')" = ok\nrollback() {{ helm rollback {RELEASE} {BASE_REVISION} -n {NAMESPACE} --wait --timeout 180s; }}\nhelm upgrade {RELEASE} "$stage/chart" -n {NAMESPACE} --reuse-values --set-string image="$candidate" --set-string buildId={shlex.quote(build)} --atomic --wait --timeout 180s || {{ rollback; exit 1; }}\nkubectl rollout status deployment/{RELEASE} -n {NAMESPACE} --timeout=180s; curl -fsS https://quiz.kotopedia.org/health/ready >/dev/null; curl -fsS https://quiz.kotopedia.org/version.json > "$stage/public-version.json"; cmp -s "$stage/public-version.json" "$stage/web/version.json"
python3 - {shlex.quote(DB_PATH)} "$stage/feedback-before.json" <<'PY'
import hashlib,json,sqlite3,sys
db=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True); cols=[x[1] for x in db.execute('pragma table_info(feedback_reports)')]; i=cols.index('id'); before=json.load(open(sys.argv[2])); after={{hashlib.sha256(str(r[i]).encode()).hexdigest():hashlib.sha256(repr(tuple(r)).encode()).hexdigest() for r in db.execute('select * from feedback_reports order by id')}}; assert all(after.get(k)==v for k,v in before.items())
PY\n'''
def plan(build:str,inputs:Inputs)->dict[str,Any]: validate_package_identity(inputs,build); return {'mode':'PLAN_ONLY','host':HOST,'baseline_revision':BASE_REVISION,'deployed_base_image':BASE_IMAGE,'new_tag':f'quiz-master:{build}','input_manifest':inputs.manifest,'remote_write':False}
def stage_package(target:str,identity:Path,build:str,inputs:Inputs)->None:
 members=['web','chart','api','quizzes','private','catalog.json','quiz-closure.json','release-inputs.json','Dockerfile',*SUPPORT]
 p=subprocess.Popen(['tar','-C',str(inputs.package),'-cf','-',*members],stdout=subprocess.PIPE)
 try: subprocess.run(['ssh','-i',str(identity),'-o','IdentitiesOnly=yes',target,'bash -c '+shlex.quote(remote_stage_script(build))],stdin=p.stdout,check=True)
 finally:
  if p.stdout: p.stdout.close()
  if p.wait()!=0: raise GuardError('local package archive failed')
def execute(target:str,identity:Path|None,build:str,inputs:Inputs,phase:str,reviewed:Path|None=None)->None:
 validate_ssh_target(target); validate_package_identity(inputs,build)
 if identity is None or not identity.is_file(): raise GuardError('execute requires explicit SSH identity')
 if phase=='publish':
  if reviewed is None or not reviewed.is_file(): raise GuardError('publish requires independent reviewed immutable prepare receipt')
  subprocess.run(['ssh','-i',str(identity),target,f'cat > {RELEASE_PARENT}/{build}/reviewed-receipt.json'],input=reviewed.read_bytes(),check=True); subprocess.run(['ssh','-i',str(identity),target,'bash','-s'],input=remote_script(build,inputs.manifest['target_api_sha256'],'publish').encode(),check=True); return
 dockerfile=inputs.package/'Dockerfile'; manifest=write_local_manifest(inputs)
 try:
  dockerfile.write_text(DOCKERFILE,encoding='utf-8',newline='\n'); stage_package(target,identity,build,inputs); subprocess.run(['ssh','-i',str(identity),target,'bash','-s'],input=remote_script(build,inputs.manifest['target_api_sha256'],'prepare').encode(),check=True)
 finally: dockerfile.unlink(missing_ok=True); manifest.unlink(missing_ok=True)
def main(argv=None)->int:
 p=argparse.ArgumentParser(description=__doc__); p.add_argument('--preflight',type=Path,required=True); p.add_argument('--package',type=Path,required=True); p.add_argument('--build-id',required=True); p.add_argument('--ssh-target',default=HOST); p.add_argument('--identity-file',type=Path); p.add_argument('--plan',action='store_true'); p.add_argument('--execute',action='store_true'); p.add_argument('--acknowledge-production',action='store_true'); p.add_argument('--phase',choices=('prepare','publish'),default='prepare'); p.add_argument('--reviewed-receipt',type=Path); a=p.parse_args(argv)
 read_preflight(a.preflight); inputs=collect_inputs(a.package)
 if a.plan or not a.execute: print(json.dumps(plan(a.build_id,inputs),sort_keys=True)); return 0
 if not a.acknowledge_production: raise GuardError('--execute requires --acknowledge-production')
 execute(a.ssh_target,a.identity_file,a.build_id,inputs,a.phase,a.reviewed_receipt); return 0
if __name__=='__main__':
 try: raise SystemExit(main())
 except GuardError as e: print('GUARD:',e,file=sys.stderr); raise SystemExit(2)