from pathlib import Path
import json,hashlib
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/SCREEN_SONG_RELEASE_20261014';e=r/'docs/rewrite-agents/tasks/SCREEN_SONG_REVIEW_20261014';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();load=lambda p:json.loads(p.read_text(encoding='utf8'))
a=load(e/'independent-package-review.json');assert a['actual_cli_exit']==0 and a['actual_hub_state']=='ACCEPTED'
t=a['actual_reviews']['task-e6d2a8b0cb9a4521bc47037422030977']['actual_response'];assert t['reviewer']!=t['assignee'];note=t['review_note'];p=load(d/'package-current.json');assert p['archive_sha256'] in note
for name in ['release-pins.json','package-current.json','browser-proof.json','root-local-browser-verification.json']:assert sha(d/name) in note,name
before=load(r/'.run/screen_song_controller_resumed_20261014/local-verification.json')['controller_sha256']
code={k:sha(d/'worker-resumed'/v) for k,v in [('producer_sha256','prepare_screen_song_release.py'),('prepare_controller_sha256','prepare_remote.py'),('publisher_controller_sha256','publish_prepared.py')]}
for name in ['prepare_screen_song_release.py','prepare_remote.py','publish_prepared.py']:assert sha(d/'worker-resumed'/name)==before[name],name
assert all(name in note for name in ['prepare_screen_song_release.py','prepare_remote.py','publish_prepared.py'])
a.update(code,reviewer_provider='claude',package_sha256=p['archive_sha256'],release_pins_sha256=sha(d/'release-pins.json'),browser_evidence_sha256=sha(d/'browser-proof.json'),root_browser_evidence_sha256=sha(d/'root-local-browser-verification.json'),controller_hash_binding_scope='Reviewer actually read these controller files and approved their static guards. Root derives code hashes from the unchanged pre-review native byte-hash snapshot; reviewer did not include independent code-hash recomputation in the note. Package/pins/QA full hashes were independently recomputed and explicitly bound in the actual callback.')
(d/'static-review.json').write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Genuine static acceptance bound; Root-derived unchanged controller hashes explicitly qualified.')
