import subprocess,json
from pathlib import Path
code="""import subprocess,json,socket,os,urllib.request
run=lambda *a:subprocess.check_output(a,text=True)
d=json.loads(run('kubectl','get','deploy','quiz-master','-n','quiz-master','-o','json'))
h=json.loads(run('helm','history','quiz-master','-n','quiz-master','-o','json'))
n=json.loads(run('kubectl','get','nodes','-o','json'))['items'][0]
s=os.statvfs('/var/lib/rancher/k3s/agent/containerd')
x={'hostname':socket.gethostname(),'revision':str(next(i['revision'] for i in h if i['status']=='deployed')),'deployment_revision':d['metadata']['annotations']['deployment.kubernetes.io/revision'],'pvc_uid':run('kubectl','get','pvc','quiz-data','-n','quiz-master','-o','jsonpath={.metadata.uid}'),'containers':[{'name':c['name'],'image':c['image']} for c in d['spec']['template']['spec']['containers']],'disk':{'total':s.f_blocks*s.f_frsize,'free':s.f_bavail*s.f_frsize,'available_percent':s.f_bavail*100/s.f_blocks,'path':'/var/lib/rancher/k3s/agent/containerd'},'node':{'conditions':{c['type']:c['status'] for c in n['status']['conditions']},'unschedulable':n['spec'].get('unschedulable',False),'taints':n['spec'].get('taints',[])}}
print(json.dumps(x))
with urllib.request.urlopen('https://quiz.kotopedia.org/version.json',timeout=30) as r: print(json.dumps(json.load(r)))
"""
r=subprocess.run(['ssh','-i','C:/Users/Alexey_Matvienko/.ssh/ll_deploy_ed25519','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','root@192.3.164.184','python3 -'],input=code.encode(),capture_output=True,check=True)
p=Path('.run/lazy_feedback20_20261020/preflight.txt');p.write_bytes(r.stdout);a=json.loads(r.stdout.decode().splitlines()[0]);print(json.dumps(a))
assert a['disk']['available_percent']>=20 and a['revision']=='77'
