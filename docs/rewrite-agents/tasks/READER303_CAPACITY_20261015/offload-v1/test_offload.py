import copy,hashlib,io,json,os,subprocess,sys,tempfile,unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch,MagicMock
import offload,execute
DOCS=Path(__file__).parent

class OffloadTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name).resolve()
  self.plan=json.loads((DOCS/'plan.json').read_bytes());self.protected=json.loads((DOCS/'protected-hashes.json').read_bytes())
 def tearDown(self):self.temp.cleanup()
 def entry(self):
  p=self.root/Path(self.plan['entries'][0]['path']).name;p.write_bytes(b'local guard fixture');st=p.stat()
  return dict(self.plan['entries'][0],size=st.st_size,dev=st.st_dev,ino=st.st_ino,mtime_ns=st.st_mtime_ns,sha256=hashlib.sha256(p.read_bytes()).hexdigest())
 def test_actual_plan_then_mutations(self):
  self.assertEqual(len(offload.validate_plan(self.plan,self.protected)),28)
  for kind in ('duplicate','path','name','hash','metadata','protected','total'):
   bad=copy.deepcopy(self.plan);protected=copy.deepcopy(self.protected)
   if kind=='duplicate':bad['entries'][1]=copy.deepcopy(bad['entries'][0])
   if kind=='path':bad['entries'][0]['path']='/opt/quiz-master/releases/../escape.tar.gz'
   if kind=='name':bad['entries'][0]['path']='/opt/quiz-master/releases/quiz-2099-unsafe.tar.gz'
   if kind=='hash':bad['entries'][0]['sha256']='x'*64
   if kind=='metadata':bad['entries'][0]['ino']=True
   if kind=='protected':protected.pop(next(iter(protected)))
   if kind=='total':bad['total_bytes']+=1
   with self.subTest(kind=kind),self.assertRaises(AssertionError):offload.validate_plan(bad,protected)
 def test_file_metadata_hash_nlink_and_parent_guards(self):
  entry=self.entry();offload.verify_entry(entry,self.root)
  for field,value in [('ino',entry['ino']+1),('mtime_ns',entry['mtime_ns']+1),('sha256','0'*64),('path','/escape')]:
   bad=dict(entry,**{field:value})
   with self.subTest(field=field),self.assertRaises(AssertionError):offload.verify_entry(bad,self.root)
  st=(self.root/Path(entry['path']).name).stat()
  fake=SimpleNamespace(st_mode=st.st_mode,st_nlink=2,st_dev=st.st_dev,st_ino=st.st_ino,st_size=st.st_size,st_mtime_ns=st.st_mtime_ns)
  with patch.object(Path,'lstat',return_value=fake),self.assertRaises(AssertionError):offload.verify_entry(entry,self.root)
 def test_batch_and_per_unlink_hash_validation_precede_unlink(self):
  entry=self.entry();bad=dict(entry,sha256='0'*64)
  with patch.object(offload.os,'unlink') as unlink,self.assertRaises(AssertionError):offload.remove_verified([bad],self.protected,self.root)
  unlink.assert_not_called()
  def corrupt():(self.root/Path(entry['path']).name).write_bytes(b'changed before unlink')
  with patch.object(offload.os,'unlink') as unlink,self.assertRaises(AssertionError):offload.remove_verified([entry],self.protected,self.root,before_unlink=corrupt)
  unlink.assert_not_called()
 def test_capacity_boundaries_and_concurrent_growth(self):
  before={'disk_available':20000000000,'disk_total':100000000000};reclaim=1518083884
  offload.check_capacity(before,reclaim=reclaim)
  floor=100000000000//5+offload.GIB
  for available in (floor-1,floor):
   with self.subTest(available=available),self.assertRaises(AssertionError):offload.check_capacity(before,{'disk_available':available,'disk_total':before['disk_total']},reclaim)
  offload.check_capacity(before,{'disk_available':before['disk_available']+reclaim-offload.GROWTH_LIMIT,'disk_total':before['disk_total']},reclaim)
  with self.assertRaises(AssertionError):offload.check_capacity(before,{'disk_available':before['disk_available']+reclaim-offload.GROWTH_LIMIT-1,'disk_total':before['disk_total']},reclaim)
  with self.assertRaises(AssertionError):offload.check_capacity({'disk_available':floor-reclaim,'disk_total':100000000000},reclaim=reclaim)
 def test_inventory_additions_allowed_removals_refused(self):
  before={'containerd':{('a','id')},'docker':{('b','digest','id')}}
  after={k:set(v)|{('new','entry')} for k,v in before.items()};offload.images_preserved(before,after)
  after['containerd'].remove(('a','id'))
  with self.assertRaises(AssertionError):offload.images_preserved(before,after)
 def test_render_is_complete_inert_and_linux_syntax(self):
  with patch.object(subprocess,'run') as command:shell=offload.render(self.plan,self.protected)
  command.assert_not_called()
  for text in ['racknerd-f0269d5','flock -n 8','version', '== 62','O_NOFOLLOW','st_nlink','452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e','run_offload(plan, protected)']:
   self.assertIn(text,shell)
  self.assertNotIn('docker image rm',shell);self.assertNotIn('helm upgrade',shell)
  result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=shell.encode(),capture_output=True)
  self.assertEqual(result.returncode,0,result.stderr.decode())
 def test_preflight_actual62_guards_execute_before_and_after(self):
  import sqlite3,urllib.request
  image='docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4'
  node={'spec':{},'status':{'conditions':[{'type':'Ready','status':'True'},{'type':'DiskPressure','status':'False'}]}}
  baseline={'helm':{'version':62,'info':{'status':'deployed'}},'deploy':{'spec':{'template':{'spec':{'containers':[{'image':image},{'image':image}]}}},'status':{'availableReplicas':1}},'pvc':{'metadata':{'uid':'7fc2428f-4146-4c78-a26d-2347d9f3b7bf'},'status':{'phase':'Bound'}},'nodes':{'items':[node]}}
  def run(data,count=29,opened=29,sha='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e',status=200):
   def command(args,**kw):return json.dumps(data['helm' if args[0]=='helm' else args[2]]).encode()
   def query(sql):return SimpleNamespace(fetchall=lambda:[('synthetic row',)]*count,fetchone=lambda:('ok',) if 'integrity' in sql else (opened,))
   db=MagicMock();db.__enter__.return_value.execute.side_effect=query
   response=MagicMock();response.__enter__.return_value.status=status
   with patch.object(subprocess,'check_output',side_effect=command),patch.object(os,'statvfs',create=True,return_value=SimpleNamespace(f_bavail=20,f_blocks=100,f_frsize=1000000000)),patch.object(os,'stat',return_value=SimpleNamespace(st_dev=1,st_mode=0o100600)),patch.object(sqlite3,'connect',return_value=db) as connect,patch.object(urllib.request,'urlopen',return_value=response),patch.object(hashlib,'sha256') as h,redirect_stdout(io.StringIO()):
    h.return_value.hexdigest.return_value=sha
    state=offload.preflight()
    self.assertEqual(connect.call_count,2)
    self.assertTrue(all('?mode=ro' in call.args[0] and call.kwargs=={'uri':True} for call in connect.call_args_list))
    return state
  self.assertEqual(run(baseline)['helm_revision'],62)
  for mutation in ('revision','image','pvc','unbound','replica','ready','pressure','taint','cordon'):
   data=copy.deepcopy(baseline)
   if mutation=='revision':data['helm']['version']=61
   if mutation=='image':data['deploy']['spec']['template']['spec']['containers'][0]['image']='foreign'
   if mutation=='pvc':data['pvc']['metadata']['uid']='foreign'
   if mutation=='unbound':data['pvc']['status']['phase']='Pending'
   if mutation=='replica':data['deploy']['status']['availableReplicas']=0
   if mutation=='ready':data['nodes']['items'][0]['status']['conditions'][0]['status']='False'
   if mutation=='pressure':data['nodes']['items'][0]['status']['conditions'][1]['status']='True'
   if mutation=='taint':data['nodes']['items'][0]['spec']['taints']=[{'effect':'NoExecute'}]
   if mutation=='cordon':data['nodes']['items'][0]['spec']['unschedulable']=True
   with self.subTest(mutation=mutation),self.assertRaises(AssertionError):run(data)
  for kwargs in ({'count':28},{'opened':28},{'sha':'0'*64},{'status':503}):
   with self.subTest(kwargs=kwargs),self.assertRaises(AssertionError):run(baseline,**kwargs)
 def test_orchestration_snapshots_and_protected_checks_surround_removal(self):
  before={'disk_available':20000000000,'disk_total':100000000000};after=dict(before,disk_available=before['disk_available']+self.plan['total_bytes'])
  inventory={'containerd':{('private-ref','sha')},'docker':{('private-tag','digest','id')}}
  def remove(entries,protected,**kwargs):kwargs['before_unlink']();return [e['path'] for e in entries]
  out=io.StringIO()
  with patch.object(offload,'preflight',side_effect=[before,before,after]) as preflight,patch.object(offload,'verify_protected') as protected,patch.object(offload,'remove_verified',side_effect=remove),patch.object(offload,'loaded_images',return_value=inventory) as images,patch.object(os,'unlink') as unlink,redirect_stdout(out):
   offload.run_offload(self.plan,self.protected)
  self.assertEqual(preflight.call_count,3);self.assertEqual(protected.call_count,2);self.assertEqual(images.call_count,2);unlink.assert_not_called()
  self.assertNotIn('private-ref',out.getvalue());self.assertNotIn('private-tag',out.getvalue())
  self.assertIn('EXACT_COLD_PACKAGES_OFFLOADED',out.getvalue())
 def test_parent_identity_drift_refuses_before_unlink(self):
  entry=self.entry()
  with patch.object(offload,'parent_identity',side_effect=[(1,1),(1,2)]),patch.object(os,'unlink') as unlink,self.assertRaises(AssertionError):offload.remove_verified([entry],self.protected,self.root)
  unlink.assert_not_called()
 def copies_fixture(self):
  work=self.root/'copy-work';copies=work/'copies';copies.mkdir(parents=True)
  plan=copy.deepcopy(self.plan);rows=[]
  for index,entry in enumerate(plan['entries']):
   payload=('copy unit fixture '+str(index)).encode();local=copies/Path(entry['path']).name;local.write_bytes(payload)
   entry['size']=len(payload);entry['sha256']=hashlib.sha256(payload).hexdigest()
   rows.append({'remote':entry['path'],'local':str(local),'size':len(payload),'sha256':entry['sha256'],'transfer_exit':0,'transfer_kind':'scp'})
  plan['total_bytes']=sum(e['size'] for e in plan['entries'])
  receipt={'plan_sha256':'a'*64,'count':28,'bytes':plan['total_bytes'],'copied':rows}
  return work,plan,receipt
 def test_scp_copies_actual_bytes_then_hash_path_and_transfer_mutations(self):
  work,plan,receipt=self.copies_fixture()
  # Tiny28-file unit fixture isolates local-copy verification; actual frozen plan contract is tested separately.
  with patch.object(execute,'WORK',work),patch.object(offload,'validate_plan',return_value=plan['entries']):
   execute.verify_copies(plan,receipt,'a'*64,self.protected)
   for field,value in [('sha256','0'*64),('transfer_kind','invented'),('transfer_exit',1),('local',str(self.root/'escape'))]:
    bad=copy.deepcopy(receipt);bad['copied'][0][field]=value
    with self.subTest(field=field),self.assertRaises((AssertionError,FileNotFoundError)):execute.verify_copies(plan,bad,'a'*64,self.protected)
   Path(receipt['copied'][0]['local']).write_bytes(b'altered')
   with self.assertRaises(AssertionError):execute.verify_copies(plan,receipt,'a'*64,self.protected)
 def approval_fixture(self):
  docs=self.root/'unit-docs';docs.mkdir();work=self.root/'unit-work';work.mkdir()
  for name in execute.SOURCE_FILES:(docs/name).write_bytes((DOCS/name).read_bytes())
  for name,value in [('plan.json',self.plan),('protected-hashes.json',self.protected),('copy-receipt.json',{'unit_fixture':True})]:(docs/name).write_text(json.dumps(value))
  (docs/'offload.sh').write_bytes(offload.render(self.plan,self.protected).encode())
  raw=b'Ran 8 tests in 0.001s\n\nOK\n';(docs/'tests-stdout.txt').write_bytes(raw)
  tests={'actual_exit':0,'tests':8,'stdout_sha256':hashlib.sha256(raw).hexdigest(),'source_sha256':{name:execute.digest(docs/name) for name in execute.SOURCE_FILES}}
  (docs/'tests.json').write_text(json.dumps(tests))
  manifest={name:execute.digest(docs/name) for name in execute.INPUT_FILES};(docs/'approval-inputs.json').write_text(json.dumps(manifest))
  review={'actual_cli_exit':0,'actual_hub_state':'ACCEPTED','actual_reviews':{execute.TASK_ID:{'call':{'action':'review','arguments':{'task_id':execute.TASK_ID,'verdict':'accept','error_count':0,'note':'approval-inputs sha256 '+execute.digest(docs/'approval-inputs.json')}},'actual_response':{'id':execute.TASK_ID,'state':'ACCEPTED','assignee':execute.ASSIGNEE,'reviewer':'independent-unit-fixture'}}}}
  (docs/'source-review.json').write_text(json.dumps(review));return docs,work,manifest,review
 def test_exact_manifest_and_fresh_review_guards_before_ssh(self):
  docs,work,manifest,review=self.approval_fixture()
  with patch.object(execute,'DOCS',docs),patch.object(execute,'WORK',work),patch.object(execute,'verify_copies'),patch.object(subprocess,'run') as ssh:
   execute.validate_inputs()
   for mutation in ('unaccepted','old_task','wrong_assignee','self_review','unbound','omitted_manifest','source_drift'):
    current=copy.deepcopy(review);inputs=copy.deepcopy(manifest)
    if mutation=='unaccepted':current['actual_hub_state']='SUBMITTED'
    if mutation=='old_task':current['actual_reviews']={'task-5b14787b143443f089d413d12e94e16e':current['actual_reviews'][execute.TASK_ID]}
    if mutation=='wrong_assignee':current['actual_reviews'][execute.TASK_ID]['actual_response']['assignee']='old'
    if mutation=='self_review':current['actual_reviews'][execute.TASK_ID]['actual_response']['reviewer']=execute.ASSIGNEE
    if mutation=='unbound':current['actual_reviews'][execute.TASK_ID]['call']['arguments']['note']='wrong digest'
    if mutation=='omitted_manifest':inputs.pop('test_offload.py')
    (docs/'approval-inputs.json').write_text(json.dumps(inputs))
    if mutation=='omitted_manifest':current['actual_reviews'][execute.TASK_ID]['call']['arguments']['note']='approval-inputs sha256 '+execute.digest(docs/'approval-inputs.json')
    (docs/'source-review.json').write_text(json.dumps(current))
    if mutation=='source_drift':(docs/'offload.py').write_bytes(b'drift')
    with self.subTest(mutation=mutation),self.assertRaises(AssertionError):execute.main()
    (docs/'offload.py').write_bytes((DOCS/'offload.py').read_bytes())
   ssh.assert_not_called()
 def test_wrong_copy_and_existing_evidence_stop_before_ssh(self):
  docs,work,manifest,review=self.approval_fixture()
  with patch.object(execute,'DOCS',docs),patch.object(execute,'WORK',work),patch.object(execute,'verify_copies',side_effect=AssertionError('bad cold copy')),patch.object(subprocess,'run') as ssh:
   with self.assertRaisesRegex(AssertionError,'bad cold copy'):execute.main()
   ssh.assert_not_called()
  (work/'execution-stdout.txt').write_bytes(b'prior actual evidence')
  with patch.object(execute,'WORK',work),patch.object(execute,'validate_inputs') as validate,patch.object(subprocess,'run') as ssh:
   with self.assertRaisesRegex(AssertionError,'existing execution'):execute.main()
   validate.assert_not_called();ssh.assert_not_called()
 def test_timeout_retains_partial_logs_and_refuses_retry(self):
  docs,work,manifest,review=self.approval_fixture()
  validated=(self.plan,self.protected,{},manifest,execute.digest(docs/'source-review.json'),execute.digest(docs/'approval-inputs.json'))
  with patch.object(execute,'DOCS',docs),patch.object(execute,'WORK',work),patch.object(execute,'validate_inputs',return_value=validated),patch.object(execute,'verify_copies'),patch.object(subprocess,'run',side_effect=subprocess.TimeoutExpired('ssh',1,output=b'partial actual stdout',stderr=b'partial actual stderr')) as ssh:
   with self.assertRaises(subprocess.TimeoutExpired):execute.main()
   self.assertEqual(ssh.call_count,1);command=ssh.call_args.args[0]
   self.assertIn('BatchMode=yes',command);self.assertIn(execute.SSH_KEY,command)
   self.assertEqual((work/'execution-stdout.txt').read_bytes(),b'partial actual stdout')
   self.assertEqual((work/'execution-stderr.txt').read_bytes(),b'partial actual stderr')
   self.assertEqual(json.loads((work/'execution-exit.json').read_bytes()),{'actual_exit':'timeout'})
   with self.assertRaisesRegex(AssertionError,'existing execution'):execute.main()
   self.assertEqual(ssh.call_count,1)

 def test_optimized_refuses_both_sources(self):
  for name in ('offload','execute'):
   result=subprocess.run([sys.executable,'-O','-c','import '+name],cwd=DOCS,capture_output=True,text=True)
   self.assertNotEqual(result.returncode,0);self.assertIn('optimized Python',result.stderr)
 def test_missing_receipt_and_existing_logs_never_ssh(self):
  with patch.object(execute,'DOCS',self.root),patch.object(execute.subprocess,'run') as ssh:
   with self.assertRaises(Exception):execute.main()
  ssh.assert_not_called()

if __name__=='__main__':unittest.main()
