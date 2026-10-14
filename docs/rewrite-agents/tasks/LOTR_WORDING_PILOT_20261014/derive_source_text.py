from html.parser import HTMLParser
from pathlib import Path
import json,hashlib
d=Path('C:/ap/quiz_master/.run/lotr_sources_20261014_0448')
class Text(HTMLParser):
 def __init__(self):super().__init__();self.out=[];self.skip=0
 def handle_starttag(self,t,a):
  if t in ['script','style']:self.skip+=1
  if t in ['p','div','br','h1','h2','h3']:self.out.append('\n')
 def handle_endtag(self,t):
  if t in ['script','style']:self.skip-=1
 def handle_data(self,s):
  if not self.skip:self.out.append(s)
out=[]
for s in json.loads((d/'manifest.json').read_text()):
 assert s.get('http_status')==200
 p=Path(s['raw_path']);assert hashlib.sha256(p.read_bytes()).hexdigest()==s['sha256']
 parser=Text();parser.feed(p.read_text(encoding='utf8'));text='\n'.join(line.strip() for line in ''.join(parser.out).splitlines() if line.strip());target=d/(s['name']+'-text.txt');target.write_text(text,encoding='utf8')
 out.append({**s,'text_path':str(target),'text_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'derivation':'HTMLParser text, scripts/styles omitted; raw HTML retained unchanged in ignored scratch'})
(d/'source-artifact-manifest.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps({'artifacts':len(out),'all_http_status':200,'raw_hash_matches':True}))
