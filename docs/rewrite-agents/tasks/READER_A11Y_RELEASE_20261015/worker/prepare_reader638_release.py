"""Prepare a hash-bound Reader successor archive; never execute or publish it."""
from __future__ import annotations
import argparse, hashlib, importlib.util, json, shutil
from pathlib import Path, PurePosixPath
from verify_reader638_candidate import load_house as runtime_house

BASELINE_BUILD='quiz-2026.10.14-library-09b19cc'
BASELINE_ARCHIVE_SHA256='7d9d6c64763a64b811d942a9df3cdc489a4fc39a11ac8d628165e0636649791f'
BASELINE_IMAGE='docker.io/library/quiz-master@sha256:4878f824f4b0fb23fa20a8f246541ca4dfa7a1750715f64176cfba4faead0a50'
BASELINE_CUTOVER_IMAGE='docker.io/library/quiz-master@sha256:ac4fd7624a22762d2c169c748b8553e1fd31247db7125038b0c72e0afec9bdd4'
PVC_UID='7fc2428f-4146-4c78-a26d-2347d9f3b7bf'
API_SHA256='f4d69555623aab2b8e1468fccb65256abefc9823d65214799b7e1475d4d9c850'
NGINX_SHA256='e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc'
FROZEN_COMMIT='63847958fdde804f97366e1be04645269a4d42cc'; BUILD_ID='quiz-2026.10.15-reader-6384795'
READER_SOURCE='next/apps/quiz_app/assets/study/question-articles.json'; CATALOG_SOURCE='next/apps/quiz_app/assets/catalog.json'
FROZEN_ASSETS={'catalog':CATALOG_SOURCE,'reader':READER_SOURCE,'library_background':'next/apps/quiz_app/assets/library-bg-v1.png',
              **{name.replace('-','_'):f'next/apps/quiz_app/assets/categories/{name}.png' for name in ('geography-capitals','geography-flags','mythology-greece','history-art')}}
ARTICLE_IDS={'question:greek-002'}
TAXONOMY=('qm-tags-v1','07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151','98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c')

def require(ok,msg):
 if not ok: raise RuntimeError(msg)
def digest(path):
 with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(path): return json.loads(Path(path).read_text(encoding='utf-8'))
def rows(value): return value['articles'] if isinstance(value,dict) and 'articles' in value else value
def house():
 p=Path(__file__).parents[2]/'MIXED_RELEASE_20261014/worker/prepare_lotr_package.py'; s=importlib.util.spec_from_file_location('reader_house_prepare',p); assert s and s.loader; m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
def runtime_verifier_path(): return Path(__file__).parents[2]/'MIXED_RELEASE_20261014/worker/verify_candidate_runtime.py'
def bound_json(pins,key):
 entry=pins[key]; path=Path(entry['path']); require(digest(path)==entry['sha256'],f'{key} hash does not match its pin'); return read(path)

def file_tree(root):
 root=Path(root); require(root.is_dir() and not root.is_symlink(),'web root must be a real directory'); root=root.resolve(); result={}
 for path in root.rglob('*'):
  require(not path.is_symlink(),'web tree symlink is forbidden')
  if path.is_file():
   relative=path.relative_to(root).as_posix(); pure=PurePosixPath(relative)
   require(not pure.is_absolute() and '..' not in pure.parts and '\\' not in relative,'unsafe web tree path')
   result[relative]=digest(path)
 return result

def verify_web_tree(record,label,expected):
 require(record.get('root')==str(Path(expected)),'web tree root differs from command input')
 expected_hashes=record.get('file_sha256'); require(isinstance(expected_hashes,dict) and record.get('file_count')==len(expected_hashes),'web tree manifest is incomplete')
 require(file_tree(expected)==expected_hashes,f'{label} web tree differs from frozen manifest')

def verify_reader_delta(prior,current,browser,helper):
 prior,current=rows(prior),rows(current); old={x['id']:x for x in prior}; new={x['id']:x for x in current}
 require(len(prior)==len(old)==278 and sum(len(x.get('question_refs',[])) for x in prior)==159,'prior Reader must be exact 278/159')
 require(len(current)==len(new)==279 and set(new)-set(old)==ARTICLE_IDS,'Reader additions or duplicates differ')
 require(all(new[k]==v for k,v in old.items()),'one of prior 278 Reader articles changed')
 refs=new['question:greek-002'].get('question_refs',[])
 expected=('prep-greek-mythology','greek-002','e441297ab473743e34633a90a13aa4a1f86b5e17a062185a9772a1ce5e87fe7e')
 require(len(refs)==1 and tuple(refs[0].get(k) for k in ('quiz_id','question_id','revision_sha256'))==expected,'Greek002 reference differs')
 proof=browser.get('articles',[])
 require(len(proof)==1 and proof[0].get('article_id')=='question:greek-002' and proof[0].get('question_id')==expected[1] and proof[0].get('revision_sha256')==expected[2],'browser Greek002 reference differs')
 require(browser.get('actual_visible_score')=='19/20' and browser.get('controlled_real_go_fixture_questions')==20 and proof[0].get('all_four_headed_sections_accessible') is True and proof[0].get('empty_textareas')==0 and proof[0].get('source_links_count')==5,'fresh browser Reader checks missing')
 total=sum(len(x.get('question_refs',[])) for x in current)
 allrefs={(r.get('quiz_id'),r.get('question_id'),r.get('revision_sha256')) for x in current for r in x.get('question_refs',[])}
 noncatalog={(x['quiz_id'],x['question_id'],x['revision_sha256']) for x in runtime_house().NONCATALOG_READER_REFS}
 revisions=helper.frozen_revision_map(Path(__file__).parents[5],FROZEN_COMMIT)
 require(total==len(allrefs)==160 and len(noncatalog)==2 and noncatalog<=allrefs and helper.count_exact_article_bindings(current,revisions)==158,'Reader playable/noncatalog references or duplicates differ')
 return {'packs':136,'questions':4084,'reader_articles':279,'total_refs':160}


def verify_inputs(pins,helper):
 require(pins['frozen_commit']==FROZEN_COMMIT and pins['baseline_image']==BASELINE_IMAGE,'actual58 source/image pin differs')
 require(pins['api_sha256']==API_SHA256 and pins['nginx_sha256']==NGINX_SHA256 and pins['pvc_uid']==PVC_UID,'actual58 API/Nginx/PVC pin differs')
 for key,label in [('source_review','Flutter UI source'),('reader_review','Greek002 Reader source')]:
  helper.require_actual_acceptance(bound_json(pins,key),label)
 build=bound_json(pins,'build_receipt')
 require(build.get('frozen_source')==FROZEN_COMMIT and build.get('build_id')==BUILD_ID,'build receipt source differs')
 checks={row['label']:row for row in build['checks']}
 require(len(build['checks'])==2 and set(checks)=={'production','qa'},'exact two actual builds required')
 for label,key in (('production','production_web'),('qa','qa_web')):
  row=checks[label]
  require(row.get('actual_exit')==0 and row.get('frozen_assets_byte_identical') is True and Path(row['output']).resolve()==Path(pins[key]).resolve(),'actual build output differs')
  require(digest(Path(pins[key])/'main.dart.js')==row['main_dart_js_sha256'],'actual build JS differs')
 browser=bound_json(pins,'browser_proof'); require(browser.get('status')=='VERIFIED' and browser.get('frozen_source')==FROZEN_COMMIT and browser.get('build_id')==BUILD_ID,'browser proof differs')
 require(browser.get('qa_web_main_sha256')==checks['qa']['main_dart_js_sha256'],'browser build differs')
 verify_browser_cleanup(browser)
 trees=bound_json(pins,'web_trees'); require(trees.get('schema_version')=='qm-frozen-web-trees/v1' and trees.get('frozen_source')==FROZEN_COMMIT and trees.get('build_id')==BUILD_ID,'frozen web trees provenance differs')
 for label,key in (('production','production_web'),('qa','qa_web')): verify_web_tree(trees['trees'][label],label,pins[key])
 require(trees['trees']['production'].get('frozen_catalog_reader_bytes_identical') is True and trees['trees']['qa'].get('frozen_catalog_reader_bytes_identical') is True,'frozen source asset identity missing')
 frozen=pins['frozen_assets']; require(set(frozen)==set(FROZEN_ASSETS),'exact frozen catalog/Reader/artwork pins are required')
 for name,relative in FROZEN_ASSETS.items():
  entry=frozen[name]; source=Path(entry['path']); payload=helper.git_bytes(Path(__file__).parents[5],FROZEN_COMMIT,relative)
  require(source.read_bytes()==payload and digest(source)==entry['sha256'],'frozen Git source asset differs')
  require(digest(Path(pins['production_web'])/'assets/assets'/relative.split('assets/',1)[1])==entry['sha256'],'production source asset differs'); require(digest(Path(pins['qa_web'])/'assets/assets'/relative.split('assets/',1)[1])==entry['sha256'],'QA source asset differs')
 require(pins['current_reader']['sha256']==frozen['reader']['sha256'] and Path(pins['current_reader']['path']).read_bytes()==Path(frozen['reader']['path']).read_bytes(),'current Reader differs from frozen source')
 controller_review=bound_json(pins,'controller_review')
 expected=pins['controller_source_sha256']; own=Path(__file__).parent
 known=controller_sources()
 require(set(expected)=={str(path.resolve()) for path in known},'exact controller/dependency source pins required')
 require(all(digest(path)==expected[str(path.resolve())] for path in known),'controller dependency changed after review')
 helper.verify_controller_review(controller_review,expected)
 require(Path(pins['production_web']).resolve()!=Path(pins['qa_web']).resolve(),'QA output cannot be production input')
 return browser

def verify_prior_reader(stage,prior_path):
 require((stage/READER_SOURCE).read_bytes()==prior_path.read_bytes(),'prior Reader pin does not match extracted actual58 archive')

def controller_sources():
 own=Path(__file__).parent
 return ({own/name for name in ('prepare_reader638_release.py','verify_reader638_candidate.py','test_reader638_release.py','prepare_reader638_remote.py','test_prepare_reader638_remote.py','reader638_guard.py')} |
         {own.parents[1]/'MIXED_RELEASE_20261014/worker'/name for name in ('prepare_lotr_package.py','verify_candidate_runtime.py','test_verify_candidate_runtime.py','prepare_remote_mixed.py')})

def verify_browser_cleanup(browser):
 require(browser.get('browser_inactive') is True and browser.get('ports_closed')==[19090,19093],'browser/ports remain active')
 if browser.get('browser_close_actual_exit')==0: return
 cleanup=browser.get('browser_cleanup',{})
 require(browser.get('browser_close_actual_exit')==1 and cleanup.get('actual_cleanup_exit')==0 and
         cleanup.get('session')=='reader638-local-mixed' and cleanup.get('namespace')=='quiz-master' and
         cleanup.get('inactive') is True and cleanup.get('native_processes_absent') is True and
         cleanup.get('foreign_processes_changed') is False and cleanup.get('ports_closed')==[19090,19093] and
         cleanup.get('verified_daemon_pid') in cleanup.get('checked_owned_pids',[]) and
         cleanup.get('previously_verified_chrome_pid') in cleanup.get('checked_owned_pids',[]) and
         cleanup.get('owned_go_cleanup',{}).get('stop_seen') is True,
         'failed browser close lacks verified exact owned-process quiescence')

def verify_catalog(stage):
 catalog=read(stage/CATALOG_SOURCE); require(isinstance(catalog,list) and len(catalog)==136 and len({x.get('quiz_id') for x in catalog})==136 and sum(x.get('questions_count',0) for x in catalog)==4084,'catalog differs from 136/4084')

def install_staging_revisions(stage,helper):
 expected,_=helper.expected_staging_revisions_from_bundles(read(stage/'runtime-bundles.json'),BUILD_ID)
 helper.write_json_lf(stage/'expected-staging-revisions.json',expected)

def verify_staging_revisions(stage,helper):
 expected,_=helper.expected_staging_revisions_from_bundles(read(stage/'runtime-bundles.json'),BUILD_ID)
 require(read(stage/'expected-staging-revisions.json')==expected,'staging revisions bind a different release root')

def verify_preserved(before,stage):
 after={p.relative_to(stage).as_posix():digest(p) for p in stage.rglob('*') if p.is_file()}; changed={p for p in before if before[p]!=after.get(p)}|set(after)-set(before)
 allowed={READER_SOURCE,'cutover.sh','rehearse.py','verify_candidate_runtime.py','expected-staging-revisions.json','checksums.txt','web/version.json'}; require({p for p in changed if not p.startswith('web/')}<=allowed,'Reader-only stage altered nonweb data/API/Nginx/schema bytes')
 require(digest(stage/'api')==API_SHA256 and digest(stage/'nginx.conf')==NGINX_SHA256,'Reader-only stage altered API/Nginx')

def install_runtime_verifier(stage,helper,production_hash):
 from reader638_guard import preflight_shell
 shutil.copyfile(runtime_verifier_path(),stage/'verify_candidate_runtime.py')
 helper.inject_version(stage,{'packs':136,'questions':4084,'reader_articles':279},production_hash)
 cutover=stage/'cutover.sh'; text=cutover.read_text(encoding='utf-8')
 require(f'quiz_build={BASELINE_BUILD}' in text and BASELINE_CUTOVER_IMAGE in text and PVC_UID in text and 'helm template' in text and 'PREPARED build=' in text and 'helm upgrade' not in text,'archived58 prepare-only controls differ')
 def once(old,new):
  nonlocal text
  require(text.count(old)==1,'archived58 control contract differs: '+old)
  text=text.replace(old,new)
 once(BASELINE_CUTOVER_IMAGE,BASELINE_IMAGE)
 once(f'quiz_build={BASELINE_BUILD}',f'quiz_build={BUILD_ID}')
 once('--expected-packs 136 --expected-questions 4084 --expected-reader-articles 278 --expected-reader-total-refs 159 --expected-reader-playable-refs 157','--expected-packs 136 --expected-questions 4084 --expected-reader-articles 279 --expected-reader-total-refs 160 --expected-reader-playable-refs 158')
 oldhash='0c34332e394327aafa3ab6d158d35cf898931aac548af7a2763221d73ebd24cd'
 require(text.count(oldhash)==3,'archived58 JS guard count differs');text=text.replace(oldhash,production_hash)
 start=text.find("python3 - \"$quiz_build\" <<'PY'\n");end=text.find('\nPY',start);require(start>=0 and end>=0,'archived58 metadata gate missing')
 gate=f'''python3 - "$quiz_build" <<'PY'
from pathlib import Path
import json,sys
build=sys.argv[1];meta=json.loads(Path('web/version.json').read_text())
assert build=='{BUILD_ID}' and meta['buildId']==build
assert meta['commit']==meta['source_commit']=='{FROZEN_COMMIT}'
assert (meta['packs'],meta['questions'],meta['question_articles'])==(136,4084,279)
assert meta['api_sha256']=='{API_SHA256}' and meta['main_dart_js_sha256']=='{production_hash}'
assert (meta['taxonomy_id'],meta['taxonomy_sha256'],meta['taxonomy_file_sha256'])=={TAXONOMY!r}
PY'''
 text=text[:start]+gate+text[end+3:]
 # The same baseline health/disk guard runs at each image preparation boundary.
 definition='quiz_preflight() {\n'+preflight_shell()+'\n}\n'
 once('set -euo pipefail\n','set -euo pipefail\n'+definition)
 once('flock -n 9\n','flock -n 9\nquiz_preflight\n')
 once('docker build --network=none','quiz_preflight\ndocker build --network=none')
 once('quiz_archive="/var/lib/rancher/k3s/agent/images/$quiz_build.tar"','quiz_preflight\nquiz_archive="/var/lib/rancher/k3s/agent/images/$quiz_build.tar"')
 cutover.write_bytes(text.encode('utf-8'))
 rehearsal=stage/'rehearse.py';body=rehearsal.read_text(encoding='utf-8')
 old_root='/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce'
 old_checks='37c59305cf3b6439689ac27282b79a869777119ac6cb504b4b20618f9a4f4e0c'
 require(body.count(old_root)==1 and body.count(old_checks)==1 and API_SHA256 in body,'archived58 rollback controls differ')
 body=body.replace(old_root,f'/opt/quiz-master/releases/{BASELINE_BUILD}').replace(old_checks,digest(stage/'checksums.txt'))
 require('assert len(matches)==12 and len(expected_questions)==20' in body,'preserved mixed12/20 rehearsal missing')
 rehearsal.write_bytes(body.encode('utf-8'));(stage/'api').chmod(0o755);cutover.chmod(0o755)


def prepare(pins,archive,output):
 helper=house(); helper.BASELINE_BUILD=BASELINE_BUILD; helper.BASELINE_ARCHIVE_SHA256=BASELINE_ARCHIVE_SHA256; helper.BUILD_ID=BUILD_ID; helper.TARGET_SOURCE=FROZEN_COMMIT; helper.TARGET_API_SHA256=API_SHA256
 browser=verify_inputs(pins,helper); helper.verify_safe_archive(archive); helper.require_new_output_root(output)
 prior_path=Path(pins['prior_reader']['path']); prior=bound_json(pins,'prior_reader'); current=bound_json(pins,'current_reader'); counts=verify_reader_delta(prior,current,browser,helper)
 helper.extract_immutable(archive,output/BUILD_ID); stage=output/BUILD_ID; helper.verify_checksum_manifest(stage); target=stage/READER_SOURCE
 verify_prior_reader(stage,prior_path)
 before={p.relative_to(stage).as_posix():digest(p) for p in stage.rglob('*') if p.is_file()}; shutil.rmtree(stage/'web'); shutil.copytree(pins['production_web'],stage/'web'); target.write_bytes(Path(pins['current_reader']['path']).read_bytes())
 production_hash=digest(stage/'web/main.dart.js'); install_runtime_verifier(stage,helper,production_hash); install_staging_revisions(stage,helper); verify_staging_revisions(stage,helper); verify_catalog(stage); verify_preserved(before,stage); helper.write_checksums(stage); artifact,sha,members=helper.archive_and_verify(stage,output)
 result={'status':'PREPARED_NOT_EXECUTED','build_id':BUILD_ID,'frozen_commit':FROZEN_COMMIT,'archive':str(artifact),'archive_sha256':sha,'file_members':members,'counts':{**counts,'refs':{'total':160,'playable':158,'noncatalog':2}},'qa_checked_not_packaged':pins['qa_web']}; (output/'package-preparation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8'); return result
def main():
 p=argparse.ArgumentParser(); p.add_argument('--pins',type=Path,required=True); p.add_argument('--prior-archive',type=Path,required=True); p.add_argument('--output-root',type=Path,required=True); a=p.parse_args(); print(json.dumps(prepare(read(a.pins),a.prior_archive,a.output_root),ensure_ascii=False))
if __name__=='__main__': main()
