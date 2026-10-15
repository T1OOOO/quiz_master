"""Compose the separate exact111 packet locally; never execute remote operations."""
from pathlib import Path,PurePosixPath
import argparse,ast,hashlib,importlib.util,inspect,json,os,re,sqlite3,stat,sys
sys.dont_write_bytecode=True
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[6]
CAPACITY=OWN.parents[1]
PLAN=OWN.parent/'plan.json'
PLAN_SHA='f5155427154539df181dbc9f526eabe551ef59f85639ecbd5be8f3b0755e3436'
PROTECTED=CAPACITY/'protected-resources.json'
PROTECTED_SHA='9052dc05fcf76728a1131cda567cd49c1e28c268c62f3e9dfb3a29e78e12a1bf'
COMPOSER=CAPACITY/'adapter-v2/compose_adapter.py'
COMPOSER_SHA='5bebdf180218b63592c8f944b41613dc9aa90f4e35a82efc664bf839fcd75cc5'
WORK=REPO/'.run/country483_remote_20261015/remaining-worker'
BACKUPS=Path('/opt/quiz-master/backups')
IMAGE='docker.io/library/quiz-master@sha256:6c603a840b01c9c4605eba234e4af3d95a3f52fff12e65d9904b563db5722f14'
META={'path','sha256','integrity','bytes','allocated_bytes','dev','ino','mtime_ns','mode','uid','gid','nlink'}

def require(ok,message):
    if not ok:raise ValueError(message)

def sha(path):
    with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def digest(text):return hashlib.sha256(text.encode()).hexdigest()

def selected_names(plan):
    return [name for group in plan['groups'] for name in [group['keeper'],*group['aliases']]]

def validate_plan(plan):
    require(__debug__,'optimized Python forbidden')
    require(plan.get('schema_version')=='qm-country483-remaining-exact-dedup/v1' and plan.get('baseline_revision')==63 and
            plan.get('baseline_image')==IMAGE and plan.get('pvc_uid')=='7fc2428f-4146-4c78-a26d-2347d9f3b7bf' and
            plan.get('feedback_count')==29 and plan.get('feedback_sha256')=='452929a2ea8dc34600eff8039571e2b0479ec7ad1ec52fa6e271b5c71008030e','baseline/schema differs')
    require(plan.get('previous_actual_exit')==1 and plan.get('previous_actual_removed')==29 and plan.get('previous_preserved185_verified') is True and
            plan.get('source_plan_sha256')=='ded18e94923b44ba5a4d5dda126b4b8aeea834b10c743965e9617706f0281d3f','previous failed-reserve binding differs')
    entries,preserved,groups=plan['entries'],plan['preserved'],plan['groups']
    require(len(entries)==plan['expected_entries']==185 and len(preserved)==plan['expected_preserved']==74 and len(groups)==47,'exact185/74/47 required')
    names=selected_names(plan);aliases=[a for g in groups for a in g['aliases']]
    require(len(names)==len(set(names))==158 and len(aliases)==plan['expected_aliases']==111,'exact111 disjoint aliases required')
    require(set(entries)-set(aliases)==set(preserved) and all(entries[n]==e for n,e in preserved.items()),'preserved metadata differs')
    require(len(plan['explicit_retention_names'])==len(set(plan['explicit_retention_names']))==29 and
            set(plan['explicit_retention_names'])<=set(preserved),'retained backup selected')
    for name,e in entries.items():
        require(set(e)==META and re.fullmatch(r'quiz-[A-Za-z0-9._-]+\.sqlite',name) is not None and
                e['path']==str(PurePosixPath('/opt/quiz-master/backups')/name) and e['integrity']=='ok' and
                e['mode']==0o600 and e['uid']==e['gid']==0 and e['nlink']==1 and re.fullmatch('[0-9a-f]{64}',e['sha256']) is not None,'unsafe backup metadata')
        require(all(type(e[k]) is int and e[k]>=0 for k in ('bytes','allocated_bytes','dev','ino','mtime_ns','mode','uid','gid','nlink')) and
                e['bytes']>0 and e['ino']>0 and e['mtime_ns']>0,'invalid metadata integers')
    for g in groups:
        require(set(g)=={'keeper','aliases','sha256','bytes'} and g['aliases'] and g['keeper'] in preserved,'invalid retained group')
        require(all(n in entries and entries[n]['sha256']==g['sha256'] and entries[n]['bytes']==g['bytes'] for n in [g['keeper'],*g['aliases']]),'alias/keeper bytes differ')
    require(sum(entries[n]['allocated_bytes'] for n in aliases)==plan['expected_allocated_reclaim']==4795174912,'allocated reclaim differs')
    states={e['sha256'] for e in entries.values()}
    require(states=={e['sha256'] for e in preserved.values()} and len(states)==plan['retained_unique_states']==52,'database state would be lost')
    require(plan.get('minimum_post_headroom_bytes')==2147483648 and plan.get('maximum_concurrent_growth_bytes')==1073741824 and
            plan.get('execution_authorized_by_this_plan') is False and plan.get('remote_peak_certified') is False,'capacity/authority differs')
    return entries

def check_capacity(before,after=None,reclaim=4795174912):
    free,total=before['disk_available'],before['disk_total']
    require(type(free) is int and type(total) is int and free>0 and total>0,'invalid observed capacity')
    minimum=total//5+1+2147483648
    require(free+reclaim>=minimum,'projected strict20 plus2GiB unavailable')
    if after is not None:
        actual=after['disk_available']
        require(type(actual) is int and type(after['disk_total']) is int and after['disk_total']==total and
                actual*5>total and actual>=minimum,'actual strict20 plus2GiB unavailable')
        require(actual>=free+reclaim-1073741824,'concurrent growth exceeded1GiB')

def execute_groups(entries,groups,parent,house_source,before_unlink):
    """Keep the pinned all-groups-first house loop; replace its redundant reads with one stronger fingerprint read."""
    env={'__name__':'qm_remaining_house'};exec(compile(house_source,'closed-exact-house.py','exec'),env)
    env['BACKUPS']=BACKUPS
    allowed=[n for g in groups for n in [g['keeper'],*g['aliases']]]
    require(len(allowed)==len(set(allowed)),'duplicate selected name')
    require(all(env['NAME'].fullmatch(n) for n in allowed),'selected name outside exact allowlist')
    counts={n:0 for g in groups for n in g['aliases']};started=False
    def checked(name,group):
        nonlocal started
        require(parent_marker(BACKUPS)==parent,'backup parent changed')
        require(name in allowed and env['NAME'].fullmatch(name) and entries[name]['mode']==0o600 and
                entries[name]['uid']==os.geteuid() and entries[name]['nlink']==1 and
                entries[name]['bytes']==group['bytes'] and entries[name]['sha256']==group['sha256'],'house check outside private frozen group')
        if name in counts:
            counts[name]+=1
            if counts[name]==2 and not started:
                before_unlink();started=True
        no_process_use(BACKUPS)
        result=verify_entry(BACKUPS/name,entries[name])
        require(parent_marker(BACKUPS)==parent,'backup parent changed before unlink')
        return result
    env['check']=checked
    receipt=env['run']({'schema_version':'qm-cold-backup-dedup/v1','expected_files':len(allowed),
        'groups':[dict(keeper=g['keeper'],duplicates=g['aliases'],bytes=g['bytes'],sha256=g['sha256']) for g in groups]})
    require(started and all(c==2 for c in counts.values()),'house alias-check sequence changed')
    expected={a:(g['keeper'],g['sha256'],g['bytes']) for g in groups for a in g['aliases']}
    actual={r['removed']:(r['restore_from'],r['sha256'],r['bytes']) for r in receipt['removed_aliases']}
    require(len(receipt['removed_aliases'])==len(expected) and actual==expected,'flushed removal mapping differs')
    return receipt

def run_remaining(plan,protected,house_source):
    require(__debug__ and os.name=='posix' and os.geteuid()==0,'normal root POSIX Python required')
    entries=validate_plan(plan)
    require(os.stat(BACKUPS).st_dev==os.stat('/var/lib/rancher/k3s/agent/containerd').st_dev,'backups not on measured filesystem')
    aliases={a for g in plan['groups'] for a in g['aliases']}
    require(not {str(BACKUPS/a) for a in aliases}&set(protected['files']),'protected resource selected')
    preflight();verify_protected(protected);verify_inventory(entries,BACKUPS)
    before=None;images=None
    def snapshot():
        nonlocal before,images
        before=preflight();check_capacity(before);images=loaded_images()
        print(json.dumps({'phase':'before_first_unlink','observed':before,'loaded_images':inventory_summary(images)}),flush=True)
    receipt=execute_groups(entries,plan['groups'],protected['backup_parent'],house_source,snapshot)
    verify_inventory(plan['preserved'],BACKUPS);verify_protected(protected)
    require(len({e['sha256'] for e in plan['preserved'].values()})==52,'retained state count differs')
    current=loaded_images();images_preserved(images,current)
    after=preflight()
    print(json.dumps({'phase':'post_preservation_before_capacity','removed_count':len(receipt['removed_aliases']),
          'preserved_backups':74,'unique_states_retained':52,'protected_files_preserved':32,
          'before':before,'after':after,'loaded_images':inventory_summary(current),
          'loaded_image_additions':{k:len(current[k]-images[k]) for k in images},'preexisting_loaded_images_preserved':True}),flush=True)
    check_capacity(before,after)
    print(json.dumps({'status':'EXACT111_REMAINING_ALIASES_REMOVED','allocated_reclaim':4795174912,'removed_count':111,
        'minimum_post_headroom_bytes':2147483648,'maximum_concurrent_growth_bytes':1073741824,
        'remote_peak_certified':False,'release_capacity_still_required':True}),flush=True)

def dependencies(plan):
    require(__debug__ and sha(COMPOSER)==COMPOSER_SHA,'immutable lifetime composer changed or optimized Python')
    spec=importlib.util.spec_from_file_location('accepted_lifetime_composer',COMPOSER)
    composer=importlib.util.module_from_spec(spec);spec.loader.exec_module(composer)
    v1,_,_,house,guard,house_exprs,guard_exprs=composer.inputs()
    require(len(house_exprs)==1 and len(guard_exprs)==2,'three owned closes required')
    require(digest(house)=='c32104d26bb7f8306742341f8c78005431783986460c9fae33348097cbd57524' and
            digest(guard)=='17c604f7bb718aa8e8f0af3b9cb42e24622cd1594f388805c8a94a8949e560cb','patched dependency changed')
    line=next(n for n in house.splitlines() if n.startswith('NAME=re.compile('))
    pattern='(?:'+'|'.join(re.escape(n) for n in sorted(selected_names(plan)))+')'
    house=composer.once(house,line,'NAME=re.compile('+repr(pattern)+')')
    proof=dict(owned_contexts_closed=dict(house=1,preflight=2),exact_allowlist_count=len(selected_names(plan)),
               exact_house_sha256=digest(house),closed_guard_sha256=digest(guard),composer_sha256=COMPOSER_SHA)
    return house,(v1,guard),proof

def core(plan):
    house,(v1,guard),proof=dependencies(plan)
    imports='from pathlib import Path,PurePosixPath\nimport hashlib,json,os,re,sqlite3,stat\n'
    constants='IMAGE='+repr(IMAGE)+'\nMETA=set('+repr(sorted(META))+')\nBACKUPS=Path("/opt/quiz-master/backups")\nROOT=PurePosixPath("/opt/quiz-master/releases")\n'
    physical='\n\n'.join(inspect.getsource(getattr(v1,n)) for n in ('parent_marker','verify_entry','no_process_use','verify_inventory','verify_protected'))
    local='\n\n'.join(inspect.getsource(f) for f in (require,selected_names,validate_plan,check_capacity,execute_groups,run_remaining))
    return imports+constants+guard+'\n'+physical+'\n'+local+'\nhouse_source='+repr(house)+'\n',proof

def render(output):
    require(__debug__ and sha(PLAN)==PLAN_SHA and sha(PROTECTED)==PROTECTED_SHA,'Root immutable input changed or optimized Python')
    plan=json.loads(PLAN.read_text());validate_plan(plan);protected=json.loads(PROTECTED.read_text())
    body,proof=core(plan)
    body+='\nplan='+repr(plan)+'\nprotected='+repr(protected)+'\nrun_remaining(plan,protected,house_source)\n'
    compile(body,'remaining111','exec')
    shell='set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\ntest "$(hostname)" = racknerd-f0269d5\nexec 8>/opt/quiz-master/DEPLOY.lock\nflock -n 8\npython3 - <<\'REMAINING111\'\nif not __debug__: raise RuntimeError("optimized Python forbidden")\n'+body+'\nREMAINING111\n'
    fixture_body,_=core(plan)
    fixture_names=[[g['keeper'],*g['aliases'][:2]] for g in plan['groups'] if len(g['aliases'])>=2][:2]
    require(len(fixture_names)==2 and all(len(n)==3 for n in fixture_names),'two multialias fixture groups required')
    fixture_body+='\nFIXTURE_NAMES='+repr(fixture_names)+'\n'+(OWN/'posix_fixture.py').read_text()
    compile(fixture_body,'isolated-multialias','exec')
    fixture='set -euo pipefail\nunset PYTHONOPTIMIZE PYTHONSTARTUP\npython3 - <<\'REMAINING_FIXTURE\'\n'+fixture_body+'\nREMAINING_FIXTURE\n'
    output=Path(output)
    require(output.resolve().is_relative_to(WORK) and output.resolve()!=WORK.resolve() and not output.exists(),'fresh owned output required')
    require(all(not p.is_symlink() and not p.is_junction() for p in (output,*output.parents)),'linked output forbidden')
    output.mkdir(parents=True)
    for name,text in [('remaining111.sh',shell),('isolated-posix-PENDING.sh',fixture)]:
        (output/name).write_bytes(text.encode());proof[name+'_sha256']=digest(text)
    proof.update(status='LOCAL_RENDER_ONLY',plan_sha256=PLAN_SHA,protected_sha256=PROTECTED_SHA,
        actual_cleanup_performed=False,execution_authorized=False,posix_fixture='PENDING_ROOT_EXECUTION',remote_peak_certified=False,
        source_sha256={p.name:sha(p) for p in OWN.glob('*.py')})
    (output/'preview.json').write_text(json.dumps(proof,indent=2)+'\n');return proof

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output-root',type=Path,required=True)
    print(json.dumps(render(parser.parse_args().output_root)))
