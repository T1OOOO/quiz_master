set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
python3 - <<'OWNED_ALLOCATION'
import pathlib,subprocess,json,os
root=pathlib.Path('/opt/quiz-master/releases')
rows=[]
for p in sorted(root.iterdir()):
 if p.name.startswith('quiz-') and not p.is_symlink():
  rows.append(dict(name=p.name,directory=p.is_dir(),allocated_bytes=int(subprocess.check_output(['du','-s','-B1',str(p)]).split()[0])))
print(json.dumps(dict(owned_releases=rows)))
print(json.dumps(dict(docker_disk_summary=subprocess.check_output(['docker','system','df'],text=True))))
print(json.dumps(dict(owned_backups_allocated=int(subprocess.check_output(['du','-s','-B1','/opt/quiz-master/backups']).split()[0]),owned_durable_archives_allocated=int(subprocess.check_output(['du','-s','-B1','/var/lib/rancher/k3s/agent/images']).split()[0]))))
OWNED_ALLOCATION
