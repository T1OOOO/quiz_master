"""Exercise the public verifier against exact packaged data with mocked HTTP only."""
from pathlib import Path
from unittest.mock import patch
from contextlib import redirect_stdout
import io,json,runpy,urllib.parse
d=Path('.run/planet_release_20261011');m=json.loads((d/'package.json').read_text());stage=Path(m['stage']);articles=json.loads((stage/'web/assets/assets/study/question-articles.json').read_text())['articles']
def fake_urlopen(url,timeout):
 p=url.removeprefix('https://quiz.kotopedia.org/')
 if p=='version.json':return io.BytesIO(json.dumps(m['version']).encode())
 if p in ['main.dart.js','assets/assets/catalog.json','assets/assets/study/question-articles.json']:return io.BytesIO((stage/'web'/p).read_bytes())
 qid=urllib.parse.parse_qs(urllib.parse.urlsplit(url).query)['quiz_id'][0]
 if qid=='planet-paradoxes-20261010':questions=json.loads((stage/'next/content'/qid/'bundle.json').read_text())['quiz']['questions']
 else:questions=[{'question_id':ref['question_id'],'revision':{'sha256':ref['revision_sha256']}} for a in articles for ref in a['question_refs'] if ref['quiz_id']==qid]
 return io.BytesIO(json.dumps({'quiz':{'questions':questions}}).encode())
output=io.StringIO()
with patch('urllib.request.urlopen',fake_urlopen),patch.object(Path,'write_text') as write,redirect_stdout(output):runpy.run_path(str(d/'verify_public.py'))
data=json.loads(output.getvalue());assert data['live_question_article_bindings']==85 and write.call_count==1
print('PASS mocked verifier self-check85bindings; this is NOT a public or browser verification')
