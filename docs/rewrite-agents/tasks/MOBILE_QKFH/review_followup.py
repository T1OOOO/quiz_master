"""Run the bounded follow-up in the existing independent AGY conversation."""
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent
prompt = '''Read-only follow-up of your six concrete blockers for MOBILE_QKFH.
Read ONLY these current files (do not enumerate the repository or reread all assets):
E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart
E:/Projects/quiz_master/next/apps/quiz_app/test/fact_practice_models_test.dart
E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice.dart
E:/Projects/quiz_master/next/apps/quiz_app/test/fact_practice_test.dart
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/fact-bank.md
E:/Projects/quiz_master/docs/rewrite-agents/tasks/MOBILE_QKFH/backrub-review.md
Verify all six repairs, current real API and fair canonical answers. Initial report had inaccurate class names: actual API StudyFact/FactQuestion/FactChoice and correctId=fact.id; no FactPracticeBank exists. Sources are actual launchUrl buttons. Do not repeat these inaccurate points.
Country links now typed, true neighbors extracted; nested child prompts qualified; family/typed fallback preserving kind; owner/cast/credit names resolved; dates/source captions Russian; individual fact continuation pool fixed. The disabled BackRub former-name/year record remains excluded; separately reviewed qualified research-project name accepted by primary-source review.
Report ACCEPT or REVISE with only concrete current blockers and precise lines. Check regression tests really cover the fixes. Do not edit, deploy, call other agents or run builds. Keep scope to these six files.'''
with (root / 'review-followup.jsonl').open('w', encoding='utf-8') as output:
    result = subprocess.run(
        ['agy', '--conversation', '398148a3-7c19-41ac-a74b-9d099fa04c9a',
         '--model', 'gemini-4-argon-high', '--mode', 'plan',
         '--output-format', 'stream-json', '--print', prompt],
        stdout=output, stderr=subprocess.STDOUT, encoding='utf-8', timeout=900)
print('Independent review exit:', result.returncode)
raise SystemExit(result.returncode)
