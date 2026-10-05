# Metadata implementation and editorial checkpoint

Base checkout a1fd8bf, branch codex/quiz-v2. This checkpoint preserves ongoing
work; it is not full4078 annotation application or a metadata production release.
Quizipedia is already released independently at /#/quizipedia (revision24,
game source486df89, release/browser evidence committed through a1fd8bf).

## Implemented behavior and independent review

Exact levels1–10 map to Easy1–3, Medium4–6, Hard7–8, Nightmare9–10. Optional
canonical metadata preserves legacy archives. The Go taxonomy/import contract
keeps editorial entity tags private. Difficulty selection filters before
20-question partitioning and shuffles inside each selected round. SQLite whole
pack practice works when round is omitted. PostgreSQL ranked selection supports
the same filter/partition contract; PostgreSQL practice remains unsupported.
Flutter parsers accept server difficulty counts, preserve selected bands through
requests/routes/Browse, and retain explicit no_match failures.

Original CODE_METADATA_GATE reported8 findings. CODE_METADATA_RECHECK accepted
their fixes and required PostgreSQL question shuffling and replay evidence.
CODE_METADATA_FINAL accepts the reviewed code with no actionable findings and
conditional requirement acceptance pending the final pinned CI. These are real
independent Codex contexts, not an independent-provider certification.

## Fresh executed checks

- Windows Go1.27.0: full `go test ./...` PASS after final shuffler and new replay
  tests; SQLite96.092s. `go vet ./next/server/...` exit0, no diagnostics. Focused
  gofmt output empty. Saved root logs go36-full-tests/go36-vet in ignored .run.
- SQLite annotated partial attempt: one answer accepted before republish;
  replacement changes taxonomy with disjoint tags, metadata, options, keys and
  explanations. Sources and both dictionaries are removed, then the old receipt,
  second answer, Finish2/2 and reveals remain pinned to original persisted data.
  Targeted regression PASS under valid admission, plus full suite above.
- PostgreSQL real-service regression added for82 interleaved questions,
  41matching questions, rounds20/20/1, reverse permutations, actual stored
  positions/public metadata/snapshots, catalog/source identity and no repeats.
  Tagged compile-only PASS under valid admission; local DB runtime NOT_RUN.
  CI now explicitly includes attempts with migrate/identity/store and `-p 1`.
- Flutter3.47.1: all96 tests PASS, analyze no issues, formatter21files/zero
  changes. Targeted DTO/error/request/Browse tests50 PASS. The narrow map test
  pan adjustment has independent acceptance; production map code unchanged.
- Python: `python -B -m unittest discover -s metadata -p test_quiz_metadata.py`
  11 PASS. Earlier root module-form invocation failed only on import path;
  correct discovery invocation above was rerun successfully.
- Contract checker:3positive cases,7scoring cases,37named negatives rejected,
  content hash8bb47ad26c94bade21146b318dea66544412fdebb67dde31612f1d3c995685e5.
- Root partial combined metadata check2777/4078 PASS after accepted Philias165,
  Preparation75, fresh Pets75, NewYear75 and Cats112 copies; reviewers also checked candidates.
  All source semantic hashes remain frozen; partial success is not full coverage.

Pinned CI190e863 now passed all3 jobs, including real PostgreSQL/health, Web and
debug Android; exact evidence is CI_CHECKPOINT_190E863.md/run37340025169.
No Android signing/device result or metadata production rollout is implied.

## Editorial state

Taxonomy425 semantic SHA07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151.
The earlier20 additions and latest2 sports/figure-skating additions have independent
vocabulary reviews; all previous definitions remain unchanged. Game catalog/manifest edits only rebind this taxonomy reference and
refresh the catalog hash; game facts, coordinates and licensed pictures unchanged.

Accepted copies2777/4078 are recorded by ACCEPTED_REFERENCE_REBIND,
ACCEPTED_WAVE_423_2/3/4/5/6, ACCEPTED_REFERENCE_REBIND_425 and ACCEPTED_WAVE_425_1/2.
These include all299 freshly reread food records, HomeAlone185,
celebrities33 and animal phobias89 after review corrections. Root original
country/capital/Study/word/firstpet annotation provenance remains explicit in
earlier reports; this total is not a claim every fact was independently sourced.
All low-confidence/factual/ambiguous items keep private editorial flags.

Philias165 fresh individual candidates passed independent full-source metadata
review after two private-flag/rationale corrections (PHILIAS_423_DELTA).
Preparation75 passed root source sample32/75, all20 ballet and all flagged rows,
after lowering an explicit composer-name cue from5 to1. Remaining43 books were
not individually source-reviewed by root; source-fact certification is excluded.
Fresh Pets75 passed independent full75 raw+annotation review after18 duplicate
flags and2 cue ratings4to2. Root separately reread all20 delta source records.
The preceding Pets150 classifier/copy pass is REJECTED outsideaccepted, with
PETS_423_A150_REWORK explaining why uniqueness/shape checks do not prove quality.
NewYear75 passed independent full75 raw/metadata review and final10-row correction
recheck. Root read all10 affected raw records; key conflicts, duplicate links,
Scrooge reasoning, figure-skating tags/superlative and Grinch ambiguity corrected.
All numeric ratings and source fields remain unchanged;40 low/43 flagged rows
are not factual certification. Source key/explanation follow-up: quiz_master-jsu.
After425 rebind, root Python11 and game catalog5 tests passed; all2590 prior
record arrays match GitHEAD, and game facts/media/geometry remain unchanged.
Cats112 passed independent full112 raw/annotation review and a bounded final
62-record delta recheck. Root reread all8 changed-grade source records and verified
62 changed/50 unchanged, retained prior flags, exact112 order, six source byte
hashes and full4078 semantic integrity. Eight visible-cue estimates were lowered;
59 rows gained60 private duplicate flags. Aoshima school history, distinct
English collective words and Hermitage aliases/uniform/classes remain separate
facts. Accepted byte copy is recorded by ACCEPTED_WAVE_425_2; factual claims and
keys have not been independently sourced or repaired by this metadata work.

Still awaiting acceptance1301: dogs358, NewYear678, Preparation265, covered by
the eight remaining exact disjoint frozen425 packets. Preparation B135 is an
author-complete, structurally validated candidate, pending independent review;
Dogs A180 has30 literal records saved after60 full raw reads, with150 candidate
records still unwritten. These165 draft rows are excluded from accepted totals.
Fresh combined accepted2777 and draft165 partial checks preserve source4078
semantic integrity and reject overlap. NewYear source-key follow-up remains jsu.
Full application, deterministic
private index/catalog generation, provider privacy checks and synchronized release
remain required. No fallback scores or keyword-based tagging will fill these gaps.

Rejected initial templates remain outside accepted/ as audit history. Earlier
author handoffs and concerns reflect their then-current state; the later review
and this checkpoint supersede only their documented dispositions. Existing
factual concerns are not resolved by assigning difficulty or tags.

Beads qr4/qr4.5 remain in progress. Future source-level factual fixes and a ranked
mixed-pack immutable bundle are separate work; current CLI search supports
cross-theme private selections without presenting Study as ranked API content.
