# Finite answer-option quality audit

You are an AI QA helper for the Quiz Master lead. The user explicitly requests
question/answer audits and bounded helpers. Read AGENTS.md, use your own actual
host_hub identity, join team-a32157792ef74ebda086a7f97cc7abb1 ready and accept
the offered task. The Quiz Master resource queue was waived; ownership and
bounded concurrency remain. You are not alone; preserve all other changes.

Current production is Flutter Web/Go, Helm54,136 quizzes/4084 questions/272 Reader
articles. Its publication and mobile checks passed. This is a separate read-only
quality audit, not a new release or whole-bank factual approval. No GitHub Actions,
schedulers, builds, browsers, SSH, Git writes, app edits or child agents.

Audit the actual canonical subset in
`.run/reader_import_20261014/package-v3/quiz-2026.10.14-reader-17be4ce/runtime-bundles.json`.
Read questions/options and private_grading from these existing source bundles;
do not create production attempts or derive correctness from option position.
Count the actual packs/questions first, report coverage explicitly against4084.

Find candidate answer giveaways: a correct option with an explanation in
parentheses, unusually long correct text against plausible short distractors,
duplicate normalized alternatives, or answer-style inconsistencies. Record exact
quiz/question IDs, evidence and why it deserves editorial/factual review. Numerical
length flags are candidates, not automatic defects; inspect the highest-ranked
examples yourself and distinguish innocent proper names from hints. Do not claim
facts verified merely because a stored key exists. This user wants plausible
alternatives; never propose changing the answer key without source-backed review.

Own ONLY `docs/rewrite-agents/tasks/ANSWER_OPTION_AUDIT_20261014/REPORT.json`.
Use existing house tools where useful. Report actual scope/counts, source SHA,
reproducible checks, at most15 prioritized findings and limitations. No questions,
grading, metadata, drafts or exports may be edited. Submit actual evidence through
Hub, then stop. Root will assign safe fixes and a separate independent review.
