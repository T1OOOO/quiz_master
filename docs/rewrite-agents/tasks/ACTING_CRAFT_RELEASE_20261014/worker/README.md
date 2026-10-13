# Actor release controllers and local package

The producer repairs the incomplete inherited prototype against the actual published Music release (Helm50). Root preserved the original prototype in `../worker-v1-incomplete`; it is not modified. The worker owns this directory and `.run/acting_craft_controller_senior_20261014` only. No Git index, app source, browser, SSH, Docker, server or real feedback mutation was performed.

| Pin | Exact value |
| --- | --- |
| Baseline build/source | `quiz-2026.10.13-music-craft-f79555e` / `f79555e0659f0c20b86064b446ac582de323b2e9` |
| Baseline archive SHA256 | `ae4768f4a73d94976066f24bc80dcc31636d449428660706a91154c84930f9f7` |
| Baseline image | `docker.io/library/quiz-master@sha256:b94a399359f87024f5b00a53c47852a3e8f90f1ba6f4bb861385e9c2655f17d7` |
| Target build/source | `quiz-2026.10.14-acting-craft-b80deb1` / `b80deb12844aa786e9e0351273eab3f525ddce27` |
| Production JS SHA256 | `c92ec7cd0c53040d425c5fa97f904baa0b60b74ec2f0248837a5de601bcff1f0` |
| QA JS SHA256 | `716177c0496b31a95d701ebf6045fb6e4a60330c9882e25c2faf826a5b04844f` |
| Catalog SHA256 | `77c496394c4089a8895eb180b61592807e4c37ea15b81cb54eecc0be303be377` |
| Reader SHA256 | `f805bb0157e35e864d26f6fa6927e3b242720aa1a5b239465a0aa12b0b1c911d` |
| API SHA256 | `26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01` |
| Nginx SHA256 | `e9add812a138010e443463acb455295103dc69886ca32cd17dafbccfa676d6bc` |
| PVC UID | `7fc2428f-4146-4c78-a26d-2347d9f3b7bf` |
| Verified target archive SHA256 | `609567a55f2bb5a54476ae00d51cf26dbc26a5d810ab96fe5fb38b50f9e55f46` |

Baseline counts are 133 packs / 4052 questions / 252 Reader articles / 10 runtime cache entries. Target counts are 134 / 4060 / 260 / 11. All 133 old catalog rows, 10 cache objects, old raw quiz bytes and canonical content files survive exactly. Of the 252 old articles, 248 objects are unchanged; the other four differ only in the eight descriptive `source_links[*].title` values specified by the hash-pinned accepted `SOURCE_TITLES_20261014/proposed-music-articles.json` (SHA256 `541004c607877ec33d1260cfaad7ab1aa08494872773c5677538caeeec31da47`). URL, source support, text, IDs, refs and all other fields are preserved.

Eight new Actor questions and eight articles have sixteen primary source links. The producer verifies all eight raw/public/private/draft/manifest mappings, balanced keys `[0,1,2,3,0,1,2,3]` and accepted question revision hashes. Raw Git/archive bytes remain CRLF, SHA256 `a3fa877452956691f048d1cd129756a64a6e94de23a09d7752680c6a4ed11963`. Quizctl's manifest pins normalized LF bytes, SHA256 `5df21fce18ef2710d5b821eeb0a3ad3ca7d854146b0cccf479cdcaca688f8013`; the controller verifies both deliberately. The ten baseline runtime IDs retain their real `20261011` Encore/People suffixes.

The final package record is `.run/acting_craft_controller_senior_20261014/package-v2/package-preparation.json`, with the adjacent stage and tar.gz. Both fresh producer runs returned exit0 and identical archive bytes: 313 members and 156 reconstructed private staging revisions. Those revisions change only the known staging source URI. The staged Linux rehearsal expects 11 canonical packs / 156 questions plus NewYear55 = 211 graded answers and 12 finished histories. These are expected assertions, not claimed rehearsal results. Existing row preservation, NewYear key coverage, feedback lifecycle on a copy and old API rollback are retained.

```powershell
python docs/rewrite-agents/tasks/ACTING_CRAFT_RELEASE_20261014/worker/prepare_acting_craft_release.py --repo C:/ap/quiz_master --frozen-commit b80deb12844aa786e9e0351273eab3f525ddce27 --production-web C:/ap/quiz_master/.run/acting_craft_release_20261014/production-web --qa-web C:/ap/quiz_master/.run/acting_craft_release_20261014/qa-web --output-root C:/ap/quiz_master/.run/acting_craft_controller_senior_20261014/package-v3 --prior-archive C:/ap/quiz_master/.run/music_craft_controller_repair_20261013/package-v1/quiz-2026.10.13-music-craft-f79555e.tar.gz
python docs/rewrite-agents/tasks/ACTING_CRAFT_RELEASE_20261014/worker/negative_checks.py --package-json C:/ap/quiz_master/.run/acting_craft_controller_senior_20261014/package-v2/package-preparation.json --scratch C:/ap/quiz_master/.run/acting_craft_controller_senior_20261014
python docs/rewrite-agents/tasks/ACTING_CRAFT_RELEASE_20261014/worker/prepare_remote.py --release-dir C:/ap/quiz_master/.run/acting_craft_controller_senior_20261014/validation-evidence --verify-package
```

The output root must be absent or empty. Negative tests mutate only the owned stage and restore every mutation in `finally`; they verify the package again at the end. Actual command logs, including the initial red baseline regression and two test corrections, remain in the owned scratch. The first failed mutation test hit the stronger normalized raw digest before the semantic guard; the digest check now follows the semantic checks without weakening either. The second test selected the first newly sorted Actor article instead of an old article; it now selects an old article by ID. No historical report or accepted callback was rewritten.

## Root evidence and release gates

Root copies the real package record to `package-current.json` in the release evidence directory. `--verify-package` is locally runnable before any approval exists. Default `prepare_remote.py --release-dir <dir>` previews only after the real static review and browser gates. Root alone runs explicit `--prepare`. The remote controller verifies host `racknerd-f0269d5`, baseline image, original PVC, canonical release directory, disk and absent target, uploads only the exact archive, and invokes prepare-only cutover. That shell takes a fresh secure backup, rehearses a copy, checks image/API/Nginx/JS, durable image archive and Helm dry-run; it cannot publish.

`static-review.json` requires actual accepted independent Hub callbacks in `actual_reviews` or `actual_review`, each `{call, actual_response}`, with distinct reviewer and assignee, `actual_hub_state: ACCEPTED`, actual `reviewer_provider` (`claude`, `anthropic` or `antigravity`) and `actual_cli_exit: 0`. It must bind `package_sha256`, `producer_sha256`, `prepare_controller_sha256`, `publisher_controller_sha256`, `browser_evidence_sha256` and `root_browser_evidence_sha256` to current bytes. The worker supplies no accepted record.

`browser-proof.json` uses the explicit named agent-browser CLI schema:

- `frozen_source.git_revision`: target full source SHA.
- `actual_clean_ui_answers: 8`, `actual_clean_server_score: 8`, `new_article_sheets_opened_closed: 8`, `source_controls_each: [2,2,2,2,2,2,2,2]`.
- `music_source_label_articles_checked: 4`, `actor_fixture_answer_rows: 8`, `feedback_submissions: 0`.
- Actual `clean_qa_flow_actual_exit: 0`, `named_agent_browser_close_exit: 0`, `named_agent_browser_session_inactive: true`.
- Actual integer `fixture_api_exit`, `shutdown_method: owned Windows TerminateProcess`, `server_wrapper_actual_exit: 0`, `all_captured_owned_pids_gone: true`, `fixture_processes_gone_verified: true`, `ports19090_19093_free: true`.

Windows intentional `Popen.terminate()` uses TerminateProcess and can report API exit1; no graceful API exit0 is invented. Root's wrapper must complete successfully and independently observe every captured owned PID gone and both ports free. This is separate from the future Linux copied-DB API lifecycle. The old SDK stop acknowledgement is removed.

`root-local-browser-verification.json` separately requires `actual_frozen_source`, `root_visually_inspected_eight_questions_eight_source_footers_score8`, `four_music_source_labels_verified` and `native_artifact_hashes_verified`; static review binds its exact bytes. Root must record its actual failed first browser run and repaired flow honestly. Mobile width390x844 is layout evidence; touch0 and physical Android remain uncertified.

Root records real preparation outputs in `execution-packet.json`: exact build/source/package/image/values, successful `remote_prepare_exit`, hash-bound remote log, durable image archive and hash, backup/rehearsal/disk/Helm-dryrun hashes, local browser hash, publisher source hash and exact `publish_script_sha256`. `actual_copy_rehearsal` requires `canonical_packs: 11`, `canonical_questions: 156`, `newyear_questions: 55`, `total_graded: 211`, `practice_finished: 12`, `old_rows_preserved: true`, `feedback_lifecycle_copy_only: PASS` and `old_api_rollback: PASS`. These fields can only be populated after actual preparation.

Before execution acceptance, Root may call `publish_script(package, execution, stage, prefix, verify_hash=False)` to render the inert exact publication shell for independent review; `prefix` is the staged shell before `quiz_image="quiz-master:$quiz_build"`. Local syntax/mode tests use historical Music execution hashes solely as render-test data, never as Actor image or execution evidence.

`save_execution_acceptance.py --release-dir <dir> --trace <actual-review-jsonl> --exit-json <actual-exit-json> --task-id <actual-execution-review-task> --reviewer-provider claude` writes only after an actual successful independent Hub callback and successful final CLI result. It binds the complete execution packet and image/package/script/controller/browser hashes. Missing callback writes nothing.

`publish_prepared.py --release-dir <dir> --preview` validates accepted execution locally. Default is also read-only. Root alone runs explicit `--publish` after actual independent execution acceptance. The publisher converts exactly one prepare-only guard to publish-only, consumes the prepared immutable image, checks durable archive/baseline/PVC, repeats backup/copy rehearsal/disk/Helm/server checks, executes atomic waited Helm upgrade and verifies exact public metadata/JS/Reader bytes. It never rebuilds.

## Completed checks and remaining gates

Actual local checks passed: baseline red-to-green regression, two real producer runs with deterministic identical archive, full member/checksum/frozen-Git/source parity, preservation and normalized-digest checks, 22 negative rejections, full shell syntax for prepare/publish/remote guard/remote preparation and four actual Bash mode branch exits. The owned Python files compile. No real rehearsal, image, browser QA, approval or publication is implied by these checks.

Independent Claude review, Root's real browser proof, remote preparation/copy rehearsal/image/Helm proof, real independent execution approval and Root publication remain separate gates. Root owns Git/Beads/remote handoff. Root reports the real baseline has 26 OPEN feedback reports; this worker made no network calls and did not touch those reports. Local negative tests submit zero reports and write zero approval artifacts.
