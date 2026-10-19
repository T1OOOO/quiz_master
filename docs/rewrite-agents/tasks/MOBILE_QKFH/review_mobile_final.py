"""Independent review of the final, bounded phone graph correction."""
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
prompt = '''Read-only final mobile UI delta review. Read ONLY:
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-mobile.diff
E:/Projects/quiz_master/next/apps/quiz_app/test/belief_mobile_graph_test.dart
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/release/release_executor.py (only Dockerfile constant and remote_script set-E/ERR guards already reviewed ACCEPT in conversation65e8d40a-56c2-4107-8f77-84102952359b).
Phone screenshot exposed religionedge caption overlapping two nodes. Diff makes narrowviewport singleverticalcolumn, nodewidth<=240 and164spacing, caption14withTextScaler/max3lines, sharedgeometryusednodes/painter/fit. Existing manualzoom/selection unchanged, fullnames/relations remain accessible below map. Test RU320px1.5scale+geometry and existingbelief focused6passed. Check correctness/readability and potential overlaps; actual pinch not simulated in this review.
Release minor hardening afterACCEPT: set -Eeuo pipefail extendsERRinheritance; USER0:0 around webdirclear/COPY then restoresUSER10001:10001 matching actualbaseimageuserconfirmedreadonlyinspect. Nineguardtests pass; no remote mutation performed. User authorizeddeployexistingtarget.
Return concise ACCEPT or REVISE with concrete blocking current lines only. Do not edit, execute scripts, SSH, enumerate repository, build, or spawn agents. Keep bounded to these three files.'''
fit = '--fit' in sys.argv
collision = '--collision' in sys.argv
if fit:
    prompt = '''Review ONLY E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-fit.diff in context of your accepted vertical mobilegraph. Three consistent minzoomlimits lower .25→.05 so Fit can actually fit all21nodes vertically in280px (sceneheight3360). Previous .25clamp left840px clipped. Strengthened existing21nodephone test asserts renderedsceneheight*scale<=280.01; RED beforefix, focused6GREENafterfix. No otherbehaviorchange. Return conciseACCEPT orREVISE concreteblockers only; readonly nootherfiles/tools/edits/commands/agents.'''
if collision:
    prompt = '''Final small collision guard review ONLY E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/belief-collision.diff. In fullverticalgraph, non-adjacentedge midpoint can landon anintermediatenode. captionFits skips painting captions overlappingnodeRects or earliercaptions with4pxgap, whilearrowstillpainted and fullrelationtextremainsexistingSemantics/details. Unitassertsadjacentcaptionfits, duplicatecaptionrejected, 0→2captionovermiddle1rejected; focused6PASS. No question/data/zoomchanges. ReturnconciseACCEPT orREVISE concretecurrentbugs. Readonly diffonly no commands/edits/agents.'''
with (root / ('collision-review.jsonl' if collision else 'fit-review.jsonl' if fit else 'mobile-final-review.jsonl')).open('w', encoding='utf-8') as output:
    result = subprocess.run(
        ['agy', *(['--conversation', '87fdcf4c-a2c5-40d3-b01a-046ffcd2e8c1'] if fit or collision else []), '--model', 'gemini-4-argon-high', '--mode', 'plan',
         '--output-format', 'stream-json', '--print', prompt],
        stdout=output, stderr=subprocess.STDOUT, encoding='utf-8', timeout=900)
print('Independent mobile delta review exit:', result.returncode)
raise SystemExit(result.returncode)
