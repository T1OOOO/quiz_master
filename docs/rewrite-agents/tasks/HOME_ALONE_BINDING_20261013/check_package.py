from pathlib import Path
import importlib.util,json,shutil,subprocess,sys,hashlib,copy
r=Path('C:/ap/quiz_master');w=r/'.run/home_alone_binding_20261013';d=r/'docs/rewrite-agents/tasks/HOME_ALONE_BINDING_20261013';spec=importlib.util.spec_from_file_location('package',d/'prepare_article_package.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
assert m.sha256_file(d/'prepare_article_package.py')=='e20178598cd5a06c1e039fdfa31636dd20bd8daca9daf932042821d67cb469f6'
reader=(w/'reader244-v1.json').read_bytes();source=subprocess.check_output(['git','rev-parse','HEAD'],cwd=r,text=True).strip();archive=r/'.run/culture_next6_release_20261013/v8/quiz-2026.10.13-culture-328f2f8-v8.tar.gz'
prod=w/'fixture-production-web';qa=w/'fixture-qa-web'
for dst,old in [(prod,r/'.run/culture_next7_release_root_20261013/production-web'),(qa,r/'.run/culture_next7_release_root_20261013/qa-web')]:
 assert not dst.exists();shutil.copytree(old,dst);(dst/'assets/assets/study/question-articles.json').write_bytes(reader)
original=m.git_bytes
# Fixture only: a future frozen Reader is supplied while all other Git inputs remain real.
# Existing compiler bytes reused only to exercise packaging; never a new release claim.
def fixture_git_bytes(repo,commit,relative):
 return reader if relative=='next/apps/quiz_app/assets/study/question-articles.json' else original(repo,commit,relative)
m.git_bytes=fixture_git_bytes
out=w/'package-fixture-v1';assert not out.exists();sys.argv=['producer','--repo',str(r),'--frozen-commit',source,'--production-web',str(prod),'--qa-web',str(qa),'--output-root',str(out),'--prior-archive',str(archive)];m.main()
x=json.loads((out/'package-preparation.json').read_text());stage=Path(x['stage']);compile((stage/'rehearse.py').read_text(),str(stage/'rehearse.py'),'exec');assert x['counts']['reader_articles']==244
assert (stage/'nginx.conf').read_bytes()==(r/'next/infra/production/nginx.conf').read_bytes()
assert (stage/'next/content/home-alone-1-part-1/bundle.json').read_bytes()==(r/'.run/culture_next7_release_root_20261013/package-v2/quiz-2026.10.13-culture-e437661/next/content/home-alone-1-part-1/bundle.json').read_bytes()
text=(stage/'rehearse.py').read_text();assert "'q-ha1-p1-1'" in text and "'q-ha1-p1-2'" in text
# Fail closed on a same-count altered article, before asset copy.
bad=json.loads(reader);bad['articles'][0]['title_ru']+='changed';badraw=json.dumps(bad,ensure_ascii=False).encode();m.git_bytes=lambda repo,commit,rel:badraw if rel=='next/apps/quiz_app/assets/study/question-articles.json' else original(repo,commit,rel)
try:m.copy_and_check_web_inputs(r,source,stage,prod,qa);raise AssertionError('Changed article accepted')
except RuntimeError as e:negative=str(e)
assert 'hash' in negative.lower() or 'sha' in negative.lower()
p={'producer_sha256':m.sha256_file(d/'prepare_article_package.py'),'fixture_archive_sha256':x['archive_sha256'],'fixture_file_members':x['file_members'],'counts':x['counts'],'reader_fixture_sha256':hashlib.sha256(reader).hexdigest(),'exact_nginx_preserved':True,'exact25HomeAlone_bundle_preserved':True,'rehearsal_python_syntax_passed':True,'same_count_changed_article_rejected':negative,'limits':['Fixture-only Git Reader substitution; real other frozen Git inputs and immutable template','Previously compiled outputs reused only as packaging fixtures, not freshly compiled or deployable','No staging DB/browser/image/Helm/production execution']}
(d/'package-root-proof.json').write_bytes(json.dumps(p,indent=2).encode()+b'\n');(out/'DO_NOT_DEPLOY.txt').write_bytes(b'Fixture-only Reader substitution and reused compiler output. NOT a release package.\n');print('FIXTURE_ROOT_PROOF',json.dumps(p))
