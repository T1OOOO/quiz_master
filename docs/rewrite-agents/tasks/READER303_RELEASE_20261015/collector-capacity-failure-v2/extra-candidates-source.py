from pathlib import Path
import json,stat,os,subprocess
base=Path('/opt/quiz-master/releases');items=[]
for p in sorted(base.iterdir()):
 s=p.lstat()
 if stat.S_ISREG(s.st_mode) and not p.name.endswith('.tar.gz'):items.append({'name':p.name,'bytes':s.st_size,'mode':stat.S_IMODE(s.st_mode),'mtime_ns':s.st_mtime_ns,'dev':s.st_dev,'ino':s.st_ino})
print(json.dumps({'regular_non_tar':items,'directories_du':subprocess.check_output(['du','-sk',*[str(p) for p in sorted(base.iterdir()) if p.is_dir() and not p.is_symlink()]],text=True)}))
