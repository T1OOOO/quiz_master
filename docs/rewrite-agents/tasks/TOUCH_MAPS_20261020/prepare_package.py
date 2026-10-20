"""Freeze a web-only candidate using the hash-checked release70 runtime inputs."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
import release_executor as release

API_SOURCE='7f8344d638e2079d3b47b74972754a3425419791'
def tree(path): return release.hash_tree(path)
def copy_verified(source,destination,expected):
 if tree(source)!=expected: raise release.GuardError('baseline tree checksum differs: '+source.name)
 shutil.copytree(source,destination)
def main():
 p=argparse.ArgumentParser(description=__doc__)
 for name in ('source','destination','baseline-package','baseline-inputs','preflight'): p.add_argument('--'+name,type=Path,required=True)
 a=p.parse_args(); source=a.source.resolve(); baseline=a.baseline_package.resolve(); dest=a.destination.resolve()
 release.read_preflight(a.preflight)
 commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=source,text=True).strip()
 if subprocess.check_output(['git','status','--porcelain','--untracked-files=no'],cwd=source,text=True): raise release.GuardError('source must be clean')
 if subprocess.check_output(['git','diff',API_SOURCE,'--','quizzes','next/server','next/content'],cwd=source): raise release.GuardError('web-only source changed API/content')
 if dest.exists(): raise release.GuardError('destination must be fresh')
 version=json.loads((baseline/'web/version.json').read_text(encoding='utf-8'))
 if version.get('buildId')!=release.BASE_BUILD_ID or version.get('api_sha256')!=release.API_SHA256 or version.get('source_api_commit')!=API_SOURCE: raise release.GuardError('baseline package identity differs')
 manifest=json.loads(a.baseline_inputs.read_text(encoding='utf-8'))
 if manifest.get('target_api_sha256')!=release.API_SHA256: raise release.GuardError('baseline manifest API differs')
 for name in ('chart','quizzes','private'):
  if tree(baseline/name)!=manifest.get(name): raise release.GuardError('retained baseline inputs changed: '+name)
 for name,expected in manifest.get('support',{}).items():
  if release.sha256_file(baseline/name)!=expected: raise release.GuardError('baseline support changed: '+name)
 if release.sha256_file(baseline/'web/version.json')!=manifest.get('version_sha256'): raise release.GuardError('baseline version changed')
 closure=json.loads((baseline/'quiz-closure.json').read_text(encoding='utf-8')); quizzes=tree(baseline/'quizzes')
 if len(quizzes)!=165 or quizzes!=closure.get('candidate'): raise release.GuardError('baseline quiz closure differs')
 if release.sha256_file(baseline/'api')!=release.API_SHA256: raise release.GuardError('unchanged API bytes differ')
 web=source/'next/apps/quiz_app/build/web'; js=(web/'main.dart.js').read_bytes(); build='quiz-2026.10.20-touch-'+commit[:8]
 if build.encode() not in js or b'https://quiz.kotopedia.org' not in js: raise release.GuardError('compiled application identity differs')
 dest.mkdir()
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
 for name in release.SUPPORT: shutil.copy2((Path(__file__).parent if name=="volatile_checks.py" else baseline)/name,dest/name)
 version.update(quizipedia_facts=13678,buildId=build,commit=commit,source_commit=commit,frontend_only=True,api_build_id=version['api_build_id'],source_api_commit=API_SOURCE,main_dart_js_sha256=hashlib.sha256(js).hexdigest())
 (dest/'web/version.json').write_text(json.dumps(version,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 (dest/'quiz-closure.json').write_text(json.dumps({'base_source_revision':API_SOURCE,'base':quizzes,'candidate':quizzes,'expected_mutated':[]},sort_keys=True,indent=2)+'\n',encoding='utf-8',newline='\n')
 base_web=tree(baseline/'web'); candidate_web=tree(dest/'web')
 changed={name:digest for name,digest in candidate_web.items() if base_web.get(name)!=digest}
 if sum((dest/'web'/name).stat().st_size for name in changed)>24*1024*1024: raise release.GuardError('web patch unexpectedly large')
 for name in changed:
  target=dest/'web-delta'/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest/'web'/name,target)
 (dest/'base-web-manifest.json').write_text(json.dumps(base_web,sort_keys=True)+'\n',encoding='utf-8')
 release.validate_web_delta(base_web,candidate_web,tree(dest/'web-delta'))
 inputs=release.collect_inputs(dest); release.validate_package_identity(inputs,build)
 print(json.dumps({'buildId':build,'source_commit':commit,'frontend_only':True,'api_sha256':release.API_SHA256,'main_dart_js_sha256':version['main_dart_js_sha256'],'package':str(dest)},indent=2))
if __name__=='__main__': main()
