# Platform research: difficulty, controlled tags, selection

**Scope and baseline.** This is read-only research against packet baseline
`e802ed21db936bdb9809bab2d137903eb0aa425e`.  The packet inventories 126 packs /
3,958 questions and 883 missing legacy difficulty values.  The current collection
test still asserts 118 / 3,878 at
`next/server/internal/sqlite/collection_test.go:60,104`; reconcile that drift
before making migration counts a release gate.  No production file was changed and
no build or test was run for this report.

## What exists now

1. `content.Import` accepts only the legacy question keys at
   `next/server/internal/content/import.go:112`.  It accepts a numeric integral
   `difficulty` in 1..10 (`:146-160`), but immediately loses its value: 1..3 is
   `easy`, 4..7 is `medium`, 8..10 is `hard`; absent/null becomes `unknown`.
   `Question.Difficulty` and `PublicQuestion.Difficulty` are strings
   (`next/server/internal/content/types.go:35-44,76-85`).  Thus an existing 7 is
   indistinguishable from a 4 after import, and 9/10 cannot become Nightmare.

2. Draft, published bundle, and public-question schemas are closed
   (`additionalProperties: false`) and require the three-band field:
   `draft-quiz.schema.json:6,27`, `published-bundle.schema.json:6,23`, and
   `public-question.schema.json:4-7`.  `ValidateDraft` and `ValidateBundle`
   schema-check then validate links and hashes at
   `next/server/internal/content/validate.go:69-156,181-212`.
   `Build` projects draft questions to public questions and only keeps grading
   private (`:273-293`).

3. Canonical revision hashes cover the whole question/draft, while the bundle hash
   covers the full controlled bundle.  `Rehash` explicitly recomputes those
   hashes (`next/server/internal/content/canonical.go:211-231`); validation will
   reject stale values rather than repair them.  `quizctl import/build` validates
   and writes deterministic canonical JSON (`next/server/cmd/quizctl/main.go:102-164`,
   `next/server/internal/content/output.go:52-84`).

4. The public Flutter DTO is deliberately strict: it permits only
   `unknown|easy|medium|hard` and then discards the difficulty display value
   (`next/apps/quiz_app/lib/api_models.dart:116-190`).  `Catalog`, `Attempt`, and
   snapshots are also closed parsers (`:398-579`).  A new server field therefore
   requires the app parser and models to ship in the same compatibility release;
   otherwise the client rejects the entire catalog/attempt response.

5. Discovery is currently an asset, not an API: `CatalogPack` accepts only five
   metadata keys and loads `assets/catalog.json`
   (`next/apps/quiz_app/lib/discovery.dart:3-51`).  Search is client-side only
   across title, description, and category (`:104-125`).  Existing pack discovery
   and route handling create 20-question round chips at `:232-280`.

6. The selected pack API is `GET /v1/catalog?quiz_id=...` and
   `POST /v1/attempts {quiz_id, round?, mode?}`
   (`next/server/internal/httpapi/attempts.go:50-120`).  The request decoder rejects
   duplicate, case-aliased, null, and unknown fields (`:220-300`).  Flutter posts
   exactly those fields at `next/apps/quiz_app/lib/api_repository.dart:105-134`,
   then cross-checks its attempt against that catalog
   (`next/apps/quiz_app/lib/journey.dart:91-111,176-191` and
   `api_models.dart:557-579`).

7. `sqlite.newCollection` imports every source pack, validates/builds all of them
   before one transaction persists their immutable bundles
   (`next/server/internal/sqlite/collection.go:16-105`).  Selection is currently
   only by one `quiz_id` (`:108-130`).  A round is a *positional*, 20-question
   slice of that one public quiz, shuffled only inside the slice
   (`:133-165`); it has no difficulty/tag filter.  The HTTP selection test is
   `next/server/internal/httpapi/selection_test.go:27-42` and the no-gap/no-repeat
   round test is `next/server/internal/sqlite/rounds_test.go:13-85`.

8. Attempt replay is intentionally immutable.  SQLite stores controlled bundle and
   manifest by `(bundle_sha256,bundle_version)`, plus each pre-reveal public
   question/snapshot (`next/server/internal/sqlite/schema.go:27-31` and
   `attempts.go:91-165`).  Finish/reveal reload those stored bytes, rather than the
   current collection (`attempts.go:251-348`; collection proof
   `collection_test.go:91-99`).  This is the boundary that difficulty/tag migration
   must preserve.

## Smallest compatible contract path

Keep `difficulty` as the **canonical band enum** and add its exact, optional
numeric source value as `difficulty_level`:

```json
{
  "difficulty": "hard",
  "difficulty_level": 7,
  "editorial_tag_ids": ["country:ge", "topic:capitals"]
}
```

New required mapping is `1..3 => easy`, `4..6 => medium`, `7..8 => hard`, and
`9..10 => nightmare`.  A missing legacy value stays `difficulty:"unknown"` with
no `difficulty_level`; it must not be guessed.  The new band enum is
`unknown|easy|medium|hard|nightmare`.

Make `difficulty_level` optional in v1 readers so an already-published v1
draft/bundle can still validate.  For new imports/edits, `ValidateDraft` must
enforce both directions: known band has an integral level 1..10 and exactly its
derived band; unknown has no level.  This preserves strictness while allowing an
incremental content migration.  Extend the three closed schemas and both Go
types, then use `int *` / omitted JSON rather than a `0` sentinel.  Update the
importer's allow-list and mapping directly; it already rejects nonintegral/out of
range legacy values.  The `content_test.go:33-61,117-122` fixture family is the
right place to lock all ten boundary values.

Use one **predefined controlled tag dictionary** outside `quizzes/` (otherwise
`WalkDir` would try to import it as a legacy pack).  Give it a version, canonical
SHA-256, stable typed IDs such as `country:ge` and `ingredient:cardamom`, Russian
labels/aliases, `filterable`, and `player_safe` flags.  Validate it before any
question annotations and reject unknown/duplicate IDs.  The taxonomy worker owns
the vocabulary; this path needs only its stable IDs and hash.

`editorial_tag_ids` are question-level private metadata.  They belong in draft
questions and a new private per-question bundle metadata map, analogous to
`private_grading`; they must not be copied to `PublicQuestion` or the discovery
asset.  This permits country and ingredient selection without exposing an answer
hint (for example a flag question whose country is otherwise unnamed).  Only a
separate future `player_safe_tag_ids` projection may reach a public DTO, and only
when every dictionary entry is marked safe.  Tags that describe the correct
answer default to editorial-only.

This does require exact question revisions and bundle hashes to change when a
level/tag is attached: that is correct because the controlled content changed.
Run `Rehash`, build a newly versioned bundle, and retain old bundle rows.  Do not
rewrite `attempt_bundles`, `attempt_questions`, answers, or old manifests; their
stored public JSON and controlled bytes continue to grade and reveal old attempts.

## API and UI increment

**Phase 1: per-pack difficulty now.** Add an optional `difficulty` selection to
the existing attempt request, scoped to `quiz_id` and `round`.  A compact request
shape is `{"quiz_id":"...","round":0,"difficulty_levels":[4,5,6]}`.  Reject
unknown fields and values outside 1..10, deduplicate/sort server-side, filter
before the existing within-slice shuffle, and return a validation error when no
questions match.  The attempt still uses that pack's normal immutable bundle;
its snapshots are the authoritative selected set.  The catalog request should
return derived per-band counts (not correct-answer-related tags) so Flutter can
disable empty choices.  The client adds an Easy/Medium/Hard/Nightmare picker to
the current pack/round card and sends its levels through `JourneyController`.

The present positional definition of a round needs an explicit product decision:
filtering a pre-existing 20-question slice can yield a short round, while
filtering the whole pack then partitioning produces useful difficulty rounds but
changes what “round 2” means.  Recommend the latter for the new filtered mode,
with a request field such as `selection_mode:"difficulty"`; leave unfiltered
rounds byte-for-byte/current-order compatible.  Do not silently reinterpret old
URLs or old requests.

**Phase 2: controlled cross-pack collections.** Do not overload `quiz_id`.
Add a versioned `selection` object and a capability such as
`StartSelection(ctx, owner, spec)`, with allowed dictionary tag IDs,
`difficulty_levels`, count (initially fixed at 20), and an explicit any/all tag
operator.  Filter against the private in-memory index built after collection
validation.  Create and persist a deterministic, immutable composite controlled
bundle containing precisely the selected public questions, private grading, tag
dictionary hash, canonical selection spec, and each source quiz/revision.  Then
use the existing attempt/snapshot/finish/reveal path unchanged.

The composite bundle avoids a serious shortcut: finish currently obtains grading
from one bundle by question ID.  It also makes a replay independent of a later
dictionary or source-pack edit.  Current packet data happens to have 3,958 unique
legacy source question IDs (read-only duplicate scan), but a collection validator
must enforce global canonical question-ID uniqueness or namespace copied IDs
before supporting cross-pack composites; `ValidateCollection` today only checks
quiz IDs (`next/server/internal/content/validate.go:158-172`).

For Phase 2 discovery, replace the temporary asset-only provider with a narrow
public search/preview endpoint that exposes only player-safe pack metadata and
aggregate counts.  Keep editorial tag matching server-side.  Do not put raw
question tag IDs in a pre-answer public catalog simply to implement search.

## Migration and verification checklist

1. Schema/type/parser contract tests: all ten levels; exact four-band boundaries;
   missing=>unknown; 0, 11, fractional/string/bool rejected; stale hashes rejected;
   Flutter accepts the new closed DTO and still rejects unknown/private fields.
2. Import/quizctl tests: legacy 7 maps hard and 9/10 Nightmare; source level is
   retained; rehash changes only annotated question/quiz/bundle identities;
   deterministic build and dictionary SHA/unknown-tag/duplicate-tag failures.
3. Privacy tests: `editorial_tag_ids`, private dictionary labels, and private
   metadata never occur in catalog, start-attempt, pre-finish snapshot, or
   discovery responses; player-safe projection is a validated subset only.
4. Per-pack selection tests: every selected snapshot is in the requested range;
   unfiltered current round remains 20+tail/no-repeat; no-match, malformed,
   duplicate, and unauthorized selection input fail closed; Flutter URL/state
   reload sends the same selection.
5. Cross-pack selection tests: any/all country+ingredient filters, deterministic
   candidate ordering before shuffle, duplicate canonical-ID rejection, 20 unique
   snapshots, composite bundle hash/spec/dictionary hash persisted, and no
   private grading/tag leak.
6. Historical-attempt regression: start and partially answer an old bundle,
   publish a level/tag annotation and new bundle, restart from the changed source,
   then finish/reveal/history the old attempt using its original stored controlled
   bytes and revisions.  Preserve existing ownership, idempotency, and early
   reveal-denial tests.

## Study questions (published 6 modules / 120)

**Include them.** The user’s “all questions” should include the six accepted,
published Study self-check modules: `nature`, `geography-countries`, `history`,
`greek-mythology`, `nature-evolution`, and `geography-maps`, each with 20
questions.  They are real shipped content, not the foreign `study/drafts/wave3/`
work; do not annotate or index that draft tree.  The current Flutter asset is
`next/apps/quiz_app/assets/study/catalog.json`, declared by
`next/apps/quiz_app/pubspec.yaml:68-72`.  A read-only count gives exactly six
modules / 120 questions.

The source-of-truth inputs are each accepted
`study/modules/<module>/module.json`, `questions.candidate.json`, and
`questions.key.json`.  `study/build.py:95-147` reads all six fixed module IDs,
keeps candidate questions blind (the candidate object must be exactly
`id,type,text,options` at `:124-140`), joins answers/explanations/source refs
from the private key, and requires globally unique question IDs.  The Flutter
export is explicitly limited to accepted modules and writes the asset at
`study/build.py:159-188`.  It is not a `quizctl` input: `quizctl` only handles
the canonical quiz-contract import/build commands (`next/server/cmd/quizctl/main.go:21-164`),
so do not feed Study files to legacy import or place them under `quizzes/`.

The runtime decoder is a separate, permissive Study path:
`next/apps/quiz_app/lib/study_pages.dart:8-85` deserializes the *full* local
question including `correct_answer`, explanation, and source refs from that
asset.  Practice is local, identified as `study-local` and visibly unranked
(`:503-620`, `:642-645`); it has no API attempt, catalog, replay, or ranked
selection integration.  Therefore it cannot safely become a source for the
ranked cross-pack API merely by adding it to the discovery asset.

**Narrow coherent inclusion.** Add the shared dictionary IDs plus
`difficulty_level` and `editorial_tag_ids` only to the private record in each
published module’s `questions.key.json` (or an equivalently validated private
Study annotation sidecar).  Extend `study/build.py` to validate those values,
the dictionary version/hash, six-module/120-question coverage, and a generated
private `study-question-index/v1` that contains `{module_id, question_id,
difficulty_level, editorial_tag_ids}`.  Keep candidate files blind and keep the
existing Flutter `questions` projection unchanged: it currently copies only the
candidate fields plus correct answer, explanation, and source refs
(`study/build.py:123-146,164-169`), so editorial tags are neither displayed nor
used as pre-answer hints.

The future metadata/selection CLI should consume the normal canonical index and
this private Study index as two declared providers under the same dictionary
hash.  A Study entry may appear in future metadata search/collection previews,
but it must be excluded from `POST /v1/attempts` until it is converted to a
validated, server-held immutable bundle with private grading and snapshots.  This
includes all currently published 120 questions now without claiming they are
ranked or weakening the attempted-answer/replay model.

Add focused checks for: all six accepted modules and 120 question IDs covered;
Wave3 drafts excluded; unknown/duplicate tags and invalid 1..10 values rejected;
generated Study index deterministic; no editorial fields in Flutter catalog;
and no Study item accepted by the ranked attempt endpoint before conversion.

## Recommendation

Freeze the four-band + optional `difficulty_level` contract and private controlled
tag-dictionary/annotation boundary first.  Implement the per-pack difficulty path
against existing round/attempt machinery next.  Treat cross-pack tag collections
as the following vertical slice because they require a composite immutable bundle
and a separate public discovery projection; skipping that snapshot design would
break the repository's pinned-attempt guarantee.
