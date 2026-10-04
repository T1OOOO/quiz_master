import hashlib
import json
import pathlib
import shutil
import subprocess

root = pathlib.Path('C:/ap/quiz_master')
base = root/'.run/thematic80/release'
stage = root/'.run/lotr-audit/release'
assert not stage.exists()
stage.mkdir()
parts = ['api','web','next','quizzes','chart','Dockerfile','nginx.conf','backup_sqlite.py','release-values.yaml']
for part in parts:
    src, dst = base/part, stage/part
    if src.is_dir(): shutil.copytree(src,dst)
    else: shutil.copyfile(src,dst)
packs = ['lotr','lotr-fellowship-100','lotr-two-towers-lore-100','lotr-return-king-bts-100']
for source in (root/'quizzes/Cinema/LOTR').glob('*.json'):
    shutil.copyfile(source,stage/'quizzes/Cinema/LOTR'/source.name)
for pack in packs:
    assert not (stage/'next/content'/pack).exists()
    shutil.copytree(root/'next/content'/pack,stage/'next/content'/pack)
shutil.copyfile(root/'next/apps/quiz_app/assets/catalog.json',stage/'web/assets/assets/catalog.json')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
commit = subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
build = 'quiz-2026.10.04-lotr-'+commit[:7]
version = {'buildId':build,'commit':commit,'packs':126,'questions':3958,'study_modules':6,
           'study_questions':120,'api_sha256':sha(stage/'api'),
           'main_dart_js_sha256':sha(stage/'web/main.dart.js')}
assert version['api_sha256']=='47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764'
assert version['main_dart_js_sha256']=='d2d48f232230a9153f27aac5ef4fdcadeea736b0785f30d8fd3a173df89592c1'
catalog = json.loads((stage/'web/assets/assets/catalog.json').read_text(encoding='utf-8'))
assert len(catalog)==126 and sum(p['questions_count'] for p in catalog)==3958
for pack in packs:
    for name in ['bundle.json','draft.json','manifest.json']:
        assert sha(root/'next/content'/pack/name)==sha(stage/'next/content'/pack/name)
# Check every other raw quiz remains exactly the previously deployed revision.
changed = set(p.name for p in (root/'quizzes/Cinema/LOTR').glob('*.json'))
for p in (base/'quizzes').rglob('*.json'):
    if p.parent.name=='LOTR' and p.name in changed: continue
    assert sha(p)==sha(stage/p.relative_to(base))
(stage/'web/version.json').write_bytes((json.dumps(version,separators=(',',':'))+'\n').encode())
script_before = (base/'release-thematic.sh').read_text(encoding='utf-8')
assert script_before.count('thematic-')==1
assert script_before.count('19b8134c9d85614c056d4b1f3d181ac504d8e0ec124e4bdf3d80d8e4c8275dbb')==1
script = script_before.replace('thematic-','lotr-').replace(
    '19b8134c9d85614c056d4b1f3d181ac504d8e0ec124e4bdf3d80d8e4c8275dbb',
    'cdfd63ef1d2027e963606a447f8296559848a703219c4a415f86f61395516c46')
assert script!=script_before and 'thematic-' not in script
assert script.count('cdfd63ef1d2027e963606a447f8296559848a703219c4a415f86f61395516c46')==1
(stage/'release-lotr.sh').write_bytes(script.encode())
parts += ['release-lotr.sh']
files = []
for part in parts:
    p = stage/part
    files.extend(sorted(p.rglob('*')) if p.is_dir() else [p])
(stage/'checksums.txt').write_bytes(('\n'.join(f'{sha(p)}  {p.relative_to(stage).as_posix()}'
    for p in files if p.is_file())+'\n').encode())
archive = root/'.run/lotr-audit'/f'{build}.tar.gz'
subprocess.run(['tar','-czf',str(archive),'-C',str(stage),*parts,'checksums.txt'],check=True)
summary = {'version':version,'archive':str(archive),'sha256':sha(archive),'bytes':archive.stat().st_size}
(root/'.run/lotr-audit/package.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary))
