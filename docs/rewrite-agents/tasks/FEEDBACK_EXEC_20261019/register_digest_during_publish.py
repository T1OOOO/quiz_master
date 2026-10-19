import subprocess
code=r'''import subprocess,json,time,socket
assert socket.gethostname()=='racknerd-f0269d5'
digest='sha256:2205f76f1a7d02f91765c7fa1ca347b6db14b1ef241a03496470154664df3d43'
source='docker.io/library/quiz-master:quiz-2026.10.19-feedback-849e6705'
canonical='docker.io/library/quiz-master@'+digest
rows=[x.split() for x in subprocess.check_output(['k3s','ctr','-n','k8s.io','images','ls'],text=True).splitlines()[1:]]
assert any(x[0]==source and x[2]==digest for x in rows)
existing=[x for x in rows if x[0]==canonical]
if existing: assert existing[0][2]==digest
else: subprocess.run(['k3s','ctr','-n','k8s.io','images','tag',source,canonical],check=True)
for _ in range(10):
 r=subprocess.run(['k3s','crictl','inspecti',canonical],capture_output=True,text=True)
 if r.returncode==0: break
 time.sleep(1)
assert r.returncode==0,'CRI did not register exact approved image digest'
pods=json.loads(subprocess.check_output(['kubectl','get','pods','-n','quiz-master','-o','json'],text=True))
for p in pods['items']:
 cs=p['spec'].get('containers',[])
 if not cs or not all(c['image'].endswith('@'+digest) for c in cs): continue
 if p['status'].get('phase')=='Pending' and not any(c.get('ready') for c in p['status'].get('containerStatuses',[])):
  subprocess.run(['kubectl','delete','pod',p['metadata']['name'],'-n','quiz-master','--wait=false'],check=True)
print('Exact approved digest registered locally; only unready candidate pod retried')
'''
subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','root@192.3.164.184','python3','-'],input=code.encode(),check=True,timeout=45)
