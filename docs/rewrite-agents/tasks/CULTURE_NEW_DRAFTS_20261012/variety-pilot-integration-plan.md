# Two-question variety pilot — integration and release scope

This is a plan, not an import, acceptance, gate result, or publication record. It was prepared at `029cd9eb755349bb46c35c14889e94ed829cb4d0`.

## Current facts and hard stop

`variety-final.json` has SHA-256 `20821cb1c8e49280cec1c181c1f63f640480e64639cf38e3f0a6ad4b5f476d0a` and status `DRAFT_REQUIRES_INDEPENDENT_PROVIDER_REVIEW`. Its two IDs are `culture-variety-pilot-v2-01` (cinema) and `culture-variety-pilot-v2-02` (music). It must not be imported until the pending different-provider review accepts that exact final hash. A reviewer report alone does not authorize an import.

The local catalog currently reports 131 packs, 4,008 questions, and 206 accepted articles. The supplied production observation is immutable `quiz-2026.10.11-home-alone-e0d13f4`, image `sha256:5d41e68671f2ab8d3d01fe34a4a4b670f212d47000834c33913f2cc0e310861a`, with 26 feedback reports open. Therefore 131/4,010/208 is only a post-integration expectation to recompute from the exact staged tree; it is not a current or production claim.

| Pack | Legacy source | Current canonical bundle |
| --- | --- | --- |
| `cinema-people-20261011` | `quizzes/Cinema/People/cinema_people_20261011.json` | `next/content/cinema-people-20261011/{draft,manifest,bundle}.json` |
| `music-people-20261011` | `quizzes/MusicPeople/music_people_20261011.json` | `next/content/music-people-20261011/{draft,manifest,bundle}.json` |

The legacy sources, not the pilot JSON, are quizctl inputs. Keep the existing source spelling and `/app/quizzes/...` provenance: it is part of each question revision. Existing IDs, option order, `correct_answer` indices, source refs, and article revision refs are frozen. A candidate can supply only one new source question per pack after its facts, keyed option, and source links are independently accepted.

## Ownership and collision boundary

| Owner after acceptance | Exclusive paths | Collision rule |
| --- | --- | --- |
| Pilot writer | `variety-final.json`, source evidence | No canonical or reader edit. |
| Independent reviewer | A new review record only | Bind the final SHA and state `accept`; re-review any edit. |
| Lead/integrator | The two legacy source JSON files; both corresponding `next/content/*` triplets; catalog; a new two-article draft/review pair; generated reader catalog; a new release package | Take them as one integration change. No concurrent regeneration. |
| Release reviewer | New release-review evidence only | Reviews the exact staged package and actual outputs. |

The existing `study/drafts/*people-20261011.{candidate,key,packet}.json` are editorial evidence, not quizctl inputs. Do not rewrite them unless the lead explicitly assigns their reconciliation. Do not touch the immutable `.run/home_alone_repair_20261011/quiz-2026.10.11-home-alone-e0d13f4` package or reuse its `prepare.py`; it pins a different source/image baseline. Preserve the foreign-file baseline by running `.run/phobias_repair_20261011/verify_foreign.py` before and after integration; it checks the recorded 69 foreign hashes.

## Smallest accepted-content integration

1. Freeze the accepted reviewer JSON and source ledger together with `variety-final.json`; record SHA-256 values and HEAD. Reject a changed question/article or missing source-open record.
2. Make exactly two additions, one in each legacy source, using fresh unique legacy question IDs. The cinema item is the silver/ruby slippers adaptation objective; the music item is the Hendrix `Izabella` instrument-history objective. Preserve every existing parsed field and correct index.
3. Regenerate each affected canonical triplet. Capture before/after public question DTOs plus private `correct_option_id` mappings; require all ten old DTOs and mappings per pack to remain equal, with only the new question added. Existing question revisions must remain equal. The enclosing quiz/bundle revisions may change because the question list changes.
4. Add one `qm-question-articles/v1` file with the two articles and a separate independent review file. Each article needs a `question_refs` entry using the *newly built* quiz ID, question ID, and 64-hex revision, 100+ words, two distinct HTTPS source links with title/support/access date, and an `accept` review record containing `build.article_hash(article)`. Do not bind against guessed pre-import revisions.
5. Regenerate the reader catalog only then. `study/question_articles/build.py` rejects missing/stale refs, unaccepted reviews, omitted source metadata, duplicate bindings, and short articles; do not edit `question-articles.json` directly. Coverage is derived evidence, not publication evidence.

## Supported local commands

Run from `C:\ap\quiz_master`; use a unique new scratch directory, never a pre-existing Home Alone package.

```powershell
python .run/phobias_repair_20261011/verify_foreign.py
go run -p=1 ./next/server/cmd/quizctl audit --in quizzes

go run -p=1 ./next/server/cmd/quizctl import --in quizzes/Cinema/People/cinema_people_20261011.json --out .run/culture-variety-pilot-20261012/cinema
go run -p=1 ./next/server/cmd/quizctl validate --in .run/culture-variety-pilot-20261012/cinema/draft.json
go run -p=1 ./next/server/cmd/quizctl build --in .run/culture-variety-pilot-20261012/cinema/draft.json --out .run/culture-variety-pilot-20261012/cinema/bundle.json --version <new-approved-version> --published-at <RFC3339-UTC>
go run -p=1 ./next/server/cmd/quizctl validate --in .run/culture-variety-pilot-20261012/cinema/bundle.json

go run -p=1 ./next/server/cmd/quizctl import --in quizzes/MusicPeople/music_people_20261011.json --out .run/culture-variety-pilot-20261012/music
go run -p=1 ./next/server/cmd/quizctl validate --in .run/culture-variety-pilot-20261012/music/draft.json
go run -p=1 ./next/server/cmd/quizctl build --in .run/culture-variety-pilot-20261012/music/draft.json --out .run/culture-variety-pilot-20261012/music/bundle.json --version <new-approved-version> --published-at <RFC3339-UTC>
go run -p=1 ./next/server/cmd/quizctl validate --in .run/culture-variety-pilot-20261012/music/bundle.json

go run -p=1 ./next/server/cmd/quizctl catalog --in quizzes --out next/apps/quiz_app/assets/catalog.json --force
python study/question_articles/build.py --write
python study/question_articles/build.py --check
python study/question_articles/coverage.py
python -m unittest study.question_articles.test_build study.question_articles.test_coverage
python .run/phobias_repair_20261011/verify_foreign.py
```

`quizctl import`/ `build` replace final destinations only with explicit `--force`; staging first avoids overwriting canonical triplets before the DTO/private-grading comparison. Once comparison is accepted, repeat the exact two commands against `next/content/<pack>` with `--force`, validate both final draft and bundle, and retain the staged manifests/bundles as evidence. `quizctl diff` is useful only with a valid pre-change draft/bundle and returns a difference exit status for a real addition; that expected non-zero result is not a gate failure.

The bundle keeps `private_grading` and private editorial metadata server-side. The public catalog is allowlisted to pack metadata; the public question DTO omits grading. Verify built Flutter assets contain neither `private_grading`, `correct_option_id`, `correct_answer`, explanations, nor the editorial key file.

## Release path after local acceptance

The historic `CULTURE_20261011/release-cutover.sh` shows required controls but has stale source/image/hash/PVC/build constants. Create a new reviewed package from the exact integration commit; do not copy or run it. Its `prepare` mode must pin current production image/PVC, verify package/API/web checksums, take a fresh SQLite backup, rehearse in a new isolated directory, assert old rows and integrity, check both expanded 11-question packs and new article refs, exercise correct private-grading attempts, verify old-API rollback, build/load an immutable image, and run Helm lint plus server-side dry-run. Publish must be explicit and use `helm upgrade --atomic --wait --timeout 180s` under the deployment lock.

Before a release claim, run the agreed content/server and Flutter gates from the committed tree: `go test ./next/server/internal/content ./next/server/cmd/quizctl`, then in `next/apps/quiz_app`: `flutter analyze --no-pub`, `flutter test --concurrency=1`, and `flutter build web --release --no-pub --dart-define=QM_API_BASE_URL=https://quiz.kotopedia.org --pwa-strategy=none`. Build/rehearsal/browser/SSH commands are deliberately not run by this task.

After atomic rollout, fetch live version, JavaScript, catalog, reader asset, and both public catalog DTOs. Assert deployed hashes and all 22 question revisions; assert 11 reader refs for each affected pack; use a mobile viewport to answer each new question, open Learn more, and open both source links. Record a mismatch as a failed gate. Keep all 26 existing feedback reports open unless a separately verified fix closes one.

## Remaining unknowns

* The pending Claude verdict and exact reviewed-report path are unavailable; without them this plan stops before step 1.
* Final legacy wording, unique IDs, correct indices, source-ledger mapping, tag/taxonomy disposition, bundle version/timestamp, and release-package name are lead decisions after acceptance.
* Re-read production immediately before packaging; the supplied Home Alone image is a read-only observation, not a safe release baseline.
