from pathlib import Path
import json,hashlib
d=Path('docs/rewrite-agents/tasks/READER_PUBLIC_RELEASE_20261015');b=d/'published-browser';p=b/'mixed'
load=lambda x:json.loads(x.read_text(encoding='utf-8-sig'))
commands=[load(x) for x in sorted(p.glob('released-*.json'))]
assert len(commands)>=15 and all(x['actual_exit']==0 for x in commands)
tree=load(p/'released-article-tree.json')['stdout']
assert tree.count('StaticText')>=7 and 'Ключевой факт' in tree and 'Контекст и отличие' in tree
assert 'NCI SEER: Thyroid & Parathyroid Glands' in tree and 'NCBI Bookshelf: Glands and Hormones' in tree
dom=json.loads(json.loads(load(p/'released-article-dom.json')['stdout']))
assert dom['textarea']==0 and any(x['scroll']>x['height'] for x in dom['scrollers'])
assert 'Эндокринная система' in load(p/'released-return.json')['stdout']
assert not load(p/'released-errors.json')['stdout'].strip()
assert load(p/'released-close.json')['actual_exit']==0
cleanup=load(b/'cleanup.json');assert cleanup['actual_exit']==0 and cleanup['captured_browser_identities_absent']
http=load(d/'published-http-verification.json');assert http['status']=='PUBLISHED_HTTP_VERIFIED'
proof={'status':'PUBLISHED_BROWSER_VERIFIED','build_id':http['build']['buildId'],'viewport':{'width':361,'height':738},'session':'reader06-published-mixed','route':['Квизипедия','Изучение','Эндокринная система','Узнать больше'],'reader_title':'Щитовидная железа: две доли у трахеи','body_exposed_as_static_text':True,'empty_textareas':dom['textarea'],'scroll_to_source_footer':True,'source_controls':2,'article_close_returns_to_anatomy':True,'uncaught_browser_errors':0,'screenshots_visually_inspected':['article-top.png','article-footer.png'],'screenshot_sha256':{x:hashlib.sha256((b/x).read_bytes()).hexdigest() for x in ['article-top.png','article-footer.png']},'actual_released_commands':len(commands),'cleanup':cleanup,'scope':'Fresh compiled production Flutter Web. Existing target article opened through local Explore flow; no production quiz/guest/attempt created. Greek002 itself verified by exact published export/public20 DTO equality plus isolated actual20-game browser proof. No Android or physical screen-reader test.'}
(b/'browser-proof.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'status':proof['status'],'empty_textareas':0,'sources':2,'commands':len(commands)}))
