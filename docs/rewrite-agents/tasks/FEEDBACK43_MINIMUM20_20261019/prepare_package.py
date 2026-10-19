#!/usr/bin/env python3
"""Freeze a clean minimum20 release input. This command never contacts production."""
from __future__ import annotations
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path

BASE_SOURCE='36e0b68c64d1b6647923b5e5ddcc70d34e7edd60'
BASE_API='208ac3638f5d7bd3e081b2f042b0afcf222c95a4b1af5e139286e45a3e6f22aa'
EXPECTED_MUTATED={'Cinema/People/cinema_people_20261011.json','Cinema/Thematic80/tv_series.json','Gastronomy/gastronomy_general_facts_1.json','MusicPeople/music_people_20261011.json','Philias/philias_nature.json','Psychology/phobias_general.json','Cinema/Thematic80/game_worlds.json','Cinema/Thematic80/harry_potter.json','Nature/Cats/cats_behavior_and_psychology.json','Nature/Dogs/dogs_science_and_experiments.json','Science/planet_paradoxes_20261010.json'}
BASELINE_ONLY={'Nature/analyze_granular.py','Nature/audit_balanced.py','Nature/fill_gaps.py','Nature/finalize_granular.py'}
SUPPORT=('rehearse.py','pool-materialization-evidence.json','import20-evidence.json','import18-evidence.json','planets-acceptance.json','games-acceptance.json','harrypotter-acceptance.json','animal-extras-acceptance.json')
def sha(p):
 h=hashlib.sha256(); h.update(p.read_bytes()); return h.hexdigest()
def tree(root):
 out={}
 for p in sorted(root.rglob('*')):
  if p.is_symlink(): raise SystemExit(f'symlink forbidden: {p}')
  if p.is_file(): out[p.relative_to(root).as_posix()]=sha(p)
 return out
def git(source,*args): return subprocess.check_output(['git',*args],cwd=source,text=True).strip()
def require_preflight(path):
 raw=path.read_text(encoding='utf-8'); dec=json.JSONDecoder(); deployment,pos=dec.raw_decode(raw); version,_=dec.raw_decode(raw[pos:].lstrip())
 expected='quiz-master:quiz-2026.10.19-bones-36e0b68c@sha256:54a3455a7efac04ab6ee6f9ffb5a053d3ce2ca431ee938557d4ab2aed928d54a'
 if deployment.get('hostname')!='racknerd-f0269d5' or str(deployment.get('revision'))!='69' or deployment.get('deployment_revision')!='67' or deployment.get('pvc_uid')!='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' or {x.get('image') for x in deployment.get('containers',[])}!={expected} or version.get('buildId')!='quiz-2026.10.19-bones-36e0b68c' or version.get('api_sha256')!=BASE_API:
  raise SystemExit('preflight is not the pinned production baseline 69')
 return version
def require_api_provenance(api, commit):
 result=subprocess.run(['go','version','-m',str(api)],text=True,capture_output=True)
 if result.returncode!=0: raise SystemExit('go version -m could not inspect candidate API')
 lines={}
 for row in result.stdout.splitlines():
  fields=row.strip().split('\t',1)
  if len(fields)==2 and fields[0]=='build' and '=' in fields[1]:
   key,value=fields[1].split('=',1); lines[key]=value
  elif len(fields)==2 and fields[0]=='path': lines['path']=fields[1]
 required={'path':'quiz_master/next/server/cmd/api','GOOS':'linux','GOARCH':'amd64','vcs.revision':commit,'vcs.modified':'false'}
 if any(lines.get(key)!=value for key,value in required.items()): raise SystemExit('candidate API Go build provenance differs from clean source')
def main():
 p=argparse.ArgumentParser(description=__doc__); p.add_argument('--source',type=Path,required=True); p.add_argument('--destination',type=Path,required=True); p.add_argument('--api',type=Path,required=True); p.add_argument('--baseline-quizzes',type=Path,required=True); p.add_argument('--preflight',type=Path,required=True); p.add_argument('--quizipedia-facts',type=int,required=True); p.add_argument('--api-source-commit',required=True); a=p.parse_args()
 s=a.source.resolve(); d=a.destination.resolve(); baseline_version=require_preflight(a.preflight)
 commit=git(s,'rev-parse','HEAD')
 if git(s,'status','--porcelain','--untracked-files=no'): raise SystemExit('Refusing to package a dirty source checkout')
 if a.api_source_commit!=commit or len(commit)!=40: raise SystemExit('API source VCS commit must equal clean source HEAD')
 if d.exists(): raise SystemExit('Destination must be fresh')
 api=a.api.resolve(); data=api.read_bytes()
 if data[:4]!=b'\x7fELF': raise SystemExit('Expected a Linux API ELF')
 if hashlib.sha256(data).hexdigest()==BASE_API: raise SystemExit('API binary must change from baseline books API')
 require_api_provenance(api,commit)
 web=s/'next/apps/quiz_app/build/web'; js=web/'main.dart.js'
 build='quiz-2026.10.19-minimum20-'+commit[:8]
 if not js.is_file(): raise SystemExit('compiled clean web lacks main.dart.js')
 js_bytes=js.read_bytes()
 if build.encode() not in js_bytes or b'https://quiz.kotopedia.org' not in js_bytes: raise SystemExit('compiled clean web lacks release identity or public URL')
 qroot=s/'quizzes'; source_tree={key:value for key,value in tree(qroot).items() if key.endswith('.json')}; base_root=a.baseline_quizzes.resolve(); base=tree(base_root)
 if len(base)!=148: raise SystemExit('baseline image quiz tree must contain exactly 148 files')
 if set(base)-set(source_tree)!=BASELINE_ONLY or any(not key.endswith('.json') for key in set(base)-BASELINE_ONLY): raise SystemExit('only four pinned legacy baseline files may be absent from clean source')
 if len(source_tree)!=161: raise SystemExit('clean source must contain exactly 161 quiz JSON files')
 extra=set(source_tree)-set(base)
 if len(extra)!=17: raise SystemExit('source quiz closure is not exact 17 new JSON files')
 def normalized(p): return hashlib.sha256(p.read_bytes().replace(b'\r\n',b'\n').replace(b'\r',b'\n')).hexdigest()
 for rel in (set(base)&set(source_tree))-EXPECTED_MUTATED:
  if normalized(qroot/rel)!=normalized(base_root/rel): raise SystemExit('unapproved source semantic mutation outside exact 11')
 private=d/'private'; shutil.copytree(base_root,private/'quizzes')
 for rel in EXPECTED_MUTATED|extra:
  out=private/'quizzes'/rel; out.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(qroot/rel,out)
 candidate=tree(private/'quizzes'); changed={x for x in base if candidate.get(x)!=base[x]}
 if changed!=EXPECTED_MUTATED: raise SystemExit('candidate existing quiz closure differs outside exact 11 approved files')
 shutil.copytree(private/'quizzes',d/'quizzes')
 task=s/'docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019'
 for name in SUPPORT:
  if not (task/name).is_file(): raise SystemExit(f'missing rehearsal support: {name}')
 (private/'study/drafts').mkdir(parents=True)
 for name in ('feedback43-planets-extra-20261019.json','feedback43-games-extra-20261019.json','feedback43-harrypotter-extra-20261019.json','feedback43-animal-extras-20261019.json'):
  shutil.copy2(s/'study/drafts'/name,private/'study/drafts'/name)
 shutil.copytree(web,d/'web'); shutil.copytree(s/'deploy/helm/quiz-master',d/'chart'); shutil.copy2(api,d/'api')
 catalog=s/'next/apps/quiz_app/assets/catalog.json'
 rows=json.loads(catalog.read_text(encoding='utf-8'))
 if not isinstance(rows,list) or len(rows)!=105 or sum(row.get('questions_count',0) for row in rows if isinstance(row,dict))!=4520: raise SystemExit('ordinary public catalog must contain 105 packs and 4520 slots')
 shutil.copy2(catalog,d/'catalog.json')
 for name in SUPPORT: shutil.copy2(task/name,d/name)
 version=dict(baseline_version)
 version.update({'buildId':build,'commit':commit,'source_commit':commit,'source_api_commit':a.api_source_commit,'api_sha256':sha(d/'api'),'main_dart_js_sha256':sha(d/'web/main.dart.js'),'packs':105,'questions':4520,'quizipedia_facts':a.quizipedia_facts,'question_articles':305,'question_article_references':241,'frontend_only':False,'api_build_id':build})
 if a.quizipedia_facts!=13588: raise SystemExit('minimum20 package requires 13588 Quizipedia facts')
 (d/'web/version.json').write_text(json.dumps(version,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
 closure={'base_source_revision':BASE_SOURCE,'baseline_image_tree':str(base_root),'base':base,'candidate':candidate,'expected_mutated':sorted(EXPECTED_MUTATED),'baseline_only':sorted(BASELINE_ONLY),'new_files':sorted(extra),'unchanged_source_lf_normalized':{rel:normalized(qroot/rel) for rel in sorted((set(base)&set(source_tree))-EXPECTED_MUTATED)}}
 (d/'quiz-closure.json').write_text(json.dumps(closure,sort_keys=True,indent=2)+'\n',encoding='utf-8',newline='\n')
 print(json.dumps({'buildId':build,'source_commit':commit,'api_sha256':version['api_sha256'],'quiz_files':len(candidate),'changed_existing':len(changed),'new_files':len(closure['new_files']),'package':str(d)},indent=2))
if __name__=='__main__': main()
