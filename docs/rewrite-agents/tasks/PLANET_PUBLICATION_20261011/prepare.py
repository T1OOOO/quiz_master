from pathlib import Path
import json,subprocess,shutil,hashlib
r=Path('C:/ap/quiz_master');d=r/'.run/planet_publication_20261011';exe=r/'.run/quizctl-culture-20261011.exe'
src=r/'study/drafts/planet-paradoxes-20261010.legacy.json';dest=r/'quizzes/Science/planet_paradoxes_20261010.json'
old=json.loads((d/'bundle-before.json').read_text()); assert old['quiz']['quiz_id']=='planet-paradoxes-20261010'
assert not dest.exists(); dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dest)
assert dest.read_bytes()==src.read_bytes()
def ctl(*args):subprocess.run([str(exe),*args],cwd=r,check=True)
temp=d/'canonical';ctl('import','--in','quizzes/Science/planet_paradoxes_20261010.json','--out',str(temp))
ctl('validate','--in',str(temp/'draft.json'))
draft=json.loads((temp/'draft.json').read_text())
for new,before in zip(draft['questions'],old['quiz']['questions'],strict=True):
 assert new['question_id']==before['question_id']
 for key in ['stem','options','answer_kind','difficulty','difficulty_level']:assert new[key]==before[key],key
 assert new['grading']==old['private_grading'][new['question_id']]
for name in ['draft.json','manifest.json']:shutil.copyfile(temp/name,r/'next/content/planet-paradoxes-20261010'/name)
print('PASS: served source byte-identical; ten stems/options/grading/difficulty unchanged')
