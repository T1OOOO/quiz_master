if not __debug__:
    raise RuntimeError('publication renderer refuses optimized Python')

from pathlib import Path
import json,hashlib,re

def main():
    r=Path('C:/ap/quiz_master');w=r/'.run/reader299_release_20261015';d=r/'docs/rewrite-agents/tasks/READER299_RELEASE_20261015'
    def load(p):return json.loads(p.read_bytes())
    def h(p):return hashlib.sha256(p.read_bytes()).hexdigest()
    p=load(w/'package-v1/package-preparation.json');e=load(w/'remote-v2/remote-preparation-verification.json');stage=(r/Path(p['archive'])).parent/p['build_id'];b=p['build_id'];image=e['image'];values=e['values']
    assert b==e['build_id']=='quiz-2026.10.15-reader299-9c670e9' and p['frozen_commit']==e['source_commit']=='9c670e90ac0547eb9d276d6190a87a71680b7fd2'
    assert e['remote_prepare_exit']==0 and e['package_sha256']==p['archive_sha256'] and re.fullmatch('sha256:[0-9a-f]{64}',image)
    assert re.fullmatch(re.escape(b)+r'-cutover-\d{8}T\d{6}Z-values.yaml',values)
    prefix=(stage/'cutover.sh').read_text().split('quiz_run="$quiz_build-cutover-')[0];assert 'docker build' not in prefix and 'backup_sqlite' not in prefix
    assert 'quiz_preflight()' in prefix and 'f_bavail' in prefix and prefix.count('[[ "$quiz_mode" = prepare ]]')==1
    prefix=prefix.replace('[[ "$quiz_mode" = prepare ]]','[[ "$quiz_mode" = publish ]]')
    shell=prefix+f'''
    helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==61 and x["info"]["status"]=="deployed"'
    quiz_preflight
    echo '{e['durable_archive_sha256']}  {e['durable_archive']}' | sha256sum -c -
    echo '{e['values_sha256']}  {values}' | sha256sum -c -
    quiz_digest='{image}'
    quiz_values='{values}'
    k3s ctr images ls | awk -v image="docker.io/library/quiz-master@$quiz_digest" '$1==image {{found=1}} END {{exit !found}}'
    quiz_run="$quiz_build-publish-$(date -u +%Y%m%dT%H%M%SZ)"
    python3 backup_sqlite.py "/opt/quiz-master/backups/$quiz_run.sqlite"
    helm lint --strict chart -n quiz-master -f "$quiz_values"
    helm template quiz-master chart -n quiz-master -f "$quiz_values" > "$quiz_run-rendered.yaml"
    echo '{e['helm_dryrun_sha256']}  '"$quiz_run-rendered.yaml" | sha256sum -c -
    kubectl apply --dry-run=server -n quiz-master -f "$quiz_run-rendered.yaml"
    quiz_preflight
    helm upgrade quiz-master chart -n quiz-master -f "$quiz_values" --atomic --wait --timeout 180s
    kubectl get deploy quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);images=[c["image"] for c in x["spec"]["template"]["spec"]["containers"]];assert len(images)==2 and set(images)=={{"docker.io/library/quiz-master@{image}"}};assert x["status"].get("availableReplicas")==1'
    curl -fsS https://quiz.kotopedia.org/health/ready >/dev/null
    curl -fsS https://quiz.kotopedia.org/version.json | python3 -c 'import json,sys;assert json.load(sys.stdin)==json.load(open("web/version.json"))'
    test "$(curl -fsS https://quiz.kotopedia.org/main.dart.js | sha256sum | cut -d ' ' -f 1)" = {h(stage/'web/main.dart.js')}
    test "$(curl -fsS https://quiz.kotopedia.org/assets/assets/study/question-articles.json | sha256sum | cut -d ' ' -f 1)" = {h(stage/'web/assets/assets/study/question-articles.json')}
    printf 'PUBLISHED build=%s image=%s backup=%s\\n' "$quiz_build" "$quiz_digest" "$quiz_run"
    '''
    assert shell.count('helm upgrade')==1 and all(x not in shell for x in ['docker build','flutter build','rehearse-'])
    (d/'publish-preview.sh').write_bytes(shell.encode())
    out=dict(e,publish_script_sha256=h(d/'publish-preview.sh'),package_receipt_sha256=h(w/'package-v1/package-preparation.json'),local_browser_sha256=h(d/'local-browser/browser-proof.json'),publication_renderer_sha256=h(Path(__file__)))
    (d/'execution-packet.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf8');print('Actual executionpacket bound to prepare receipt and inert publication script.')

if __name__ == '__main__':
    main()
