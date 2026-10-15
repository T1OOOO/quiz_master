"""Correct the atlas image root using the immutable package Dockerfile."""
from pathlib import Path
import hashlib,importlib.util,json

if not __debug__:raise RuntimeError('normal Python required')
OWN=Path(__file__).resolve().parent
REPO=OWN.parents[5]
DOCS=OWN.parent.parent
OLD='/app/web/assets/assets/quizipedia/'
NEW='/usr/share/nginx/html/assets/assets/quizipedia/'

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def patch(text):
    if text.count(OLD)!=2 or NEW in text:raise ValueError('exact two legacy atlas image paths required')
    result=text.replace(OLD,NEW)
    if OLD in result or result.count(NEW)!=2:raise ValueError('atlas path replacement differs')
    return result

def context():
    source=DOCS/'worker/render_remote.py'
    if sha(source)!='54ea8a9e03b8621d8279a3af92334aab337f0e97d19a85838e1b5b6f0162e6f2':raise ValueError('accepted renderer changed')
    spec=importlib.util.spec_from_file_location('accepted_country483_atlas',source)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    pins,local,package=module.validate_inputs()
    dockerfile=Path(package['archive']).parent/module.BUILD/'Dockerfile'
    if sha(dockerfile)!='3eb0c0ca38334f32b3f3dbb7a3f12a5246dca5ab3411b8be4ea3df7e20cdf4f4' or dockerfile.read_text().count('COPY web /usr/share/nginx/html')!=1:
        raise ValueError('immutable image web root differs')
    return module,pins,local,package

def collection_script(run,image,durable):
    module,pins,local,_=context()
    return patch(module.collection_script(pins,local,run,image,durable))

def scripts():
    module,pins,local,package=context()
    resume=OWN.parent/'resume-preparation.sh'
    if sha(resume)!='674cb276d559aa769ea5f0f8a7c2c34bbd3bfee49b915107046594c69e01abd5':raise ValueError('accepted resumption composition changed')
    return {'resume-preparation-v2.sh':patch(resume.read_text()),
            'collection-INERT-EXAMPLE-v2.sh':patch(module.collection_script(pins,local,*module.EXAMPLE))}

if __name__=='__main__':
    bodies=scripts()
    for name in bodies:
        if (OWN/name).exists():raise ValueError('preserve previously rendered evidence')
    for name,body in bodies.items():(OWN/name).write_bytes(body.encode())
    record=dict(status='LOCAL_CORRECTED_ATLAS_PATHS_NOT_EXECUTED',old_image_root=OLD,new_image_root=NEW,
                reason='Immutable Dockerfile COPY web /usr/share/nginx/html; no /app/web exists in the image',
                source_sha256=sha(Path(__file__)),scripts_sha256={name:sha(OWN/name) for name in bodies},
                supersedes_only_legacy_atlas_image_path_metadata=True,original_inputs_preserved=True,
                actual_candidate_image=None,preparation_retry_performed=False,publication_performed=False)
    (OWN/'path-contract.json').write_text(json.dumps(record,indent=2)+'\n');print(json.dumps(record))
