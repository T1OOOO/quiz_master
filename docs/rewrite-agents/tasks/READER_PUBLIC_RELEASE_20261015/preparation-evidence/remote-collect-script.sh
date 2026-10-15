set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50
test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==58 and x["info"]["status"]=="deployed"'
cd /opt/quiz-master/releases/quiz-2026.10.15-reader-06dfa0b
python3 - <<'PY'
import pathlib,json,hashlib,sqlite3,stat,shutil
from verify_candidate_runtime import verify_runtime_receipt
root=pathlib.Path.cwd();run='quiz-2026.10.15-reader-06dfa0b-cutover-20261015T030942Z'
def h(path):return hashlib.sha256(path.read_bytes()).hexdigest()
backup=pathlib.Path('/opt/quiz-master/backups')/(run+'.sqlite')
with sqlite3.connect(backup.as_uri()+'?mode=ro',uri=True) as db:assert db.execute('pragma integrity_check').fetchone()==('ok',)
assert stat.S_IMODE(backup.stat().st_mode)==0o600
rehearsal=root/(run+'-rehearsal.json');a=json.loads(rehearsal.read_text())
assert a['migration']=='ok' and a['original_rows_preserved'] is True and a['integrity']=='ok' and a['feedback_lifecycle']=='ok' and a['old_api_rollback']=='ok'
assert a['post_migration_counts'][3]-a['original_counts'][3]==136
assert (a['canonical_packs'],a['canonical_questions'],a['newyear_questions'],a['total_graded'],a['practice_finished'])==(14,280,55,335,15)
with sqlite3.connect((root/('rehearsal-'+run)/'quiz.sqlite').as_uri()+'?mode=ro',uri=True) as db:
 practice=db.execute('select count(*),sum(server_score) from attempts where participant_id in (select id from participants where display_name="Release rehearsal") and status="finished"').fetchone()
assert practice==(15,335)
runtime=root/(run+'-candidate-runtime.json');gate=json.loads(runtime.read_text())
verify_runtime_receipt(gate,'quiz-master:quiz-2026.10.15-reader-06dfa0b',expected_packs=136,expected_questions=4084,expected_articles=279,expected_total_refs=160,expected_playable_refs=158)
durable=pathlib.Path('/var/lib/rancher/k3s/agent/images/quiz-2026.10.15-reader-06dfa0b.tar');assert h(durable)=='b8bd7bc5fb382f7860ce141d05e467b0b426429e4355212d44b3e50cbda61684'
values=root/(run+'-values.yaml');rendered=root/(run+'-rendered.yaml')
assert values.is_file() and rendered.is_file() and rendered.read_text().count('docker.io/library/quiz-master@sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af')==2
import os;usage=os.statvfs('/var/lib/rancher/k3s/agent/containerd');free=usage.f_bavail*usage.f_frsize;assert free*5>=usage.f_blocks*usage.f_frsize
print(json.dumps({'build_id':'quiz-2026.10.15-reader-06dfa0b','image':'sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af','values':values.name,'values_sha256':h(values),'backup_path':str(backup),'backup_sha256':h(backup),'backup_mode':'0600','backup_integrity':'ok','copied_db_rehearsal':a,'copied_db_rehearsal_sha256':h(rehearsal),'candidate_runtime':gate,'candidate_runtime_sha256':h(runtime),'helm_dryrun_sha256':h(rendered),'durable_archive':str(durable),'durable_archive_sha256':h(durable),'disk_free_bytes':free,'baseline_helm_revision':58,'status':'PREPARED_NOT_PUBLISHED'}))
PY
