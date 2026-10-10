# Older question article binding repair

Beads quiz_master-ch4. The published new 20 culture questions exposed 25 older
articles whose question revision refs differed from the legacy questions actually
served by the API: LOTR 3, ballet 1, musicals 1, Harry Potter 10, Terminator 10.

Captured five public catalog DTOs with URL/time/hash provenance. The existing
article builder now prefers a trusted tracked public snapshot, with canonical
fallback when absent. No canonical question, answer key, article body/source link
or factual author/reviewer identity changed. Exactly 25 question revision refs and
25 dependent review hashes changed. Six accepted planet articles are retained.

Independent native review accepted; actual Gemini text-only review accepted
(14.1 seconds, execution evidence evaluated as supplied). Lead checked every
affected draft/review against HEAD and ran four Python tests. Snapshot precedence
was observed RED before the change and GREEN afterwards; canonical fallback and
obsolete-revision coverage remain tested. Reader export validates 182 articles:
25 ref-only changes and 157 entire articles unchanged. All 69 unrelated file
hashes are preserved. Flutter reader tests passed 4/4 after export. Lead additionally refetched all five
production catalogs: all 25 repaired refs still match exact current revisions.

Published build `quiz-2026.10.11-culture-486901a`, source commit
`486901a45d77c0f1889dfa32c0a080be9f854dfc`, Helm revision 29.
Image `docker.io/library/quiz-master@sha256:528ac3e7e9fe05db1a7d8aa5d93013f72451734541fcebd7cdf668cf63adada9`.
Web build passed in 119.7 seconds. API and JS hashes remain unchanged. Public
reader SHA256 `37bc92c4a55ecb72ee5dfebd23f7aa44700c300af7b1321c197b6876c36d03d6`.
Public JS, catalog and reader bytes exactly match the staged package; all 55
served question/article refs match freshly fetched API revisions.

Fresh backup `/opt/quiz-master/backups/quiz-2026.10.11-culture-486901a-cutover-20261010T221435Z.sqlite`
passed integrity and restoration. Copy rehearsal preserved every original row:
counts [85,85,650,229,14412,938]; versioned staging catalog increased bundle
count 229 to 357 as expected from its own filesystem provenance. Original data
hashes, answer grading for both new packs, fake-copy feedback lifecycle and old
API rollback passed. Helm lint, image hash/nginx checks and server dry run passed
before atomic publication. These feedback tests only touched the isolated copy.

Normal browser context, mobile viewport 360x640: Harry Potter q001 and LOTR q1
both showed Learn more and opened their repaired articles. Harry Potter source
footer reached by reader-container scrolling, official source opened in a new
tab. Screenshots visually inspected; no horizontal overflow or JavaScript errors.
Browser closed after verification. Native phone gestures were not verified.

Exact image retained via Docker save after matching deployed image ID:
`/var/lib/rancher/k3s/agent/images/quiz-master-486901a-528a.tar`, SHA256
`e4f252d1d4eee747379e4247ea5d52580633bc9ad10fb154c4a139c0dadc7941`.
Previous verified images and backups remain. This is retention, not a full
cache-loss/restart recovery rehearsal (quiz_master-ie7 remains in progress).

Worker test file had one trailing empty line caught by staged diff --check;
lead removed only that blank line and reran all four Python tests successfully.
Worker evidence hashes describe its submitted pre-whitespace-cleanup state.
Gemini's release review is static supplied-text evidence; its wording about
checking 182 refs is broader than the script's exact assertion. There are 182
articles; rehearsal checks 45 affected/new refs, post-publication checks all 55
served question refs. No test of every target-linked article is claimed.

All 26 real production feedback reports remain open, latest 2026-10-07T08:19:08Z;
none resolved or submitted by this content release. No full-bank fact audit or
physical Android verification is claimed. All 69 unrelated file hashes preserved.
