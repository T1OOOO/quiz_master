from pathlib import Path
import hashlib,json,subprocess,re
root=Path('C:/ap/quiz_master');out=root/'docs/rewrite-agents/tasks/COUNTRY483_REMOTE_20261015/capacity/fixture-v3'
p=root/'.run/country483_remote_20261015/capacity-adapter-v2/preview-v1/linux-integration-v2.sh'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(p)=='787a2ea7d2227b63356f2e3e9641b562d05583a169f78a9e6f43968c90874d1c'
body=p.read_text()
pairs=[('def readonly(uri,**kwargs):','def readonly(database,**kwargs):'),("self.assertIn('mode=ro',uri);self.assertEqual(kwargs,{'uri':True})","self.assertIn('mode=ro',database);self.assertEqual(kwargs,{'uri':True})")]
for before,after in pairs:
 assert body.count(before)==1
 body=body.replace(before,after)
script=out/'linux-integration-v3.sh';assert not script.exists();script.write_bytes(body.encode())
r=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=body.encode(),capture_output=True);assert r.returncode==0,r.stderr
blocks=re.findall(r"python3 - <<'([A-Z_0-9]+)'\n(.*?)\n\1(?:\n|$)",body,re.S);assert len(blocks)==1
for marker,code in blocks:compile(code,marker,'exec')
record=dict(original_fixture_sha256=sha(p),corrected_fixture_sha256=sha(script),exact_replacements=pairs,actual_bash_syntax_exit=0,compiled_python_blocks=1,production_script_unchanged_sha256=sha(root/'.run/country483_remote_20261015/capacity-adapter-v2/preview-v1/deduplicate-v2.sh'),linux_execution_performed=False)
(out/'correction.json').write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record))
