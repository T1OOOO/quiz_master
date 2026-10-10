# Content integration evidence — 2026-10-11

Two accepted packs add 20 questions, four options each, and 20 distinct Russian
miniarticles with 40 relevant source links. Cinema uses 12 opened Academy/BFI URLs;
music uses 17 opened museum/official artist URLs. Native reviewers solved all
20 keys independently. Actual Antigravity Gemini 3.8 Flash Medium reviewed both
exact final packets using supplied text and native source evidence; it did not
fetch URLs or approve deployment. Reports alongside this file retain that limit.

Initial generic articles were rejected. A Bengali-language phrase lacked support
in the two linked cinema sources and was removed. An unsupported assertion about
a representative accepting Billie Holiday's award was removed. Two unavailable
music links were replaced with accessible, relevant official pages before review.

quizctl imported and validated both canonical drafts and bundles. All 20 private
grading option IDs match the original editorial indices, including nonzero keys.
Both packets have index balance 0:2, 1:3, 2:2, 3:3. Normalized question stems are
unique across this batch and do not duplicate the previous 3958 stems. Difficulty
values are editorial estimates, not calibrated against player results. Proposed
tags remain in private editorial keys pending taxonomy review.

Reader export passed: 182 independently reviewed articles with exact question
revision bindings. All previous 162 accepted local articles and all previous 126
public catalog entries are unchanged. Catalog now has 128 packs / 3978 questions.
The private planet question pack remains unserved; two previously accepted local
planet articles are included in the reader export.

Existing content Go tests passed. Flutter analyzer passed. Discovery test first
failed at its hardcoded old count; only that fixture was updated to 128 / 3978.
Full Flutter tests, release build and publication evidence follow in RELEASE.md.
All 69 unrelated dirty/untracked file hashes were preserved before integration.
No claim is made about reviewing the full existing bank or resolving real feedback.

## Published-runtime binding correction

First post-publication browser check found that new articles did not appear.
The public-verification assertion failed: runtime provenance URI is
/app/quizzes/... while quizctl import used quizzes/...; source URI participates
in the question revision hash. The 20 new canonical artifacts were rehashed
using the exact runtime provenance URI with the existing Go content.Rehash/Build.
All 20 resulting public questions equal captured live catalogs byte-semantically.
Only question provenance/revisions, quiz revision/bundle hashes and article refs/
review hashes changed; stems, options, grading, article bodies and links did not.
Release rehearsal now asserts all 20 runtime article bindings BEFORE deployment.
The first publication is not counted as completion; corrected reader publication
and mobile browser verification are required.
