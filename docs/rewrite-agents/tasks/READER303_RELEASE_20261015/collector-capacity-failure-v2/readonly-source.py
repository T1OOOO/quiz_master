import os,json,subprocess,sqlite3,hashlib,urllib.request
s=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
h=json.loads(subprocess.check_output(['helm','status','quiz-master','-n','quiz-master','-o','json']))
x=json.loads(subprocess.check_output(['kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json']))
i=json.loads(subprocess.check_output(['docker','image','inspect','quiz-master:quiz-2026.10.15-reader303-14b7da4']))[0]
with sqlite3.connect('file:/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db?mode=ro',uri=True) as db:
 rows=db.execute('select * from feedback_reports order by rowid').fetchall();n=db.execute("select count(*) from feedback_reports where status='open'").fetchone()[0];sha=hashlib.sha256(json.dumps(rows,ensure_ascii=False,default=str).encode()).hexdigest()
print(json.dumps({'available':s.f_bavail*s.f_frsize,'total':s.f_blocks*s.f_frsize,'deficit_to20':s.f_blocks*s.f_frsize//5-s.f_bavail*s.f_frsize,'helm':h['version'],'images':[c['image'] for c in x['spec']['template']['spec']['containers']],'feedback_count':len(rows),'open':n,'row_sha256':sha,'own_prepared_docker':{k:i.get(k) for k in ['Id','RepoTags','RepoDigests','Size','SharedSize','VirtualSize','RootFS']},'docker_df':subprocess.check_output(['docker','system','df'],text=True)}))
