# Two-item integration plan — research, not an executed patch

Native explorer task0ccd46b0 provided the following read-only planning findings; a follow-up corrected its initial overly broad statement about retaining source indexes0–5. No importer/build/runtime change was run by that helper.

`next/server/cmd/quizctl/main.go` supports import/build/catalog `--in --out [--force]`, build also `--version --published-at`, validate `--in`, diff `--before --after`. There is no targeted patch or rehash CLI. Do not overwrite the current100-question draft with a fresh import: import recreates all question revision numbers at1. Preserve the98untouched question objects and existing pack metadata; increment only rk93/rk95 current revision1 to2. Call the actual exported Rehash implementation (`canonical.go:226-232`) after editing; build/validation must reject stale hashes. Build a separate candidate bundle with a new explicit version and RFC3339 timestamp, validate it and diff against the frozen old bundle.

Keep canonical option identities for unchanged answer choices. For rk95 four raw choices, the correct new mapping in `manifest.questions[]` entry `canonical_id=lotr-rk-95`, `options[]` is:

```json
[
  {"source_index":0,"canonical_id":"lotr-rk-95-opt-1"},
  {"source_index":1,"canonical_id":"lotr-rk-95-opt-2"},
  {"source_index":2,"canonical_id":"lotr-rk-95-opt-3"},
  {"source_index":3,"canonical_id":"lotr-rk-95-opt-5"}
]
```

The new raw index3 must not become opt-4: that ID was Tirion, now dropped. Alqualonde retains opt-5. Correct raw index1 still binds private `grading.correct_option_id=lotr-rk-95-opt-2`. Update manifest source_sha256 for the changed raw file, preserve source_id/mapping_version/quiz/category/title/description metadata and align the two source_explanation fields with the actual revised explanations. Never accept positional scratch importer IDs as preserved identity. Candidate v3 option IDs are editorial only, not published canonical IDs.

Reader currently has no articles bound to these two question IDs. `study/question_articles/build.py` checks exact per-question SHA against `snapshots/<quiz_id>.json` or fallback `next/content/<quiz_id>/bundle.json`; `snapshots/lotr.json` is a different quiz_id and must not be overwritten. Author the two real Reader-schema records against the newly validated bundle revision and obtain exact canonical article-hash review before `--write`. `--check` confirms exports. Preserve all264existing Reader objects and all135catalog rows. Metadata-only `quizctl catalog --in quizzes --out next/apps/quiz_app/assets/catalog.json --force` does not itself export changed question content; avoid an unnecessary regeneration. Identify and run the actual aggregate question-content exporter, rather than assuming that metadata catalog generation updates runtime questions.

Required evidence before publishing: source/editorial acceptance with limits, exact raw/draft/manifest/private-key parity and new nonzero answer checks, unchanged98question hashes, v3 candidate→canonical option identity mapping, refreshed aggregate question assets without collateral changes, two revised Reader bindings/hash approval, relevant Go/content/Flutter gates, actual browser quiz and article flows, copied-database/rollback and current release gates. Production remains Screen Song Helm52 until those pass;26realfeedback staysOPEN.
