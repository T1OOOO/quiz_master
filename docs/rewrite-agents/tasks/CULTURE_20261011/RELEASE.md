# Verified publication — 2026-10-11

Final build: quiz-2026.10.11-culture-ba80671; source commit
ba806718e73689b7a536ba4d197b0856e88a70ab, pushed to codex/quiz-v2.
Helm revision 28; image docker.io/library/quiz-master@sha256:f746f1c06e567af4512a09004a1411a9b269beb782e45b1ef6a82ce984abcf8a.
Target racknerd-f0269d5, PVC UID 7fc2428f-4146-4c78-a26d-2347d9f3b7bf.

Added 20 independently source-reviewed questions and 20 miniarticles, two source
links each. Total public catalog 128 packs / 3978 questions; reader 182 articles.
All existing 126 catalog entries and 162 accepted local articles unchanged.
The reader also carries two previously accepted planet articles; the private
planet question pack remains unserved. Study modules remain 6 / 120 questions.

Gates: content Go tests, both canonical draft/bundle validation and exact grading
ID comparisons, article export/hash/binding validation, Flutter analyzer,
114 Flutter tests, four repeated reader tests after binding correction, release
web build. Gemini ran real finite official agy CLI content and script reviews;
its reviews used supplied evidence and did not independently fetch URLs or execute
release gates. Native content reviewers actually opened 12 cinema and 17 music
primary URLs. Detailed exact-hash reports accompany this file.

Release archive SHA256 cc795d7da617649940aec1ad373103e757a34af8c082b265b22f80e5359413db.
API unchanged SHA256 26e1657fd6259bdbbef9178cbe9343b775406d91c56cb9661d302ad530ab6f01.
Web JS SHA256 a6497dff4c48ea5b7c2c23e34fdeb86868961ea1abeeb2cf426fe25ee614714e.
Fresh pre-cutover backup:
/opt/quiz-master/backups/quiz-2026.10.11-culture-ba80671-cutover-20261010T215653Z.sqlite.
Rehearsal restored the backup into an isolated SQLite database: existing rows
preserved, integrity OK, report lifecycle and old-API rollback OK. All 20 practice
answers received correct feedback and both attempts finished. Staging URI prefix
was asserted and normalized only for semantic comparison; exact production public
revisions were checked separately via HTTPS before rollout. Default preparation
mode exits before Helm; publish mode runs these gates before atomic rollout.

Initial release 2e3516f passed offline export but its new articles failed the live
revision check. Root corrected provenance/revision bindings through existing Go
content.Rehash/Build and obtained independent recheck. An early corrected-release
rehearsal then stopped before Helm because staging has a different source path;
the prefix-aware check above resolved that distinction. No failing gate was
ignored. A Windows Bash line-ending error also stopped preparation and was repaired
with explicit LF output and regenerated checksums before publication.

Public verification: version matches exact package; JS, catalog and reader bytes
match staged artifacts; all 20 live question/article bindings match production.
Catalog/reader contain no private grading fields. On a 360x640 browser, new music
and cinema quizzes accepted an answer, showed Learn more, opened the article and
exposed two source buttons. Reader container scrolling reached source footer;
source buttons opened Rock Hall and Academy URLs in separate tabs. No horizontal
page overflow or browser JavaScript errors observed. Screenshots accompany this
file. Physical Android device and all question screens were not manually tested.

Durable image archive retained at
/var/lib/rancher/k3s/agent/images/quiz-master-ba80671-f746.tar
SHA256 f9fa927ec323ca934b75a70beadbb53470476dfd557b551311a7ffe8f216bebf.
An all-platform ctr export found a missing unused content object; the partial
archive was replaced atomically with Docker save after verifying the exact image
ID. This retention is not a full cache-loss/restart recovery rehearsal (ie7 open).
Previous verified image/archive and Helm revision remain available for rollback.

All 26 real production feedback reports remain OPEN; latest 2026-10-07T08:19:08Z.
No feedback report is resolved by this content release. A read-only wider binding
audit found 25 older stale movie/music reader refs (LOT R, ballet, musicals,
Harry Potter, Terminator); tracked separately as quiz_master-ch4. Six accepted
planet articles remain unchanged, with the planet QUESTION pack unserved.
Broader fact review and calibrated difficulty remain ongoing; no full-bank claim.
All 69 unrelated dirty/untracked file hashes were preserved; no GitHub Actions.
