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

Publication pending the new Web build, pushed source commit, fresh production
backup/restore/copy migration/rollback rehearsal, gated cutover, exact public
asset and 55 served question/article revision checks, and browser inspection.
Existing real feedback stays open. No full-bank or physical Android verification
is claimed.
