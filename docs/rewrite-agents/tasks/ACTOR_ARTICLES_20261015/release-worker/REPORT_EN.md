# Actor articles release-controller handoff

This new, unexecuted controller set is adapted from the accepted Reader59 worker. It pins the actual baseline: Helm revision 59, build `quiz-2026.10.15-reader-06dfa0b`, image `docker.io/library/quiz-master@sha256:95ad1112d272b6cec48d517b350285ed560687cec4a8fc8f7d1b99e6d27cf2af`, and PVC `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`.

The target contract is strict: existing 279 articles and 160 references are unchanged; exactly `question:cinema-oct3-001` through `004` add four bindings from `prep-film-actors-1`, giving 283 articles, 164 references, 162 playable references and two noncatalog references. Frozen source is `d204f9b69f941b51e41edcaed3bd9832a16e8035`, target build is `quiz-2026.10.15-actors-d204f9b`, actor-export hash is `6fa80af3ad71003d6deb51ca64e91ae736b2c7bece21039978830cd33cf80dc8`, and Reader59 baseline archive hash is `6ddd12317732d0fa5bf87f8a80ff24e7ef71b50a233d7d65fa4249421a6c79ab`.

The native helper's first nine tests passed, but independent Opus review returned
12 concrete REWORK findings. They included baseline counts in the successor
metadata/verifier, old archive/JS/rollback pins, a second preflight definition
that would leave the old guard active, and missing real-archive negative tests.
The unchanged initial review is retained in `../controller-rework-review.json`.

Root then took exclusive ownership under Hub task
`task-2523b71184794acda8cd4eebdeafd192`. The real pinned revision 59 archive now
transforms to 283/164/162 metadata and runtime checks; one revision 59 preflight
definition replaces the inherited definition in place and remains at all three
image preparation boundaries. The rollback root/checksum and old image/JS pins
come from that actual archive. New question/browser bindings require exact quiz,
question, revision, row count and source-link count.

Root restored the eight meaningful predecessor tests and added candidate-wrapper
and browser-revision/source-count regressions. Together with six remote tests,
all 16 passed. `../controller-tests.json` and `.txt` retain actual execution;
`../controller-source-delta.json` records the full ten-source dependency map.
The first expanded-suite harness run had a wrong fixture-function name; that
failure is preserved separately and is not counted as a pass.

This is still an inert source packet awaiting fresh independent acceptance.
Root's actual dual Flutter builds and isolated mobile-browser 20-question run
are recorded outside this worker folder. No package, SSH preparation, immutable
image or publication has run for this successor. Historical accepted controllers
were not edited. Android and physical screen-reader checks remain outside scope.
