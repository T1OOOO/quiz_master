"""Produce a new exact snapshot from an already verified archive after removals.

Never deletes sources. Added/changed files, permissions, ownership, links or xattrs
require a fresh ordinary archive; only removed entries and directory times/sizes
can be reconciled by this helper. Original archives remain immutable.
"""
from pathlib import Path,PurePosixPath
import argparse,copy,importlib.util,json,os,tarfile

BACKUP=Path('E:/Backups/quiz-master/server-20261021')
CONTROLLER=BACKUP/'controller-source/archive_orchestrator-v2.py'
CONTROLLER_SHA='dde03ca072f5765ef9b91a1f81ea5fd085054fe51a8eb5bd928614373d4a3304'

def validate_subset(old_rows,current_rows):
    old={e['path']:e for e in old_rows};current={e['path']:e for e in current_rows}
    if len(old)!=len(old_rows) or len(current)!=len(current_rows):raise ValueError('duplicate source paths')
    if '.' not in current or current['.'].get('type')!='dir':raise ValueError('source root missing')
    if not set(current)<=set(old):raise ValueError('new source entries require ordinary rearchive')
    for path,new in current.items():
        before=old[path]
        if new.get('type')=='dir' and before.get('type')=='dir':
            if {k:v for k,v in new.items() if k not in ('mtime_ns','size')}!={k:v for k,v in before.items() if k not in ('mtime_ns','size')}:
                raise ValueError('directory metadata changed beyond size/time: '+path)
        elif new!=before:raise ValueError('file/link metadata or contents changed: '+path)
    return sorted(set(old)-set(current))

def pax_time(ns):
    seconds,fraction=divmod(abs(ns),1000000000)
    return ('-' if ns<0 else '')+f'{seconds}.{fraction:09d}'

def repack_tar(original,current_rows,output,basename):
    """Pure local TAR transformation; caller enforces source/receipt guards."""
    current={e['path']:e for e in current_rows};seen=set()
    with output.open('xb') as raw:
        with tarfile.open(original,'r:gz') as source,tarfile.open(fileobj=raw,mode='w:gz',format=tarfile.PAX_FORMAT,compresslevel=1) as target:
            for member in source:
                path=PurePosixPath(member.name)
                if path.is_absolute() or '..' in path.parts or not path.parts or path.parts[0]!=basename:
                    raise ValueError('original member escapes source root')
                if not (member.isfile() or member.isdir() or member.issym()):raise ValueError('special member')
                relative=PurePosixPath(*path.parts[1:]).as_posix() if len(path.parts)>1 else '.'
                if relative not in current:continue
                if relative in seen:raise ValueError('duplicate retained member')
                seen.add(relative);wanted=current[relative]
                kind='file' if member.isfile() else 'dir' if member.isdir() else 'symlink'
                if kind!=wanted['type']:raise ValueError('member type differs')
                info=copy.deepcopy(member)
                if member.isdir():
                    info.mtime=wanted['mtime_ns']/1000000000
                    info.pax_headers['mtime']=pax_time(wanted['mtime_ns'])
                stream=source.extractfile(member) if member.isfile() else None
                try:target.addfile(info,stream)
                finally:
                    if stream is not None:stream.close()
        raw.flush();os.fsync(raw.fileno())
    if seen!=set(current):raise ValueError('retained member set incomplete')

def controller():
    import hashlib
    if hashlib.sha256(CONTROLLER.read_bytes()).hexdigest()!=CONTROLLER_SHA:raise ValueError('controller differs')
    spec=importlib.util.spec_from_file_location('verified_archive_controller',CONTROLLER)
    a=importlib.util.module_from_spec(spec);spec.loader.exec_module(a)
    return a

def reconcile(original_manifest,original_archive,original_linux,original_review,current_manifest,output):
    a=controller()
    for path in (original_manifest,original_archive,original_linux,original_review,current_manifest,output):a.persistent(path)
    root=json.loads(original_manifest.read_text())['root']
    old=a.load_manifest(original_manifest,root);current=a.load_manifest(current_manifest,root)
    if old['source_identity']!=current['source_identity']:raise ValueError('original source identity changed')
    a.verify(root,original_manifest,original_archive,original_linux,original_review)
    original_sha=a.sha_file(original_archive)
    removed=validate_subset(old['entries'],current['entries'])
    if output.resolve().parent!=BACKUP/'generation2/archives' or output.name!=PurePosixPath(root).name+'.tar.gz':
        raise ValueError('output must be this exact generation2 archive')
    output.parent.mkdir(parents=True,exist_ok=True)
    part=output.with_suffix(output.suffix+'.part');receipt=output.with_suffix(output.suffix+'.repack-receipt.json')
    if output.exists() or part.exists() or receipt.exists():raise ValueError('generation2 output already exists')
    fresh=a.inventory(root,output.with_suffix(output.suffix+'.pre-source.json'))
    if fresh['manifest_sha256']!=current['manifest_sha256']:raise ValueError('current source changed before repack')
    a.fresh_guard(root,fresh)
    repack_tar(original_archive,current['entries'],part,PurePosixPath(root).name)
    count,names=a.safe_tar_members(part,PurePosixPath(root).name)
    expected={PurePosixPath(root).name if e['path']=='.' else PurePosixPath(root).name+'/'+e['path'] for e in current['entries']}
    if len(names)!=len(expected) or set(names)!=expected:raise ValueError('new archive path set differs')
    post=a.inventory(root,output.with_suffix(output.suffix+'.post-source.json'))
    if post['manifest_sha256']!=current['manifest_sha256']:raise ValueError('current source changed during repack')
    if a.sha_file(original_archive)!=original_sha:raise ValueError('original archive changed')
    os.replace(part,output)
    result={'root':root,'original_archive_sha256':original_sha,'archive_sha256':a.sha_file(output),
            'source_manifest_sha256':current['manifest_sha256'],'source_entry_count':current['entry_count'],
            'tar_member_count':count,'omitted_entries':len(removed),'archive_fsynced':True,
            'original_archive_retained':True,'original_source_deleted':False,'linux_restore_still_required':True}
    with receipt.open('x',encoding='utf-8',newline='\n') as f:
        json.dump(result,f,sort_keys=True,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('original-manifest','original-archive','original-linux','original-review','current-manifest','output'):
        p.add_argument('--'+name,required=True,type=Path)
    args=p.parse_args()
    print(json.dumps(reconcile(args.original_manifest,args.original_archive,args.original_linux,args.original_review,args.current_manifest,args.output),sort_keys=True))

if __name__=='__main__':main()
