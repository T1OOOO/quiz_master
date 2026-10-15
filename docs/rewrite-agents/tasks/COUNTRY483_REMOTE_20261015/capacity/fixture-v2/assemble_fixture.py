"""Assemble the isolated fixture connection-close correction; no execution."""
from pathlib import Path
import argparse,ast,hashlib,importlib.util,json,sys
sys.dont_write_bytecode=True
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[5]
WORK=REPO/'.run/country483_remote_20261015/fixture-v2'
OLD=OWN.parent/'worker'
OLD_SCRIPT=REPO/'.run/country483_remote_20261015/capacity-worker/preview-v1/linux-fixture-PENDING.sh'
PINS={OLD/'dedup_adapter.py':'ce1a44f63ead662347f89d896a701d8b7f1b2a2e10a7317e08cc94de5238818d',
      OLD/'linux_fixture_tests.py':'f29a300489cc909ddd5721c83beae7684efe4efbc76c0a722e5d22490f03942d',
      OLD_SCRIPT:'66eab3363c78fd92e03f1429613f521494fdb99019cb943ca05b5319c094cab2',
      REPO/'.run/country483_remote_20261015/capacity-worker/preview-v1/deduplicate.sh':'29cde354cc9117288b7cc5afef110fc8ee5e7389a6946694bf07137a82c1299a'}
BEFORE="        with sqlite3.connect(self.path) as db:db.execute('create table fixture(value text)')"
AFTER="        with contextlib.closing(sqlite3.connect(self.path)) as db:db.execute('create table fixture(value text)');db.commit()"

def sha(path):
    with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def require(ok,message):
    if not ok:raise RuntimeError(message)

def body(shell):return shell.split("<<'COUNTRY483_FIXTURE'\n",1)[1].rsplit('\nCOUNTRY483_FIXTURE',1)[0]

def test_names(shell):
    tree=ast.parse(body(shell))
    return [(node.name,fn.name) for node in tree.body if isinstance(node,ast.ClassDef)
            for fn in node.body if isinstance(fn,ast.FunctionDef) and fn.name.startswith('test_')]

def assemble():
    require(__debug__,'optimized Python forbidden')
    for path,digest in PINS.items():require(sha(path)==digest,'accepted source/fixture/deletion binding changed: '+str(path))
    spec=importlib.util.spec_from_file_location('accepted_exact29_adapter',OLD/'dedup_adapter.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    house,_=module.sources();original=module.fixture_source(house)
    require(original.encode()==OLD_SCRIPT.read_bytes(),'accepted fixture no longer reproduces')
    require(original.count(BEFORE)==1 and original.count('import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat')==1,'fixture replacement anchor changed')
    corrected=original.replace(BEFORE,AFTER).replace('import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat',
                                                     'import types,sys,unittest,tempfile,sqlite3,json,os,hashlib,stat,contextlib')
    require(test_names(original)==test_names(corrected) and len(test_names(corrected))==14,'fixture cases changed')
    compile(body(corrected),'fixture-v2-only','exec')
    return corrected

def render(output):
    corrected=assemble();output=Path(output)
    require(output.resolve().is_relative_to(WORK) and output.resolve()!=WORK.resolve() and not output.exists(),'fresh fixture-v2 output required')
    require(all(not p.is_symlink() and not p.is_junction() for p in (output,*output.parents)),'linked fixture output forbidden')
    output.mkdir(parents=True);script=output/'linux-fixture-v2.sh';script.write_bytes(corrected.encode())
    result=dict(status='LOCAL_FIXTURE_RENDER_ONLY',script=str(script),script_sha256=sha(script),
                pinned_original_sha256={str(k):v for k,v in PINS.items()},source_sha256={p.name:sha(p) for p in OWN.glob('*.py')},
                correction='Only FingerprintTests.setUp uses contextlib.closing plus explicit commit; all14cases and production guards unchanged',
                linux_tests='PENDING_ROOT_EXECUTION',actual_production_cleanup=False)
    (output/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');return result

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output-root',type=Path,required=True)
    print(json.dumps(render(parser.parse_args().output_root)))
