"""Independent, read-only review of the finite publication controller."""
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
prompt = '''Independently review this authorized frontend-only production release controller. READ ONLY these files:
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/release/release_executor.py
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/release/test_negative_guards.py
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/release/README.md
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/preflight.txt
E:/Projects/quiz_master/deploy/helm/quiz-master/templates/app.yaml
Goal: user explicitly authorized deploy to existing quiz.kotopedia.org. Extend retained immutable Docker image ONLY replacing web dir; API, content, nginx config and SQLite unchanged. Target revision62, hostname/PVC/image checks, exclusive lock, fresh package directory; input checksums; exact render comparison allows only 2image+buildannotation edits; online SQLite backup and copy-integrity restoreproof; per-originalfeedback hashedrow preservation allowing newrows; atomic Helm upgrade, rollback62, publicversion/JS/health checks. Do not execute controller or SSH, edit files, enumerate repository, launch other agents, or build. Report ACCEPT or REVISE; concrete blocking bugs only with exact current lines. Check shell command semantics, Docker/config vs manifest digest, rollback behavior and private data preservation. No invented requirements for user confirmation; current user authorized publication. The actual root will execute only after review accepts. Seven local negative guard tests have passed, actual remote execution not yet run. Keep bounded to these five files.'''
followup = '--followup' in sys.argv
baseline = '--baseline' in sys.argv
if followup:
    prompt = '''Read-only follow-up of your 3 MOBILE_QKFH publication-controller blockers. Read ONLY current E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/release/release_executor.py and test_negative_guards.py in samefolder. Repairs: explicit return1 inside verify_public and invoke outsidecondition; post-success ERRtrap rollsback62 for everypostupgradefailure; LFforced Dockerfile andmanifest; Helmnormalize strips trailingwhitespace. AddedexactbaseDockerIDpin knownfromactualreadonlydockerinspectmatchingbaseline, and9tests. Verify real shell semantics, trap preservesfailurestatus and cleanup. Return ACCEPT or REVISE concrete current blockers only. Do not execute, SSH, edit, enumerate, build ordelegate. User authorized existingproductiondeploy, rootexecutesonlyafteracceptance.'''
if baseline:
    prompt = '''Read-only bounded baseline correction review. Read ONLY current release_executor.py and test_negative_guards.py under E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/release/ and ../preflight-current.txt. First real invocation stopped BEFORE backup/imagebuild/upgrade because Helmhistory latest revision64 differsfromDeployment annotationrevision62. Root actuallyread Helmhistory:64deployed sinceOct16, and kubectlDeployment annotation62; bothsamepinnedimage dc230d8.../build3c22818/PVCunchanged. The original preflight mislabeled Deploymentcounter asHelmrevision. NowBASE_REVISION64 usedHelmguard+rollback, separateBASE_DEPLOYMENT_REVISION62 guardedbothpreflight+remote, actualPVCUIDpreflightrequired, measuredpositivefree insteadstale exactbytes (livecapacityformula unchanged). Ten localguards pass includingrejectconfusing62asHelm. This preserves currentrelease64config viareuse-values androllback64. Otheracceptedtransaction unchanged. ReviewACCEPTorREVISE concretecurrentbugs. Do not execute/SSH/edit/enumerate/delegate. Userauthorizedsameproductionrelease. Keepconcise.'''
with (root / ('baseline-review.jsonl' if baseline else 'release-review-final.jsonl' if followup else 'release-review.jsonl')).open('w', encoding='utf-8') as output:
    result = subprocess.run(
        ['agy', *(['--conversation', '65e8d40a-56c2-4107-8f77-84102952359b'] if followup or baseline else []), '--model', 'gemini-4-argon-high', '--mode', 'plan',
         '--output-format', 'stream-json', '--print', prompt],
        stdout=output, stderr=subprocess.STDOUT, encoding='utf-8', timeout=900)
print('Independent release review exit:', result.returncode)
raise SystemExit(result.returncode)
