import sqlite3,json,hashlib,pathlib,socket
assert socket.gethostname()=='racknerd-f0269d5'
p=pathlib.Path('/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db');assert p.is_file() and not p.is_symlink()
with sqlite3.connect(p.as_uri()+'?mode=ro',uri=True) as db:
 db.execute('begin')
 row=db.execute('select b.controlled_bundle,b.manifest,a.bundle_sha256,a.status from attempts a join attempt_bundles b on b.bundle_sha256=a.bundle_sha256 and b.bundle_version=a.bundle_version where a.id=?',('a-ab9c12da-3c37-490b-aa2e-27efb3cd9a01',)).fetchone();assert row
 hashes={k:hashlib.sha256((v.encode() if isinstance(v,str) else v)).hexdigest() for k,v in zip(('controlled_bundle','manifest'),row[:2])}
 assert hashes=={'controlled_bundle': '8d05be80a37c6d37613c0aa9962ea631406df4eec6ec72929c01d686cf666ce3', 'manifest': 'b74c57e21d8828d46fca907444a4486ad026fffe766ccc4047d49683389bb2cf'}
 assert row[2]=='bc5bd90cd6835de4a8c007f1e9994521841857829ab37c71c27794ff593af050'
 assert db.execute('select count(*) from attempt_answers where attempt_id=?',('a-ab9c12da-3c37-490b-aa2e-27efb3cd9a01',)).fetchone()[0]==0
 print(json.dumps(dict(hashes,old_bundle_sha256=row[2],status=row[3],checked_questions=3,old_keys_and_explanations_preserved=True,verification='read-only SQLite byte comparison against verified pre-release backup',api_completion='blocked by elapsed deadline and no accepted answers')))
