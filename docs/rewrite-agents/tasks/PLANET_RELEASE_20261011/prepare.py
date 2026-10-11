from pathlib import Path
import ast, hashlib, json, shutil, subprocess

r=Path('C:/ap/quiz_master'); d=r/'.run/planet_release_20261011'
commit='d228c9ed66b29a5409df416c4566204fec47ab36'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=r,text=True).strip()==commit
build='quiz-2026.10.11-planets-'+commit[:7]
base=r/'.run/culture_encore_20261011/quiz-2026.10.11-encore-317b339'
stage=d/build; stage.mkdir()
for name in ['next','quizzes','metadata','chart','Dockerfile','nginx.conf','backup_sqlite.py','release-values.yaml','api']:
 src=base/name; dst=stage/name
 if src.is_dir(): shutil.copytree(src,dst)
 else: shutil.copyfile(src,dst)
q=Path('quizzes/Science/planet_paradoxes_20261010.json')
(stage/q).parent.mkdir(exist_ok=True); shutil.copyfile(r/q,stage/q)
pack=Path('next/content/planet-paradoxes-20261010')
assert (stage/pack).resolve().is_relative_to(stage.resolve())
if (stage/pack).exists(): shutil.rmtree(stage/pack)
shutil.copytree(r/pack,stage/pack)
shutil.copytree(r/'next/apps/quiz_app/build/web',stage/'web')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert {p.relative_to(r/'quizzes').as_posix():sha(p) for p in (r/'quizzes').rglob('*.json')}=={p.relative_to(stage/'quizzes').as_posix():sha(p) for p in (stage/'quizzes').rglob('*.json')}
assert sha(stage/'api')=='26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01'
catalog=json.loads((stage/'web/assets/assets/catalog.json').read_text())
assert len(catalog)==131 and sum(p['questions_count'] for p in catalog)==4008
articles=json.loads((stage/'web/assets/assets/study/question-articles.json').read_text())['articles']
assert len(articles)==206
for name in ['catalog.json','study/question-articles.json']:
 assert (stage/'web/assets/assets'/name).read_bytes()==(r/'next/apps/quiz_app/assets'/name).read_bytes()
assert build.encode() in (stage/'web/main.dart.js').read_bytes()
v=dict(buildId=build,commit=commit,local_build=True,packs=131,questions=4008,study_modules=6,study_questions=120,question_articles=206,api_sha256=sha(stage/'api'),main_dart_js_sha256=sha(stage/'web/main.dart.js'))
(stage/'web/version.json').write_text(json.dumps(v)+'\n')
s=(base/'rehearse.py').read_text()
s=s.replace("['cinema-encore-20261011','music-encore-20261011']", "['cinema-encore-20261011','music-encore-20261011','planet-paradoxes-20261010']")
# Fail before spawning if the shared staging port belongs to any process.
needle="p=start(root/'api')"; assert s.count(needle)==1
s=s.replace(needle,"with socket.socket() as probe: probe.bind(('127.0.0.1',18088))\n"+needle)
ast.parse(s); (stage/'rehearse.py').write_text(s,newline='\n')
s=(base/'cutover.sh').read_text()
s=s.replace('quiz-2026.10.11-encore-317b339',build).replace(r'2026\.10\.11-encore-317b339',r'2026\.10\.11-planets-'+commit[:7])
s=s.replace('sha256:528ac3e7e9fe05db1a7d8aa5d93013f72451734541fcebd7cdf668cf63adada9','sha256:3e9402747c700298eb756b927c7f028894ed5d3ed7efb9a83ca48b0f82a35636')
s=s.replace('a6497dff4c48ea5b7c2c23e34fdeb86868961ea1abeeb2cf426fe25ee614714e',v['main_dart_js_sha256'])
assert 'encore-317b339' not in s and s.count(v['main_dart_js_sha256'])==3
(stage/'cutover.sh').write_text(s,newline='\n')
(stage/'checksums.txt').write_text('\n'.join(sha(p)+'  '+p.relative_to(stage).as_posix() for p in sorted(stage.rglob('*')) if p.is_file() and p.name!='checksums.txt')+'\n')
archive=d/(build+'.tar.gz'); subprocess.run(['tar','-czf',str(archive),'-C',str(stage),'.'],check=True)
packet=dict(version=v,stage=str(stage),archive=str(archive),sha256=sha(archive),baseline_image='docker.io/library/quiz-master@sha256:3e9402747c700298eb756b927c7f028894ed5d3ed7efb9a83ca48b0f82a35636')
(d/'package.json').write_text(json.dumps(packet,indent=2)); print(json.dumps(packet,indent=2))
