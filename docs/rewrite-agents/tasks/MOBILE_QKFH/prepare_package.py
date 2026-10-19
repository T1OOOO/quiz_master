"""Package a clean committed web build; never contacts production."""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, required=True)
parser.add_argument('--destination', type=Path, required=True)
parser.add_argument('--fact-count', type=int, required=True)
args = parser.parse_args()
source = args.source.resolve()
commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source, text=True).strip()
dirty = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], cwd=source, text=True)
if dirty:
    raise SystemExit('Refusing to package a dirty source checkout')
build = 'quiz-2026.10.19-mobile-' + commit[:8]
web = source / 'next/apps/quiz_app/build/web'
if not (web / 'main.dart.js').is_file():
    raise SystemExit('No release web build')
js = (web / 'main.dart.js').read_bytes()
if build.encode() not in js or b'https://quiz.kotopedia.org' not in js:
    raise SystemExit('Build identity or public API URL missing from compiled application')
if args.destination.exists():
    raise SystemExit('Destination must be fresh')
preflight = (Path(__file__).parent / 'preflight.txt').read_text(encoding='utf-8')
decoder = json.JSONDecoder()
_, consumed = decoder.raw_decode(preflight)
version, _ = decoder.raw_decode(preflight[consumed:].lstrip())
version.update(buildId=build, commit=commit, source_commit=commit,
               main_dart_js_sha256=hashlib.sha256((web / 'main.dart.js').read_bytes()).hexdigest(),
               quizipedia_facts=args.fact_count, quizipedia_sections=13,
               api_build_id=version['buildId'], frontend_only=True)
shutil.copytree(web, args.destination / 'web')
shutil.copytree(source / 'deploy/helm/quiz-master', args.destination / 'chart')
(args.destination / 'web/version.json').write_text(json.dumps(version, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'buildId': build, 'source_commit': commit,
                  'main_dart_js_sha256': version['main_dart_js_sha256'],
                  'package': str(args.destination.resolve())}, indent=2))
