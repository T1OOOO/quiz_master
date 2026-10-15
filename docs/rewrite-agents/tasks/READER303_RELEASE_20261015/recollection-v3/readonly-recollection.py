from pathlib import Path
import sys,json,hashlib,re
r=Path('C:/ap/quiz_master');w=r/'.run/reader303_release_20261015';d=r/'docs/rewrite-agents/tasks/READER303_RELEASE_20261015'
sys.path.insert(0,str(d/'release-worker'))
import prepare_reader303_remote as remote
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert h(d/'release-worker/prepare_reader303_remote.py')=='89f5fc11b2205e26da920c0b188ecf6693b532d55d1c8945e3ef7d110c53fde8'
old=w/'remote-v2';assert json.loads((old/'remote-prepare-exit.json').read_bytes())=={'actual_exit':0}
log=(old/'remote-prepare-log.txt').read_text();match=re.search(r'PREPARED build=(\S+) image=(sha256:[a-f0-9]{64}) values=(\S+) mode=prepare',log)
assert match and match[1]==remote.reader.BUILD_ID
run=match[3].removesuffix('-values.yaml');assert run.endswith('20261015T171054Z')
durable='c86b4632f0826f9a5a7d92b772ba1744846f23ff08d2b46403c23d1c18153bd3'
assert durable in log
script=remote.collection_script(run,match[2],durable)
assert script.encode()==(old/'remote-collect-script.sh').read_bytes()
evidence=w/'remote-v3-collect';assert not evidence.exists();evidence.mkdir()
(evidence/'remote-collect-script.sh').write_bytes(script.encode())
proof=json.loads(remote.ssh_capture(script,60,'remote-collect',evidence,remote.legacy_remote()))
review=d/'remote-helper-acceptance-v5.json';sources=[d/'release-worker'/n for n in ('prepare_reader303_remote.py','test_prepare_reader303_remote.py','reader303_guard.py')]+[remote.LEGACY/'prepare_remote_mixed.py']
package=json.loads((w/'package-v2/package-preparation.json').read_bytes())
proof.update(source_commit=remote.reader.FROZEN_COMMIT,package_sha256=package['archive_sha256'],remote_prepare_exit=0,remote_log_sha256=h(old/'remote-prepare-log.txt'),helper_source_sha256={str(p.resolve()):h(p) for p in sources},helper_review_sha256=h(review),original_prepare_evidence=str(old),prior_failed_collection_exit=1,recollection_only=True,limits=['Original preparation0; failed original collector1 retained. Fresh original read-only collector0; no rebuild, rehearsal or publication. Exact publication review remains.'])
(evidence/'remote-preparation-verification.json').write_bytes((json.dumps(proof,indent=2)+'\n').encode())
pin=d/'preparation-receipt-pin.json';assert not pin.exists();pin.write_text(json.dumps({'path':str(evidence/'remote-preparation-verification.json'),'sha256':h(evidence/'remote-preparation-verification.json')},indent=2)+'\n')
print(json.dumps({'status':proof['status'],'image':proof['image'],'free':proof['disk_free_bytes'],'recollection_only':True,'actual_exit':0}))
