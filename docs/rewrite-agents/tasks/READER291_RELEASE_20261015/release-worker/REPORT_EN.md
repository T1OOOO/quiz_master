# Reader291 release-controller repair

This source-only controller adapts the accepted Actor283 package to Reader291. It does not build, prepare remotely, deploy, publish, or claim acceptance.

The frozen target is commit `3482af9a8b7b7119f14069a791a77b36a8014c49` and build `quiz-2026.10.15-reader291-3482af9`. The baseline is deployed Helm revision 60: build `quiz-2026.10.15-actors-d204f9b`, image `docker.io/library/quiz-master@sha256:c4b5ba6564678b986bc74cb59b3d660e14bfc733a5633eab83c8d47cbffa4922`, and PVC `7fc2428f-4146-4c78-a26d-2347d9f3b7bf`.

The controller requires all 283 previous Reader articles and their 164 references to remain byte-identical. It accepts exactly eight additions, `question:cinema-oct3-005` through `012`, each bound once to `prep-film-actors-1`. The resulting contract is 291 articles, 172 references, 170 playable references, and two known noncatalog references. No questions, options, keys, API bytes, or catalog data are changed by this controller.

The source verifies the actual Actor283 archive layout before editing it. It replaces the inherited preflight with the revision-60 guard at all three image-preparation boundaries, retains the strict 20% available-space condition, rewrites the prior Actor283 image assertion from `95ad1112…` to the current `c4b5ba65…` image, and binds successor metadata and candidate checks to 291/172/170. Rollback rehearsal remains rooted at the Actor283 archive and its checksum.

The inherited suite initially failed: five of 16 tests errored because it had an empty four-article browser fixture, the Actor cleanup identity, an old JS hash and old rollback pins. `controller-tests-rework-failure.txt` records that reproduced failure. The controller fixture now reads the hash-pinned current Reader291 browser proof at `local-browser/browser-proof.json`: its eight article rows cover `cinema-oct3-005` through `012`, and its score is derived from the exact eight deliberate wrong IDs (`12/20`). It also checks the truthful failed-close record: owned native processes are inactive; it does not claim they are absent. The Actor283 archive is bound through the shared `BASELINE_ARCHIVE` path beside its SHA-256 pin. The repaired suite passed locally on 2026-10-15; this report remains a controller artifact, not a production browser receipt. Root owns the independent actual browser evidence.

Remaining gates are outside this worker: independent different-provider review, accepted integration source, root-owned frozen build/browser proof, package preparation, and any execution or publication authorization.

Latest local verification was `python -m unittest -v test_reader291_release.py test_prepare_reader291_remote.py`, exit 0: `Ran 18 tests in 23.151s`, `OK`. `python -m py_compile prepare_reader291_release.py prepare_reader291_remote.py verify_reader291_candidate.py reader291_guard.py test_reader291_release.py test_prepare_reader291_remote.py` also exited 0. The 18 tests include the current-proof admission regression, score mismatch rejection, inactive-process guard, old absent-only cleanup-field rejection, and shared baseline-archive path check.

The controller source map re-pinned for follow-up review is:

- `prepare_reader291_release.py` — `968e7a18122e1d76250815e30480b9f5cde3a66d1f23c71df050c40830168fa8`
- `verify_reader291_candidate.py` — `ee1030d95da5589feaf216c1e64e82c0ba4bab391c42fe181f3e14370878eda6`
- `test_reader291_release.py` — `27292a33bafedb2efbd73683c06bce9c6c4001c03097b7b0bec8d00c2b60d39b`
- `prepare_reader291_remote.py` — `bedd69aff765592246b4973bd338a89e1858cf7be7acd3e51e85cefd4c8c6672`
- `test_prepare_reader291_remote.py` — `bb51405c4fe06dd81a2d2db2e6d4d12eb0a6f7474d90b771c865b5c7eaa31228`
- `reader291_guard.py` — `5847bbcbbccce11bca011039006cc58288254f2f6792bad9f09dae1a9e13efed`
- `MIXED_RELEASE_20261014/worker/prepare_lotr_package.py` — `c9e4dc75574232a8f36f6ac1ee3e7a6039c398e721641335c54f4fb07332d0e0`
- `MIXED_RELEASE_20261014/worker/verify_candidate_runtime.py` — `dfd07f90c71e3106e0a73baac120921c59458111457f74ab1d67e64490a2afca`
- `MIXED_RELEASE_20261014/worker/test_verify_candidate_runtime.py` — `9269deebe4e65fe522d97e1c7d7ac20bdbc07afef808bcd1095a895c888eeceb`
- `MIXED_RELEASE_20261014/worker/prepare_remote_mixed.py` — `0d6f1d25438c06c889e41bf52e1eb982c266e6640fba610b8bc1df837bdf1103`
