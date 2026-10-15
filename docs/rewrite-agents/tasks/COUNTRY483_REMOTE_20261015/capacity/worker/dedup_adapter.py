"""Render an exact29 cold-alias packet. This CLI never executes it."""
from pathlib import Path,PurePosixPath
import argparse,ast,hashlib,inspect,json,os,re,sqlite3,stat,sys

sys.dont_write_bytecode=True
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[5]
TASKS=REPO/'docs/rewrite-agents/tasks'
WORK=REPO/'.run/country483_remote_20261015/capacity-worker'
PLAN=OWN.parent/'plan.json'
PROTECTED=OWN.parent/'protected-resources.json'
PLAN_SHA='ded18e94923b44ba5a4d5dda126b4b8aeea834b10c743965e9617706f0281d3f'
PROTECTED_SHA='9052dc05fcf76728a1131cda567cd49c1e28c268c62f3e9dfb3a29e78e12a1bf'
HOUSE_SHA='2640bb0c0a5ed72dae96aeee56ca7e3df1831569c10a0649602f56fc2ed6fdb5'
GUARD_SHA='7d8637d9a646f306aa41cf90a496d3216933a4f0b8c717cc2db5b9c3e41c66d5'
BACKUPS=Path('/opt/quiz-master/backups')
IMAGE='docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'
ALIAS=re.compile(r'quiz-2026\.10\.(?:13|14)-[A-Za-z0-9._-]+\.restore-proof\.sqlite')
META={'path','sha256','integrity','bytes','allocated_bytes','dev','ino','mtime_ns','mode','uid','gid','nlink'}


def require(ok,message):
    if not ok:raise ValueError(message)


def sha(path):
    with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()


def once(text,old,new):
    require(text.count(old)==1,'historical source anchor changed: '+old)
    return text.replace(old,new)


def validate_plan(plan):
    require(plan.get('schema_version')=='qm-country483-exact-backup-dedup/v1' and plan.get('baseline_revision')==63 and
            plan.get('baseline_image')==IMAGE and plan.get('pvc_uid')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and
            plan.get('feedback_count')==29 and plan.get('feedback_sha256')=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e', 'baseline/schema differs')
    pairs=plan['pairs'];preserved=plan['preserved'];aliases=[p['alias'] for p in pairs]
    require(len(pairs)==len(set(aliases))==plan['expected_aliases']==29 and len(preserved)==185,'exact29/185 required')
    require(not set(aliases)&set(preserved) and len(plan['explicit_retention_names'])==29 and
            set(plan['explicit_retention_names'])<=set(preserved),'protected backup selected')
    all_entries=dict(preserved)
    for pair in pairs:
        alias,keeper=pair['alias'],pair['keeper']
        require(ALIAS.fullmatch(alias) is not None and keeper==alias.removesuffix('.restore-proof.sqlite')+'.sqlite' and
                pair['keeper_metadata']==preserved.get(keeper),'exact paired private keeper required')
        a,k=pair['alias_metadata'],pair['keeper_metadata']
        require(a['sha256']==k['sha256'] and a['bytes']==k['bytes'] and alias not in all_entries,'alias/keeper bytes differ')
        all_entries[alias]=a
    require(len(all_entries)==214 and sum(p['alias_metadata']['allocated_bytes'] for p in pairs)==plan['expected_allocated_reclaim']==1408114688,
            'inventory/reclaim differs')
    for name,entry in all_entries.items():
        require(set(entry)==META and re.fullmatch(r'quiz-[A-Za-z0-9._-]+\.sqlite',name) is not None and
                entry['path']==str(PurePosixPath('/opt/quiz-master/backups')/name) and entry['integrity']=='ok' and entry['mode']==0o600 and
                entry['uid']==entry['gid']==0 and entry['nlink']==1 and re.fullmatch('[0-9a-f]{64}',entry['sha256']) is not None,
                'unsafe backup metadata')
        require(all(type(entry[k]) is int and entry[k]>=0 for k in ('bytes','allocated_bytes','dev','ino','mtime_ns','mode','uid','gid','nlink')) and
                entry['bytes']>0 and entry['ino']>0 and entry['mtime_ns']>0,'invalid metadata integers')
    states={e['sha256'] for e in all_entries.values()}
    require(states=={e['sha256'] for e in preserved.values()} and len(states)==plan['retained_unique_states']==52,
            'unique SQLite state would be lost')
    require(plan.get('remote_peak_certified') is False and plan.get('execution_authorized_by_this_plan') is False and
            plan['final_free_minimum_rule']=='available*5>total and available>=total//5+1+1073741824','capacity/authority differs')
    return all_entries


def parent_marker(root):
    require(not root.is_symlink() and root.resolve()==root.absolute(),'backup parent linked')
    st=root.lstat();require(stat.S_ISDIR(st.st_mode),'backup parent not directory')
    return dict(path=str(root),dev=st.st_dev,ino=st.st_ino,mode=stat.S_IMODE(st.st_mode),uid=st.st_uid,gid=st.st_gid)


def verify_entry(path,entry):
    require(os.name=='posix' and hasattr(os,'O_NOFOLLOW'),'POSIX no-follow verification required')
    path=Path(path);st=path.lstat()
    def marker(s):
        value=dict(bytes=s.st_size,dev=s.st_dev,ino=s.st_ino,mtime_ns=s.st_mtime_ns,mode=stat.S_IMODE(s.st_mode),uid=s.st_uid,gid=s.st_gid,nlink=s.st_nlink)
        if 'allocated_bytes' in entry:value['allocated_bytes']=s.st_blocks*512
        return value
    expected={k:entry[k] for k in marker(st)}
    require(stat.S_ISREG(st.st_mode) and st.st_nlink==1 and marker(st)==expected,'backup/protected fingerprint changed')
    for suffix in ('-wal','-shm','-journal'):require(not Path(str(path)+suffix).exists() and not Path(str(path)+suffix).is_symlink(),'live journal exists')
    fd=os.open(path,os.O_RDONLY|os.O_NOFOLLOW)
    with os.fdopen(fd,'rb') as stream:
        require(marker(os.fstat(stream.fileno()))==expected,'opened identity changed')
        digest=hashlib.file_digest(stream,'sha256').hexdigest()
        require(marker(os.fstat(stream.fileno()))==expected,'identity changed during read')
    require(marker(path.lstat())==expected and not path.is_symlink() and digest==entry['sha256'],'file hash/identity changed')
    return path


def no_process_use(root):
    prefix=str(root).encode()
    for proc in Path('/proc').iterdir():
        if not proc.name.isdecimal():continue
        try:
            require(not any(prefix in arg for arg in (proc/'cmdline').read_bytes().split(b'\0')),'backup path in active process command')
            for link in (proc/'fd').iterdir():
                try:target=os.readlink(link)
                except FileNotFoundError:continue
                require(not target.startswith(str(root)+'/'),'backup open by active process')
        except (FileNotFoundError,ProcessLookupError):continue


def verify_inventory(entries,root=BACKUPS):
    observed={p.name for p in root.iterdir() if p.name.endswith('.sqlite')}
    require(observed==set(entries),'full backup membership changed')
    no_process_use(root)
    for name,entry in entries.items():verify_entry(root/name,entry)


def verify_protected(protected):
    require(protected.get('schema_version')=='qm-country483-protected-resources/v1' and len(protected['files'])==32 and
            protected.get('mutation_performed') is False and parent_marker(BACKUPS)==protected['backup_parent'],'protected resource/parent contract differs')
    for text,entry in protected['files'].items():
        path=Path(text);require(path.resolve()==path.absolute() and not path.is_symlink(),'protected path linked')
        verify_entry(path,entry)


def check_capacity(before,after=None,reclaim=1408114688):
    free,total=before['disk_available'],before['disk_total']
    require(type(free) is int and type(total) is int and free>0 and total>0,'invalid measured capacity')
    require(free+reclaim>=total//5+1+1073741824,'projected20percent plus1GiB reserve unavailable')
    if after is not None:
        require(after['disk_total']==total and after['disk_available']*5>total and
                after['disk_available']>=total//5+1+1073741824,'actual20percent plus1GiB reserve unavailable')
        require(after['disk_available']>=free+reclaim-67108864,'concurrent growth exceeded64MiB')


def run_exact(plan,protected,house_source):
    require(__debug__ and os.name=='posix','normal POSIX Python required')
    entries=validate_plan(plan);verify_protected(protected);verify_inventory(entries)
    require(not {str(BACKUPS/p['alias']) for p in plan['pairs']}&set(protected['files']),'protected resource selected')
    require(parent_marker(BACKUPS)==protected['backup_parent'],'backup parent changed')
    env={'__name__':'qm_exact_backup_house'};exec(compile(house_source,'pinned-deduplicate.py','exec'),env)
    original=env['check'];before=None;images=None;alias_checks={p['alias']:0 for p in plan['pairs']}
    def checked(name,group):
        nonlocal before,images
        require(parent_marker(BACKUPS)==protected['backup_parent'],'backup parent changed')
        require(name in entries and entries[name]['bytes']==group['bytes'] and entries[name]['sha256']==group['sha256'],'house check outside plan')
        no_process_use(BACKUPS)
        verify_entry(BACKUPS/name,entries[name]);original(name,group)
        if name in alias_checks:
            alias_checks[name]+=1
            # The pinned house loop checks each alias once in full validation, then immediately before unlink.
            if alias_checks[name]==2 and images is None:
                before=preflight();check_capacity(before);images=loaded_images()
                print(json.dumps({'phase':'before_unlink','observed':before,'loaded_images':inventory_summary(images)}),flush=True)
        return verify_entry(BACKUPS/name,entries[name])
    env['check']=checked
    groups=[dict(keeper=p['keeper'],duplicates=[p['alias']],bytes=p['alias_metadata']['bytes'],sha256=p['alias_metadata']['sha256']) for p in plan['pairs']]
    preflight()
    receipt=env['run']({'schema_version':'qm-cold-backup-dedup/v1','expected_files':58,'groups':groups})
    require(before is not None and images is not None,'fresh pre-unlink snapshot missing')
    verify_inventory(plan['preserved']);verify_protected(protected)
    require(len(receipt['removed_aliases'])==29 and {r['removed'] for r in receipt['removed_aliases']}=={p['alias'] for p in plan['pairs']},'removed mapping differs')
    current=loaded_images();images_preserved(images,current);after=preflight();check_capacity(before,after)
    print(json.dumps({'status':'EXACT29_BACKUP_ALIASES_REMOVED','removed_count':29,'allocated_reclaim':1408114688,
       'preserved_backups':185,'unique_states_retained':52,'before':before,'after':after,'loaded_images':inventory_summary(current),
       'loaded_image_additions':{k:len(current[k]-images[k]) for k in images},'preexisting_loaded_images_preserved':True,
       'protected_files_preserved':32,'remote_peak_certified':False,'release_capacity_still_required':True}),flush=True)


def sources():
    house=TASKS/'CAPACITY_RECOVERY_20261015/deduplicate.py';guard=TASKS/'READER303_CAPACITY_20261015/offload-v1/offload.py'
    require(sha(house)==HOUSE_SHA and sha(guard)==GUARD_SHA,'historical dependency changed')
    text=house.read_text();text=once(text,r'quiz-2026\.10\.12-',r'quiz-2026\.10\.(?:13|14)-')
    tree=ast.parse(guard.read_text());names={'preflight','loaded_images','images_preserved','inventory_summary'}
    selected='\n\n'.join(ast.get_source_segment(guard.read_text(),node) for node in tree.body if isinstance(node,ast.FunctionDef) and node.name in names)
    require(sum(isinstance(n,ast.FunctionDef) and n.name in names for n in tree.body)==4,'house guard function set changed')
    selected=once(selected,"h['version'] == 62","h['version'] == 63")
    selected=once(selected,"'helm_revision': 62","'helm_revision': 63")
    selected=once(selected,'docker.io/library/quiz-master@sha256:e053b4c42c600a062d2dfff5c5152ccc70ff86b2d97b4f91b9784af7c8fc46d4',IMAGE)
    selected=once(selected,'available * 5 >= total','available * 5 > total')
    return text,selected


def fixture_source(house):
    tests=TASKS/'CAPACITY_RECOVERY_20261015/test_deduplicate.py'
    require(sha(tests)=='d1637bc23fa9e0fb261171d8acc4354eaa43e1a75f48db6fa408f4b6160bde2f','historical fixture source changed')
    old_tests=tests.read_text().replace('2026.10.12-','2026.10.13-')
    code='import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat\nfrom pathlib import Path\n'
    code+='module=types.ModuleType("deduplicate")\nexec('+repr(house)+',module.__dict__)\nsys.modules["deduplicate"]=module\n'
    code+='\n'.join(inspect.getsource(fn) for fn in (require,verify_entry,no_process_use))
    code+='\n'+old_tests+'\n'+(OWN/'linux_fixture_tests.py').read_text()
    code+='\nsuite=unittest.TestSuite([unittest.defaultTestLoader.loadTestsFromTestCase(DedupTests),unittest.defaultTestLoader.loadTestsFromTestCase(FingerprintTests)])\nresult=unittest.TextTestRunner(verbosity=2).run(suite)\nraise SystemExit(0 if result.wasSuccessful() else 1)\n'
    compile(code,'isolated-linux-fixture','exec')
    return "set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\npython3 - <<'COUNTRY483_FIXTURE'\n__name__='qm_isolated_fixture'\n"+code+'\nCOUNTRY483_FIXTURE\n'


def render(output):
    require(__debug__,'optimized Python forbidden')
    require(sha(PLAN)==PLAN_SHA and sha(PROTECTED)==PROTECTED_SHA,'Root input changed')
    plan=json.loads(PLAN.read_text());protected=json.loads(PROTECTED.read_text());validate_plan(plan)
    house,guard=sources()
    imports='from pathlib import Path,PurePosixPath\nimport hashlib,json,os,re,sqlite3,stat\n'
    constants=''.join(name+'='+repr(globals()[name])+'\n' for name in ('IMAGE','META'))
    constants+="BACKUPS=Path('/opt/quiz-master/backups')\nROOT=PurePosixPath(str(BACKUPS))\nALIAS=re.compile("+repr(ALIAS.pattern)+')\n'
    core='\n\n'.join(inspect.getsource(fn) for fn in (require,validate_plan,parent_marker,verify_entry,no_process_use,verify_inventory,verify_protected,check_capacity,run_exact))
    body=imports+constants+guard+'\n'+core+'\nplan='+repr(plan)+'\nprotected='+repr(protected)+'\nhouse_source='+repr(house)+'\nrun_exact(plan,protected,house_source)\n'
    compile(body,'country483-exact29','exec')
    shell="set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\ntest \"$(hostname)\" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\npython3 - <<'COUNTRY483_DEDUP'\nif not __debug__: raise RuntimeError('optimized Python forbidden')\n"+body+'\nCOUNTRY483_DEDUP\n'
    output=Path(output)
    require(output.resolve().is_relative_to(WORK) and output.resolve()!=WORK.resolve() and not output.exists(),'fresh owned output required')
    require(all(not p.is_symlink() and not p.is_junction() for p in (output,*output.parents)),'linked output forbidden')
    output.mkdir(parents=True);(output/'deduplicate.sh').write_bytes(shell.encode())
    (output/'linux-fixture-PENDING.sh').write_bytes(fixture_source(house).encode())
    proof=dict(status='LOCAL_RENDER_ONLY',plan_sha256=PLAN_SHA,protected_sha256=PROTECTED_SHA,house_sha256=HOUSE_SHA,guard_sha256=GUARD_SHA,
               shell_sha256=sha(output/'deduplicate.sh'),selected=29,preserved=185,unique_states=52,allocated_reclaim=1408114688,
               source_sha256={p.name:sha(p) for p in OWN.glob('*.py')},actual_cleanup_performed=False,execution_authorized=False,
               independent_review_required=True,posix_fixture_execution='PENDING_ROOT_AFTER_REVIEW',fixture_sha256=sha(output/'linux-fixture-PENDING.sh'))
    (output/'preview.json').write_text(json.dumps(proof,indent=2)+'\n');return proof


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output-root',type=Path,required=True)
    print(json.dumps(render(parser.parse_args().output_root)))
