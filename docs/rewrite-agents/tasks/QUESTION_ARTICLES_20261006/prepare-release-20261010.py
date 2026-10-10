from pathlib import Path
import hashlib,json,shutil,subprocess,sys
repo=Path('C:/ap/quiz_master');commit=sys.argv[1]
assert len(commit)==40 and all(c in '0123456789abcdef' for c in commit)
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==commit
build='quiz-2026.10.10-articles-'+commit[:7]
out=repo/'.run/feedback_triage_20261006/releases';out.mkdir(exist_ok=True)
stage=out/build;stage.mkdir()
base=repo/'.run/feedback_release/quiz-2026.10.06-feedback-e0f89cf'
for name in ['next','quizzes','metadata','chart','Dockerfile','nginx.conf','backup_sqlite.py','release-values.yaml']:
 src=base/name;dst=stage/name
 if src.is_dir():shutil.copytree(src,dst)
 else:shutil.copyfile(src,dst)
shutil.copyfile(repo/'.run/feedback_triage_20261006/api-oct10',stage/'api')
shutil.copytree(repo/'next/apps/quiz_app/build/web',stage/'web')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(stage/'api')=='26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01'
articles=json.loads((stage/'web/assets/assets/study/question-articles.json').read_text(encoding='utf-8'))['articles']
assert articles and all(a['status']=='accepted' for a in articles)
assert articles==json.loads((repo/'next/apps/quiz_app/assets/study/question-articles.json').read_text(encoding='utf-8'))['articles']
catalog=json.loads((stage/'web/assets/assets/catalog.json').read_text(encoding='utf-8'))
assert len(catalog)==126 and sum(p['questions_count'] for p in catalog)==3958
study=json.loads((stage/'web/assets/assets/study/catalog.json').read_text(encoding='utf-8'))
assert len(study['modules'])==6 and sum(len(m['questions']) for m in study['modules'])==120
v=dict(buildId=build,commit=commit,local_build=True,packs=126,questions=3958,study_modules=6,study_questions=120,question_articles=len(articles),api_sha256=sha(stage/'api'),main_dart_js_sha256=sha(stage/'web/main.dart.js'))
(stage/'web/version.json').write_text(json.dumps(v)+'\n',encoding='utf-8')
rehearse=(repo/'.run/feedback_release/rehearse-validenv.py').read_text()
rehearse=rehearse.replace('quiz-2026.10.05-quizipedia-486df89','quiz-2026.10.06-feedback-e0f89cf').replace('2026-10-06T00:00:00Z','2026-10-10T00:00:00Z')
(stage/'rehearse.py').write_text(rehearse,encoding='utf-8')
script=(base/'release-feedback.sh').read_text()
script=script.replace(r'2026\.10\.06-feedback-',r'2026\.10\.10-articles-').replace('sha256:91c9182c831e9b3b61409e1020f149f14a6310aef98b974a7d764a7c3dc248d2','sha256:de8c71716add4f88aa678abb8a7b05e1a649b3c94f86befd3a406c94662af4e2')
script=script.replace('sha256sum -c checksums.txt', '''test "$(kubectl get pvc quiz-data -n quiz-master -o jsonpath='{.metadata.uid}')" = 7fc2428f-4146-4c78-a26d-2347d9f3b7bf
sha256sum -c checksums.txt
chmod 755 api''')
(stage/'release-articles.sh').write_text(script,encoding='utf-8')
files=[p for p in stage.rglob('*') if p.is_file() and p.name!='checksums.txt']
(stage/'checksums.txt').write_text('\n'.join(sha(p)+'  '+p.relative_to(stage).as_posix() for p in files)+'\n',encoding='utf-8')
archive=out/(build+'.tar.gz');subprocess.run(['tar','-czf',str(archive),'-C',str(stage),'.'],check=True)
packet=dict(version=v,archive=str(archive),sha256=sha(archive),bytes=archive.stat().st_size)
(out/'package.json').write_text(json.dumps(packet,indent=2),encoding='utf-8');print(json.dumps(packet,indent=2))
