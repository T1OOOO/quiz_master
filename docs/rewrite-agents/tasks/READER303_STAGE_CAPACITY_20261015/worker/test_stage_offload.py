"""Isolated temporary-tree tests; no remote or real release artifact is modified."""
import copy,hashlib,importlib.util,io,json,os,subprocess,sys,tarfile,tempfile,unittest
from pathlib import Path,PurePosixPath
from unittest.mock import patch
from contextlib import redirect_stdout,ExitStack
import stage_offload as stage
PRODUCTION_CONSTANTS={name:copy.deepcopy(getattr(stage,name)) for name in ('RELEASE_ROOT','COLD_ROOT','EXPECTED_PROTECTED_FILES','FAILED_ARCHIVE_SHA256')}

class StageOffloadTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.base=Path(self.temp.name).resolve()
  self.release=self.base/'releases';self.cold=self.base/'cold';self.release.mkdir();self.cold.mkdir()
  self.prepared=self.release/stage.PREPARED_NAME;self.prepared.mkdir();(self.prepared/'runtime.json').write_bytes(b'prepared runtime must remain')
  self.protected={}
  for i in range(30):
   p=self.base/('protected-'+str(i));p.write_bytes(('protected'+str(i)).encode());self.protected[p.as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
  self.proc=self.base/'proc';self.proc.mkdir();self.mount=self.base/'mountinfo';self.mount.write_text('1 0 0:0 / / rw - tmpfs tmpfs rw\n')
  self.stack=ExitStack();self.addCleanup(self.stack.close)
  for key,value in [('RELEASE_ROOT',PurePosixPath(self.release.as_posix())),('COLD_ROOT',PurePosixPath(self.cold.as_posix())),('EXPECTED_PROTECTED_FILES',self.protected),('PROC_ROOT',self.proc),('MOUNT_INFO',self.mount)]:self.stack.enter_context(patch.object(stage,key,value))
  trees=[]
  for name in sorted(stage.COLD_NAMES):
   directory=self.release/name;directory.mkdir();(directory/'nested').mkdir();(directory/'nested/file.txt').write_bytes(('cold fixture '+name).encode())
   trees.append(self.tree(directory))
   with tarfile.open(self.cold/(name+'.tar.gz'),'w:gz') as archive:archive.add(directory,arcname=name)
  old=self.release/(stage.FAILED_NAME+'.tar.gz');old.write_bytes(b'old failed package unit fixture')
  self.stack.enter_context(patch.object(stage,'FAILED_ARCHIVE_SHA256',hashlib.sha256(old.read_bytes()).hexdigest()))
  archives=[stage.fingerprint(p) for p in sorted(self.cold.iterdir())]+[stage.fingerprint(old)]
  self.plan={'schema_version':'qm-reader303-stage-cold-offload/v1','trees':trees,'archives':archives,'protected_files':self.protected,'protected_tree':self.tree(self.prepared),'release_parent':stage.fingerprint(self.release),'cold_parent':stage.fingerprint(self.cold),'total_allocated_bytes':sum(e['blocks'] for t in trees for e in t['entries'])+sum(e['blocks'] for e in archives)}
 def tearDown(self):self.temp.cleanup()
 def tree(self,path):return {'root':path.as_posix(),'entries':[stage.fingerprint(p) for p in sorted([path,*path.rglob('*')],key=lambda p:p.as_posix())]}
 def test_valid_exact_tree_archive_contract_and_complete_tars(self):
  self.assertEqual(len(stage.validate_plan(self.plan)),len([e for t in self.plan['trees'] for e in t['entries']])+10)
  for tree in self.plan['trees']:
   stage.verify_tree(tree)
   archive=next(e for e in self.plan['archives'] if e['path']==str(stage.COLD_ROOT/(Path(tree['root']).name+'.tar.gz')))
   stage.verify_archive(tree,archive)
 def test_unordered_complete_manifest_is_accepted_but_duplicate_or_missing_parent_is_refused(self):
  unordered=copy.deepcopy(self.plan)
  for tree in [*unordered['trees'],unordered['protected_tree']]:tree['entries'].reverse()
  self.assertEqual(set(stage.validate_plan(unordered)),set(stage.validate_plan(self.plan)))
  for tree in unordered['trees']:stage.verify_tree(tree)
  duplicate=copy.deepcopy(unordered);duplicate['trees'][0]['entries'].append(copy.deepcopy(duplicate['trees'][0]['entries'][0]))
  with self.assertRaises(AssertionError):stage.validate_plan(duplicate)
  missing=copy.deepcopy(unordered);tree=missing['trees'][0]
  tree['entries']=[e for e in tree['entries'] if e['path']!=tree['root']+'/nested']
  with self.assertRaises((AssertionError,KeyError)):stage.validate_plan(missing)
 def test_actual_root_plan_validates_and_renders_without_runtime_operations(self):
  path=Path(__file__).parents[1]/'plan.json';plan=json.loads(path.read_bytes())
  with patch.multiple(stage,**PRODUCTION_CONSTANTS):
   removal=stage.validate_plan(plan)
   self.assertEqual(len(plan['trees']),9);self.assertEqual(len(plan['archives']),10);self.assertEqual(len(plan['protected_files']),30)
   self.assertEqual(sum(len(t['entries']) for t in plan['trees']),3558)
   self.assertEqual(plan['total_allocated_bytes'],2084999168)
   guard=(Path(__file__).parents[2]/'READER303_CAPACITY_20261015/offload-v1/offload.py').read_text()
   shell=stage.render(plan,guard)
   self.assertIn('run_stage_offload(plan)',shell)
   self.assertEqual(len(removal),3568)

 def test_positive_removal_touches_only_isolated_fixture_and_preserves_prepared(self):
  protected={p:stage.fingerprint(p) for p in self.protected};prepared=self.tree(self.prepared)
  with redirect_stdout(io.StringIO()):removed=stage.remove_cold(self.plan)
  self.assertEqual(set(removed),set(stage.validate_plan(self.plan)))
  self.assertTrue(all(not Path(path).exists() for path in removed))
  self.assertEqual(self.tree(self.prepared),prepared)
  self.assertEqual({p:stage.fingerprint(p) for p in self.protected},protected)
  self.assertTrue(self.release.is_dir() and self.cold.is_dir())
 def test_reject_wrong_root_prepared_root_duplicate_and_path_escape(self):
  for mutation in ('prepared','normal','duplicate','escape','extra_archive','missing_protected','allocated'):
   bad=copy.deepcopy(self.plan)
   if mutation=='prepared':bad['trees'][0]['root']=self.prepared.as_posix()
   if mutation=='normal':bad['trees'][0]['root']=(self.release/'normal-release').as_posix()
   if mutation=='duplicate':bad['trees'][1]=copy.deepcopy(bad['trees'][0])
   if mutation=='escape':bad['trees'][0]['entries'][-1]['path']=bad['trees'][0]['root']+'/../escape'
   if mutation=='extra_archive':bad['archives'][0]['path']=(self.release/'protected-live.tar.gz').as_posix()
   if mutation=='missing_protected':bad['protected_files'].pop(next(iter(bad['protected_files'])))
   if mutation=='allocated':bad['total_allocated_bytes']+=1
   with self.subTest(mutation=mutation),self.assertRaises((AssertionError,KeyError)):stage.validate_plan(bad)
 def test_entry_hash_metadata_and_nlink_drift_prevent_any_removal(self):
  for field,value in [('sha256','0'*64),('ino',123),('mtime_ns',1),('mode',0),('nlink',2),('uid',123)]:
   bad=copy.deepcopy(self.plan);bad['trees'][0]['entries'][-1][field]=value
   with self.subTest(field=field),patch.object(os,'unlink') as unlink,patch.object(os,'rmdir') as rmdir,self.assertRaises(AssertionError):stage.remove_cold(bad)
   unlink.assert_not_called();rmdir.assert_not_called()
 def test_extra_actual_member_and_wrong_cold_hash_prevent_any_removal(self):
  path=Path(self.plan['trees'][0]['root'])/'unlisted';path.write_bytes(b'foreign extra member')
  with patch.object(os,'unlink') as unlink,self.assertRaises(AssertionError):stage.remove_cold(self.plan)
  unlink.assert_not_called()
  path.unlink();self.plan['trees'][0]=self.tree(path.parent);self.plan['release_parent']=stage.fingerprint(self.release)
  bad=copy.deepcopy(self.plan);bad['archives'][0]['sha256']='0'*64
  with patch.object(os,'unlink') as unlink,self.assertRaises(AssertionError):stage.remove_cold(bad)
  unlink.assert_not_called()
 def test_incomplete_archive_rejected_even_if_its_physical_hash_is_rebound(self):
  archive=Path(self.plan['archives'][0]['path'])
  with tarfile.open(archive,'w:gz') as tar:pass
  self.plan['archives'][0]=stage.fingerprint(archive);self.plan['cold_parent']=stage.fingerprint(self.cold)
  self.plan['total_allocated_bytes']=sum(e['blocks'] for t in self.plan['trees'] for e in t['entries'])+sum(e['blocks'] for e in self.plan['archives'])
  with patch.object(os,'unlink') as unlink,self.assertRaises(AssertionError):stage.remove_cold(self.plan)
  unlink.assert_not_called()
 def test_parent_change_is_detected_immediately_before_unlink(self):
  real=stage.stable_directory
  def changed(entry):
   if entry['path']==self.plan['trees'][0]['root']:raise AssertionError('changed parent')
   return real(entry)
  with patch.object(stage,'stable_directory',side_effect=changed),patch.object(os,'unlink') as unlink,self.assertRaisesRegex(AssertionError,'changed parent'):stage.remove_cold(self.plan)
  unlink.assert_not_called()
 def test_symlink_and_special_file_are_rejected(self):
  path=Path(self.plan['trees'][0]['entries'][-1]['path'])
  with patch.object(Path,'is_symlink',return_value=True),self.assertRaises(AssertionError):stage.fingerprint(path)
  info=path.lstat();attributes={name:getattr(info,name) for name in ['st_dev','st_ino','st_size','st_mtime_ns','st_nlink','st_uid','st_gid']};attributes['st_mode']=0o010644
  from types import SimpleNamespace
  with patch.object(Path,'lstat',return_value=SimpleNamespace(**attributes)),self.assertRaises(AssertionError):stage.fingerprint(path)
 def test_process_command_cwd_exe_and_submount_guards(self):
  pid=self.proc/'123';pid.mkdir();command=pid/'cmdline';command.write_bytes(b'other-process')
  for field in ('cmdline','cwd','exe'):
   command.write_bytes((self.plan['trees'][0]['root'] if field=='cmdline' else 'other-process').encode())
   def link(path):return self.plan['trees'][0]['root'] if Path(path).name==field else '/unrelated'
   with self.subTest(field=field),patch.object(os,'readlink',side_effect=link),self.assertRaisesRegex(AssertionError,'process'):stage.assert_idle(self.plan)
  command.write_bytes(b'other-process')
  self.mount.write_text('1 0 0:0 / '+self.plan['trees'][0]['root']+'/nested rw - tmpfs tmpfs rw\n')
  with patch.object(os,'readlink',return_value='/unrelated'),self.assertRaisesRegex(AssertionError,'submount'):stage.assert_idle(self.plan)
 def guard(self):
  path=Path(__file__).parents[2]/'READER303_CAPACITY_20261015/offload-v1/offload.py'
  spec=importlib.util.spec_from_file_location('accepted_stage_guard',path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
 def test_unchanged_guard_capacity_boundaries_and_inventory_subset(self):
  guard=self.guard();before={'disk_available':20000000000,'disk_total':100000000000};reclaim=1518083884
  guard.check_capacity(before,reclaim=reclaim)
  for available in (20000000000+guard.GIB-1,20000000000+guard.GIB):
   with self.subTest(available=available),self.assertRaises(AssertionError):guard.check_capacity(before,dict(before,disk_available=available),reclaim)
  good=dict(before,disk_available=before['disk_available']+reclaim-guard.GROWTH_LIMIT);guard.check_capacity(before,good,reclaim)
  with self.assertRaises(AssertionError):guard.check_capacity(before,dict(good,disk_available=good['disk_available']-1),reclaim)
  inventory={'containerd':{('private-ref','digest')},'docker':{('private-tag','digest','id')}}
  guard.images_preserved(inventory,{k:rows|{('new','image')} for k,rows in inventory.items()})
  with self.assertRaises(AssertionError):guard.images_preserved(inventory,{'containerd':set(),'docker':inventory['docker']})
 def test_orchestration_uses_fresh_pre_post_guards_and_private_inventory_summaries(self):
  guard=self.guard();before={'disk_available':23000000000,'disk_total':100000000000};after=dict(before,disk_available=before['disk_available']+self.plan['total_allocated_bytes'])
  inventory={'containerd':{('private-ref','digest')},'docker':{('private-tag','digest','id')}}
  def remove(plan,before_mutation):before_mutation();return list(stage.validate_plan(plan))
  def stat_path(path):return type('Device',(),{'st_dev':1})()
  with ExitStack() as stack:
   pre=stack.enter_context(patch.object(stage,'guard_preflight',side_effect=[before,before,after],create=True))
   protected=stack.enter_context(patch.object(stage,'guard_verify_protected',create=True))
   images=stack.enter_context(patch.object(stage,'guard_loaded_images',return_value=inventory,create=True))
   stack.enter_context(patch.object(stage,'guard_images_preserved',side_effect=guard.images_preserved,create=True))
   stack.enter_context(patch.object(stage,'guard_inventory_summary',side_effect=guard.inventory_summary,create=True))
   stack.enter_context(patch.object(stage,'guard_check_capacity',side_effect=guard.check_capacity,create=True))
   stack.enter_context(patch.object(stage,'PROTECTED_HASHES',guard.PROTECTED_HASHES,create=True))
   stack.enter_context(patch.object(stage,'remove_cold',side_effect=remove));stack.enter_context(patch.object(os,'stat',side_effect=stat_path))
   output=io.StringIO()
   with redirect_stdout(output):stage.run_stage_offload(self.plan)
  self.assertEqual(pre.call_count,3);self.assertEqual(protected.call_count,2);self.assertEqual(images.call_count,2)
  self.assertNotIn('private-ref',output.getvalue());self.assertNotIn('private-tag',output.getvalue())
  self.assertIn('EXACT_FAILED_STAGES_OFFLOADED',output.getvalue())
 def test_after_callback_changed_bytes_with_same_size_and_mtime_still_refused(self):
  entry=min(self.plan['archives'],key=lambda e:e['path']);path=Path(entry['path'])
  def corrupt():
   path.write_bytes(b'x'*entry['size']);os.utime(path,ns=(entry['mtime_ns'],entry['mtime_ns']))
  with patch.object(os,'unlink') as unlink,self.assertRaises(AssertionError):stage.remove_cold(self.plan,before_mutation=corrupt)
  unlink.assert_not_called()

 def test_render_guard_hash_imports_modes_and_embedded_python(self):
  guard=Path(__file__).parents[2]/'READER303_CAPACITY_20261015/offload-v1/offload.py';source=guard.read_text()
  shell=stage.render(self.plan,source)
  self.assertIn('flock -n 8',shell);self.assertIn('run_stage_offload(plan)',shell)
  self.assertNotIn('shutil.rmtree',shell)
  body=shell.split("<<'READER303_STAGE_OFFLOAD'\n",1)[1].rsplit('\nREADER303_STAGE_OFFLOAD',1)[0];compile(body,'unit-render','exec')
  result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=shell.encode(),capture_output=True)
  self.assertEqual(result.returncode,0,result.stderr.decode())
  with self.assertRaisesRegex(AssertionError,'guard source'):stage.render(self.plan,source+'\n#changed')
  result=subprocess.run([sys.executable,'-O','-c','import stage_offload'],cwd=Path(__file__).parent,capture_output=True,text=True)
  self.assertNotEqual(result.returncode,0);self.assertIn('optimized Python',result.stderr)

if __name__=='__main__':unittest.main()
