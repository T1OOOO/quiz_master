"""Compose three explicit SQLite closes over the immutable exact29 v1 packet."""
from pathlib import Path
import argparse,ast,hashlib,importlib.util,json,sys
sys.dont_write_bytecode=True
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[5]
CAPACITY=OWN.parent
WORK=REPO/'.run/country483_remote_20261015/capacity-adapter-v2'
V1=REPO/'.run/country483_remote_20261015/capacity-worker/preview-v1/deduplicate.sh'
F36=REPO/'.run/country483_remote_20261015/fixture-v2/preview-v1/linux-fixture-v2.sh'
PINS={CAPACITY/'worker/dedup_adapter.py':'ce1a44f63ead662347f89d896a701d8b7f1b2a2e10a7317e08cc94de5238818d',
 V1:'29cde354cc9117288b7cc5afef110fc8ee5e7389a6946694bf07137a82c1299a',
 F36:'d457162c7c98a70592cf753ac5d687d0c6aa7a4ed45d8efb1a8cfbd9843e474f',
 CAPACITY/'fixture-v2/assemble_fixture.py':'1788c7e115d0e61dfd7fa786174742c199cb4fd475fc1c95f01f8eab71ba3f30',
 CAPACITY/'source-review-inputs.json':'8d645d8989b34afc910ee75af17f3e9e3a9a4a43ac3fde731cce600d01f9d33e'}

def require(ok,message):
    if not ok:raise RuntimeError(message)

def sha(path):
    with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()

def digest(text):return hashlib.sha256(text.encode()).hexdigest()

def once(text,old,new):
    require(text.count(old)==1,'exact lifetime-patch anchor changed')
    return text.replace(old,new)

def connect_expressions(source):
    return [ast.get_source_segment(source,item.context_expr) for node in ast.walk(ast.parse(source)) if isinstance(node,ast.With)
            for item in node.items if isinstance(item.context_expr,ast.Call) and isinstance(item.context_expr.func,ast.Attribute)
            and isinstance(item.context_expr.func.value,ast.Name) and item.context_expr.func.value.id=='sqlite3' and item.context_expr.func.attr=='connect']

def close_contexts(source,count):
    expressions=connect_expressions(source);require(len(expressions)==count,'owned SQLite context count changed')
    for expr in expressions:source=once(source,'with '+expr+' as db:', 'with contextlib.closing('+expr+') as db:')
    require(not connect_expressions(source),'unclosed SQLite context remains')
    return 'import contextlib\n'+source,expressions

def inputs():
    require(__debug__,'optimized Python forbidden')
    for path,expected in PINS.items():require(sha(path)==expected,'immutable source binding changed: '+str(path))
    manifest=json.loads((CAPACITY/'source-review-inputs.json').read_text());require(len(manifest)==38,'old38 input count changed')
    for name,expected in manifest.items():require(sha(REPO/name)==expected,'old38 input drift: '+name)
    path=CAPACITY/'worker/dedup_adapter.py';spec=importlib.util.spec_from_file_location('exact29_accepted_v1',path)
    v1=importlib.util.module_from_spec(spec);spec.loader.exec_module(v1)
    house,guard=v1.sources();closed_house,house_exprs=close_contexts(house,1);closed_guard,guard_exprs=close_contexts(guard,2)
    return v1,house,guard,closed_house,closed_guard,house_exprs,guard_exprs

def body(shell,marker):return shell.split("<<'"+marker+"'\n",1)[1].rsplit('\n'+marker,1)[0]

def compose():
    v1,house,guard,closed_house,closed_guard,house_exprs,guard_exprs=inputs()
    original=V1.read_text();patched=once(original,guard,closed_guard)
    patched=once(patched,'house_source='+repr(house),'house_source='+repr(closed_house))
    compile(body(patched,'COUNTRY483_DEDUP'),'exact29-v2','exec')
    fixture=F36.read_text()
    fixture=once(fixture,'exec('+repr(house)+',module.__dict__)','exec('+repr(closed_house)+',module.__dict__)')
    constants='\nORIGINAL_HOUSE='+repr(house)+'\nCLOSED_HOUSE='+repr(closed_house)+'\nOLD_PREFLIGHT_CONTEXTS='+repr(guard_exprs)+'\n'
    new_contexts=['contextlib.closing('+expr+')' for expr in guard_exprs]
    constants+='NEW_PREFLIGHT_CONTEXTS='+repr(new_contexts)+'\n'
    suite='suite=unittest.TestSuite([unittest.defaultTestLoader.loadTestsFromTestCase(DedupTests),unittest.defaultTestLoader.loadTestsFromTestCase(FingerprintTests)])'
    integration=(OWN/'linux_integration.py').read_text()
    fixture=once(fixture,suite,constants+integration+'\n'+suite[:-2]+',unittest.defaultTestLoader.loadTestsFromTestCase(LifetimeIntegrationTests)])')
    tree=ast.parse(body(fixture,'COUNTRY483_FIXTURE'))
    cases=[(n.name,f.name) for n in tree.body if isinstance(n,ast.ClassDef) for f in n.body if isinstance(f,ast.FunctionDef) and f.name.startswith('test_')]
    require(len(cases)==16,'original14 plus2 lifetime cases required')
    compile(body(fixture,'COUNTRY483_FIXTURE'),'isolated16-v2','exec')
    proof=dict(original_house_sha256=digest(house),patched_house_sha256=digest(closed_house),original_guard_sha256=digest(guard),
               patched_guard_sha256=digest(closed_guard),owned_contexts_closed=dict(house=1,preflight=2),original_v1_sha256=PINS[V1],
               original_f36_fixture_sha256=PINS[F36],unchanged_plan_sha256=v1.PLAN_SHA,unchanged_protection_sha256=v1.PROTECTED_SHA,
               actual_house_source_changed=True,process_guard_unchanged=True,case_names=cases,linux_tests='PENDING_ROOT_EXECUTION',
               actual_cleanup_performed=False)
    return patched,fixture,proof

def render(output):
    production,fixture,proof=compose();output=Path(output)
    require(output.resolve().is_relative_to(WORK) and output.resolve()!=WORK.resolve() and not output.exists(),'fresh owned v2 output required')
    require(all(not p.is_symlink() and not p.is_junction() for p in (output,*output.parents)),'linked v2 output forbidden')
    output.mkdir(parents=True)
    for name,text in [('deduplicate-v2.sh',production),('linux-integration-v2.sh',fixture)]:
        (output/name).write_bytes(text.encode());proof[name+'_sha256']=digest(text)
    proof.update(status='LOCAL_V2_RENDER_ONLY',source_sha256={p.name:sha(p) for p in OWN.glob('*.py')},pinned_sources={str(p):v for p,v in PINS.items()})
    (output/'receipt.json').write_text(json.dumps(proof,indent=2)+'\n');return proof

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output-root',type=Path,required=True)
    print(json.dumps(render(parser.parse_args().output_root)))
