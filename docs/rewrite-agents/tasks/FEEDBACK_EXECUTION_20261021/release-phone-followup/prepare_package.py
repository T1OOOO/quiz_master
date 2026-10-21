"""Freeze an offline web-only candidate; remote capacity is checked only by release_executor."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
import release_executor as release

API_SOURCE='7f8344d638e2079d3b47b74972754a3425419791'
CANONICAL_CONTENT_EXCEPTION={
 'next/content/prep-capitals-1/draft.json':'68f61b50d06f5ddeddc23f52c0386483c908fd7d9748a4a5c888884679832985',
 'next/content/prep-capitals-1/bundle.json':'f6372d69a929dc8ddb8d623668a0cf0c6672a820179888e7bb3634b87e6af8ae',
 'next/content/prep-capitals-1/manifest.json':'755692aff8a11be862e53c8f074637124db6573675d6ccd7e6cfa67c4603ade1',
 'next/content/prep-capitals-1/.gitattributes':'5c0ccd4346d40a9a257042b8a485544d843749688aee93ed1bcf52679a9a2441',
}


def validate_runtime_deltas(runtime_changed, content_changed):
 if runtime_changed:
  raise release.GuardError('web-only source changed API, server, or quiz bytes')
 if content_changed != set(CANONICAL_CONTENT_EXCEPTION):
  raise release.GuardError('source changed unapproved next/content paths')


def validate_canonical_content_exception(source, content_changed, expected=CANONICAL_CONTENT_EXCEPTION):
 if content_changed != set(expected):
  raise release.GuardError('source changed unapproved next/content paths')
 actual={}
 for name,digest in expected.items():
  path=source/name
  if not path.is_file() or release.sha256_file(path)!=digest:
   raise release.GuardError('reviewed canonical nonruntime content hash differs: '+name)
  actual[name]=digest
 return {'base_source_revision':API_SOURCE,'nonruntime':True,'paths':actual,'copied_into_package':False}


def changed_paths(source, paths):
 text=subprocess.check_output(['git','diff','--name-only',API_SOURCE,'--',*paths],cwd=source,text=True)
 return {line.strip().replace('\\','/') for line in text.splitlines() if line.strip()}


def validate_source_freeze(source):
 scoped=('next/apps/quiz_app','next/server','next/content','quizzes','deploy/helm/quiz-master','docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/release-phone-followup')
 if subprocess.check_output(['git','status','--porcelain','--untracked-files=all','--',*scoped],cwd=source,text=True):
  raise release.GuardError('source must be clean')
 runtime=changed_paths(source,('next/server','quizzes'))
 content=changed_paths(source,('next/content',))
 validate_runtime_deltas(runtime,content)
 return validate_canonical_content_exception(source,content)

def tree(path): return release.hash_tree(path)
def copy_verified(source,destination,expected):
 if tree(source)!=expected: raise release.GuardError('baseline tree checksum differs: '+source.name)
 shutil.copytree(source,destination)
def main():
 p=argparse.ArgumentParser(description=__doc__)
 for name in ('source','destination','baseline-package','baseline-inputs','baseline-receipt'): p.add_argument('--'+name,type=Path,required=True)
 p.add_argument('--preflight',type=Path)
 a=p.parse_args(); source=a.source.resolve(); baseline=a.baseline_package.resolve(); dest=a.destination.resolve()
 if a.preflight is not None: release.read_preflight(a.preflight)
 commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip()
 canonical_exception=validate_source_freeze(source)
 if dest.exists(): raise release.GuardError('destination must be fresh')
 version=json.loads((baseline/'web/version.json').read_text(encoding='utf-8'))
 if version.get('buildId')!=release.BASE_BUILD_ID or version.get('api_sha256')!=release.API_SHA256 or version.get('source_api_commit')!=API_SOURCE: raise release.GuardError('baseline package identity differs')
 manifest=json.loads(a.baseline_inputs.read_text(encoding='utf-8'))
 receipt=json.loads(a.baseline_receipt.read_text(encoding='utf-8'))
 release.validate_baseline_lineage(manifest,receipt)
 if manifest.get('target_api_sha256')!=release.API_SHA256: raise release.GuardError('baseline manifest API differs')
 for name in ('web','chart','quizzes','private'):
  if tree(baseline/name)!=manifest.get(name): raise release.GuardError('retained baseline inputs changed: '+name)
 if set(manifest.get('support',{})) != set(release.SUPPORT): raise release.GuardError('baseline support set differs')
 for name in release.SUPPORT:
  if release.sha256_file(baseline/name)!=manifest['support'][name]: raise release.GuardError('baseline support changed: '+name)
 if release.sha256_file(baseline/'web/version.json')!=manifest.get('version_sha256'): raise release.GuardError('baseline version changed')
 if release.sha256_file(baseline/'catalog.json')!=manifest.get('catalog_sha256'): raise release.GuardError('baseline catalog changed')
 if release.sha256_file(baseline/'quiz-closure.json')!=manifest.get('quiz_closure_sha256'): raise release.GuardError('baseline quiz closure file changed')
 closure=json.loads((baseline/'quiz-closure.json').read_text(encoding='utf-8')); quizzes=tree(baseline/'quizzes')
 if len(quizzes)!=165 or quizzes!=closure.get('candidate'): raise release.GuardError('baseline quiz closure differs')
 if release.sha256_file(baseline/'api')!=release.API_SHA256: raise release.GuardError('unchanged API bytes differ')
 web=source/'next/apps/quiz_app/build/web'; js=(web/'main.dart.js').read_bytes(); build='quiz-2026.10.21-feedback-'+commit[:8]
 if build.encode() not in js or b'https://quiz.kotopedia.org' not in js: raise release.GuardError('compiled application identity differs')
 if b'QM_BUILD_ID' in js or b'QM_API_BASE_URL' in js: raise release.GuardError('unresolved production define name in compiled application')
 dest.mkdir()
 approved=source/'docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/release-phone-followup/asset-delta-allowlist.json'
 if not approved.is_file(): raise release.GuardError('missing separately approved asset delta allowlist')
 shutil.copy2(approved,dest/release.ASSET_ALLOWLIST_NAME)
 shutil.copytree(web,dest/'web'); shutil.copytree(source/'deploy/helm/quiz-master',dest/'chart')
 # The delta image retains this existing fallback font even when Flutter's clean
 # output omits it. Preserve exactly that inherited byte in the full-image closure.
 font=Path('assets/fonts/fallback/Roboto-Regular.ttf')
 if not (dest/'web'/font).exists():
  if release.sha256_file(baseline/'web'/font)!='79e851404657dac2106b3d22ad256d47824a9a5765458edb72c9102a45816d95': raise release.GuardError('inherited fallback font changed')
  (dest/'web'/font).parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(baseline/'web'/font,dest/'web'/font)
 # Retain its existing registration, so ordinary text needs no Google Fonts fetch.
 fonts=dest/'web/assets/FontManifest.json'
 entries=json.loads(fonts.read_text(encoding='utf-8'))
 if not any(row.get('family')=='Roboto' for row in entries):
  entries.append({'family':'Roboto','fonts':[{'asset':'fonts/fallback/Roboto-Regular.ttf'}]})
  if entries==json.loads((baseline/'web/assets/FontManifest.json').read_text(encoding='utf-8')): shutil.copy2(baseline/'web/assets/FontManifest.json',fonts)
  else: fonts.write_text(json.dumps(entries,separators=(',',':'))+'\n',encoding='utf-8',newline='\n')
 if tree(dest/'chart')!=tree(baseline/'chart'): raise release.GuardError('chart changed from deployed baseline')
 copy_verified(baseline/'quizzes',dest/'quizzes',quizzes)
 shutil.copytree(baseline/'private',dest/'private'); shutil.copy2(baseline/'api',dest/'api'); shutil.copy2(baseline/'catalog.json',dest/'catalog.json')
 volatile=Path(__file__).parent/'volatile_checks.py'
 if not volatile.is_file(): raise release.GuardError('missing reviewed sibling volatile_checks.py')
 for name in release.SUPPORT: shutil.copy2((volatile if name=="volatile_checks.py" else baseline/name),dest/name)
 version.update(quizipedia_facts=13828,quizipedia_sections=15,buildId=build,commit=commit,source_commit=commit,frontend_only=True,api_build_id=version['api_build_id'],source_api_commit=API_SOURCE,main_dart_js_sha256=hashlib.sha256(js).hexdigest())
 (dest/'web/version.json').write_text(json.dumps(version,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 (dest/'quiz-closure.json').write_text(json.dumps({'base_source_revision':API_SOURCE,'base':quizzes,'candidate':quizzes,'expected_mutated':[]},sort_keys=True,indent=2)+'\n',encoding='utf-8',newline='\n')
 (dest/'nonruntime-canonical-exception.json').write_text(json.dumps(canonical_exception,sort_keys=True,indent=2)+'\n',encoding='utf-8',newline='\n')
 base_web=tree(baseline/'web'); candidate_web=tree(dest/'web')
 changed={name:digest for name,digest in candidate_web.items() if base_web.get(name)!=digest}
 if sum((dest/'web'/name).stat().st_size for name in changed)>24*1024*1024: raise release.GuardError('web patch unexpectedly large')
 for name in changed:
  target=dest/'web-delta'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest/'web'/name,target)
 (dest/'base-web-manifest.json').write_text(json.dumps(base_web,sort_keys=True)+'\n',encoding='utf-8')
 release.validate_web_delta(base_web,candidate_web,tree(dest/'web-delta'),dest/'web',release.load_asset_allowlist(dest/release.ASSET_ALLOWLIST_NAME))
 inputs=release.collect_inputs(dest); release.validate_package_identity(inputs,build)
 print(json.dumps({'buildId':build,'source_commit':commit,'frontend_only':True,'api_sha256':release.API_SHA256,'main_dart_js_sha256':version['main_dart_js_sha256'],'package':str(dest)},indent=2))
if __name__=='__main__': main()
