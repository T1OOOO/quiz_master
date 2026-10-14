from pathlib import Path
import urllib.request,json,hashlib,datetime
r=Path('C:/ap/quiz_master');d=r/'.run/lotr_sources_20261014_0448';d.mkdir(exist_ok=True)
urls=[('ferre','https://www.tolkienestate.com/writing/vincent-ferre-is-the-lord-of-the-rings-an-adventure-story/'),('christopher','https://www.tolkienestate.com/writing/christopher-tolkien-the-silmarillion/'),('maps','https://www.tolkienestate.com/es/ilustrar/mapas/'),('shippey','https://www.tolkienestate.com/writing/tom-shippey-the-lord-of-the-rings-book-of-the-century/')]
out=[]
for name,url in urls:
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=25) as f:raw=f.read();status=f.status;final=f.url
  assert status==200 and len(raw)>1000
  (d/(name+'.html')).write_bytes(raw)
  out.append({'name':name,'url':url,'final_url':final,'http_status':status,'captured_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'raw_path':str(d/(name+'.html'))})
 except Exception as e:out.append({'name':name,'url':url,'error':type(e).__name__})
(d/'manifest.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out))
