from pathlib import Path
import json,hashlib,tarfile,importlib.util,subprocess,ast,copy
r=Path('C:/ap/quiz_master');w=r/'.run/home_alone_binding_20261013';d=r/'docs/rewrite-agents/tasks/HOME_ALONE_BINDING_20261013';spec=importlib.util.spec_from_file_location('pkg',d/'prepare_article_package.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);x=json.loads((w/'package-fixture-v1/package-preparation.json').read_text());stage=Path(x['stage']);archive=Path(x['archive']);assert m.sha256_file(archive)==x['archive_sha256'];reader=(w/'reader244-v1.json').read_bytes();source=x['frozen_commit']
original=m.git_bytes;bad=json.loads(reader);bad['articles'][0]['title_ru']+='changed';badraw=json.dumps(bad,ensure_ascii=False).encode();m.git_bytes=lambda repo,commit,rel:badraw if rel=='next/apps/quiz_app/assets/study/question-articles.json' else original(repo,commit,rel)
try:m.copy_and_check_web_inputs(r,source,stage,w/'fixture-production-web',w/'fixture-qa-web');raise AssertionError('Changed article accepted')
except RuntimeError as e:negative=str(e)
assert negative=='frozen Reader source differs from the approved deterministic 244-record input'
for line in (stage/'checksums.txt').read_text().splitlines():
 digest,path=line.split('  ',1);assert m.sha256_file(stage/path)==digest
with tarfile.open(archive,'r:gz') as t:
 members=t.getmembers()
 for member in members:
  payload=t.extractfile(member);relative=Path(*Path(member.name).parts[1:]);assert payload is not None and hashlib.sha256(payload.read()).hexdigest()==m.sha256_file(stage/relative)
text=(stage/'rehearse.py').read_text();tree=ast.parse(text);node=next(n for n in ast.walk(tree) if isinstance(n,ast.If) and isinstance(n.test,ast.Compare) and isinstance(n.test.left,ast.Name) and n.test.left.id=='qid' and any(isinstance(c,ast.Constant) and c.value=='home-alone-1-part-1' for c in n.test.comparators));code=compile(ast.Module(body=[node],type_ignores=[]),'generated-reader-binding-branch','exec')
articles=json.loads(reader)['articles'];bundle=json.loads((stage/'next/content/home-alone-1-part-1/bundle.json').read_text());refs=[ref for a in articles for ref in a['question_refs'] if ref['quiz_id']=='home-alone-1-part-1'];live={'quiz':bundle['quiz']};cases=[]
def check(label,qid,matches,live,expected):
 try:exec(code,{'qid':qid,'matches':matches,'live':live});passed=True
 except AssertionError:passed=False
 assert passed==expected,label;cases.append({'case':label,'accepted':passed})
check('home-alone-exact-two','home-alone-1-part-1',refs,live,True)
check('home-alone-missing','home-alone-1-part-1',refs[:1],live,False)
check('home-alone-duplicate','home-alone-1-part-1',[refs[0],refs[0]],live,False)
wrong=copy.deepcopy(refs);wrong[0]['revision_sha256']='0'*64;check('home-alone-stale-ref','home-alone-1-part-1',wrong,live,False)
wronglive=copy.deepcopy(live);wronglive['quiz']['questions'][0]['revision']['sha256']='0'*64;check('home-alone-live-stale','home-alone-1-part-1',refs,wronglive,False)
pb=json.loads((stage/'next/content/cinema-people-20261011/bundle.json').read_text());pr=[ref for a in articles for ref in a['question_refs'] if ref['quiz_id']=='cinema-people-20261011'];check('people-all28','cinema-people-20261011',pr,{'quiz':pb['quiz']},True);check('people-incomplete-not-weakened','cinema-people-20261011',pr[:2],{'quiz':pb['quiz']},False)
assert (stage/'nginx.conf').read_bytes()==(r/'next/infra/production/nginx.conf').read_bytes();assert (stage/'next/content/home-alone-1-part-1/bundle.json').read_bytes()==(r/'.run/culture_next7_release_root_20261013/package-v2/quiz-2026.10.13-culture-e437661/next/content/home-alone-1-part-1/bundle.json').read_bytes()
p={'producer_sha256':m.sha256_file(d/'prepare_article_package.py'),'fixture_archive_sha256':x['archive_sha256'],'fixture_file_members':len(members),'counts':x['counts'],'reader_fixture_sha256':hashlib.sha256(reader).hexdigest(),'exact_nginx_preserved':True,'exact25HomeAlone_bundle_preserved':True,'all_stage_archive_checksums_verified':True,'rehearsal_python_syntax_passed':True,'same_count_changed_article_rejected':negative,'generated_branch_cases':cases,'initial_harness_actual_exit':1,'initial_harness_failure':'Packaging completed and negative guard correctly rejected. Root harness incorrectly required hash/sha in descriptive error message; recovery validates exact actual rejection text. Producer unchanged.','recovery_actual_exit':0,'limits':['Fixture-only Git Reader substitution; all other frozen Git inputs and immutable template real','Old compiler output reused only as packaging fixture; archiveNOTdeployable','No staging DB/browser/image/Helm/production execution']}
(d/'package-root-proof.json').write_bytes(json.dumps(p,indent=2).encode()+b'\n');(w/'package-fixture-v1/DO_NOT_DEPLOY.txt').write_bytes(b'FIXTURE ONLY, substituted future Reader and old compiler output. NOT a release.\n');print(json.dumps(p))
