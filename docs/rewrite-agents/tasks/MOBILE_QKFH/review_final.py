"""Bounded independent check of remaining relation/name regressions."""
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent
prompt = '''Final bounded follow-up: read ONLY current fact_practice_models.dart, test/fact_practice_models_test.dart (both under E:/Projects/quiz_master/next/apps/quiz_app/), and E:/Projects/quiz_master/next/apps/quiz_app/assets/quizipedia/knowledge_atlas.json if needed to check actual born schema.
Remaining relation blocker repaired: every relation prompt includes specific item name; link relation prompt no longer includes its answer kind; child entityId country+asset+kind+item avoids over-excluding other relations of same country. _valueKind relation is exclusively relation, never capitals/currencies; historical_project maps to former_names.name and historical_name kind, names-only. Regression tests build all questions and assert relation options all come from relation facts.
Prior born concern was hypothetical: actual current people.born values are Strings, nonempty tested. Current dataset support is sufficient; do not block on hypothetical integer future schema.
User explicitly required ALL names/facts Russian; this overrides BackRub-review.md suggestion to leave Latin propername displayed. Canonical EN BackRub remains, RU БэкРаб uses established localization. Qualified project-only claim unchanged; disabled former-name/year records remain excluded. Do not classify Russian display as a blocker.
Verify these repairs against actual code and return ACCEPT or REVISE with concrete current blockers and exact lines only. No edit, build, shell, SSH, enumeration or agents. Prior five resolved items and UI continuation need no reread. Keep concise.'''
with (root / 'review-final.jsonl').open('w', encoding='utf-8') as output:
    result = subprocess.run(
        ['agy', '--conversation', '398148a3-7c19-41ac-a74b-9d099fa04c9a',
         '--model', 'gemini-4-argon-high', '--mode', 'plan',
         '--output-format', 'stream-json', '--print', prompt],
        stdout=output, stderr=subprocess.STDOUT, encoding='utf-8', timeout=900)
print('Independent final review exit:', result.returncode)
raise SystemExit(result.returncode)
