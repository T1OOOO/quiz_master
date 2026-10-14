from pathlib import Path
import json
r=Path('C:/ap/quiz_master'); w=r/'.run/library_release_20261014'; d=r/'docs/rewrite-agents/tasks/LIBRARY_RELEASE_20261014'
p=json.loads((w/'package-v1/package-preparation.json').read_bytes())
stage=(r/Path(p['archive'])).parent/p['build_id']
metadata=json.loads((stage/'web/version.json').read_bytes())
assert metadata['question_articles']==278 and metadata['buildId']==p['build_id']
p.update(stage=str(stage),production_js_sha256=metadata['main_dart_js_sha256'])
(w/'publication-package.json').write_text(json.dumps(p,indent=2)+'\n')
source=(r/'.run/mixed_release_20261014/render_publish.py').read_text()
replacements={'MIXED_RELEASE_20261014':'LIBRARY_RELEASE_20261014','package-v5/package-preparation.json':'publication-package.json','remote-prepare-v4/remote-preparation-verification.json':'remote-v1/remote-preparation-verification.json','quiz-2026.10.14-mixed-ecac092':p['build_id'],'ecac092a9ab9af5ac39b4879b8249675b3cca9a2':p['frozen_commit'],'x["version"]==52':'x["version"]==54'}
for old,new in replacements.items():
 assert old in source,old
 source=source.replace(old,new)
exec(compile(source,str(__file__),'exec'))
