# Independent history20 review — `review-history20-oct3`

Status: **REVISE (source-provenance documentation only)**. Blind solve, answers,
wording, distractors and generated parity are accepted; the source facts were
checked independently. The remaining correction is to synchronize the source
ledger and stale evidence-status notes with the final twenty-record bank.

## Blind candidate solve (before key/legacy)

| ID | Independent answer |
|---|---|
| history-001 | А — 4 июля 1776 года |
| history-002 | Б — 24 октября 1945 года |
| history-003 | Г — Аполлон-11 |
| history-004 | В — Восток-1 |
| history-005 | Б — 1957 |
| history-006 | А — Иоанн Безземельный |
| history-007 | В — 1789 |
| history-008 | Г — 9 ноября 1989 года |
| history-009 | А — Афины |
| history-010 | В — Париж |
| history-011 | Б — 1893 |
| history-012 | Г — Средиземное и Красное |
| history-013 | В — Атлантический и Тихий |
| history-014 | А — Монтгомери |
| history-015 | Г — Валентина Терешкова |
| history-016 | Б — Тим Бернерс-Ли |
| history-017 | А — Долли |
| history-018 | Г — Майнц |
| history-019 | Б — 1901 |
| history-020 | В — Данди |

## Fact and item review

All blind answers match the final intended answer. Every item has four unique,
parallel choices, no second defensible answer under its wording, and a 31–36
word explanation. Candidate, editorial key, authoring source and legacy match
exactly under the generator check.

| IDs | Verdict | Independent finding |
|---|---|---|
| 001–002 | ACCEPT | National Archives correctly separates 2 July vote, 4 July adoption and 2 August signing; UN Treaty Collection correctly separates 26 June signature from 24 October entry into force under Art. 110. |
| 003–005 | ACCEPT | Apollo 11’s *landing* (not first-step UTC), Vostok 1, and Sputnik 1/1957 distinctions are precise. |
| 006–008 | ACCEPT | John at Runnymede in 1215, Bastille/1789, and the qualified 9 November 1989 opening of crossings are correct and avoid the common overclaims. |
| 009–011 | ACCEPT | Athens is explicitly “modern” Olympics; the UDHR city is Paris; New Zealand is restricted to women’s parliamentary vote in the first self-governing country, not every political right. |
| 012–014 | ACCEPT | Suez distinguishes water connection from 17 November 1869 inauguration; Ancón’s Atlantic–Pacific passage is correct; Rosa Parks is correctly located in Montgomery and her seating nuance is accurate. |
| 015 | ACCEPT | NASA’s 1963 chronology search body supports Tereshkova/Vostok 6/48 orbits. The 18 MB official PDF cannot be opened by this reader, so the record honestly says search-body evidence rather than inventing an open receipt. |
| 016–017 | ACCEPT facts; REVISE provenance note | CERN’s live page directly confirms Berners-Lee, 1989, scientific information sharing and the first site; Roslin’s live page directly confirms 5 July 1996, first mammal from an adult cell and the earlier embryonic-cell clone. Replace their stale “Open receipt pending” notes with the current received-open evidence. |
| 018 | ACCEPT | LOC’s guide is currently rate-limited (429) but its received official search body supports Mainz, 1454–55, Gutenberg/Fust and the carefully limited “Europe” claim. Keep that status honest rather than calling it open. |
| 019 | ACCEPT | Nobel’s source endpoint is currently 403, but the received official article body explicitly says 27 November 1895 will and first prizes on 10 December 1901; official Nobel search results also confirm the 1896 death. The note truthfully records search-body evidence. |
| 020 | ACCEPT facts; REVISE provenance note | Gandhi Heritage Portal’s received official body confirms Sabarmati departure on 12 March 1930 and Dandi. This reviewer’s direct endpoint retry timed out, so it must remain labelled search-body evidence unless a successful open receipt is actually recorded; do not upgrade it merely by assertion. |

No requested “named wrong distractor” defect: the two explanations that instead
teach a useful historical misconception are still specific and pedagogically
defensible within the requested 20–45-word range.

## Required minimal correction

`source-ledger.md` presently contains detailed rows only for history-001 through
history-007 and describes future questions, while the frozen bank contains 20.
Extend it with the same received-evidence/limitation entries already present in
`authoring20.json` for 008–020. Refresh 016 and 017 from “Open receipt pending”
to actual received-open evidence. For 015, 018, 019 and this reviewer’s retry of
020 retain the accurate search-body/open-failure qualification unless a real
successful receipt is added. This is an evidence-audit correction, not a change
to candidate questions, answers or explanations.

## Fresh structural check and input hashes

From `C:/ap/quiz_master`:

```
python docs/rewrite-agents/preparation-history/render_check.py --check
# PASS: history20; positions5each; unique4options; words20–45;
# full candidate/key/legacy parity
```

Answer positions are five each: `А=5, Б=5, В=5, Г=5`.

| File | SHA-256 |
|---|---|
| authoring20.json | `500503289b80c6bc0620033c8d11070f71aa740b93598da417f8115ec77f90b9` |
| candidate.md | `def7de52330825e9b038f774e2f3e483b51842bf22bcb235d2b4e69e11b00a7b` |
| editorial-key.md | `35500c7789ca196412d6165e300a2981ec4315987fd20c922cf507fade927026` |
| legacy.json | `3194f2c79a78c36466149bc3d794b942441ad7b79b5f608ae20db3ee28681392` |
| render_check.py | `a471590f7902c11cb51657b297866617a453e1e45577af853f0c0c6a42af7b83` |
| source-ledger.md | `3926e36724be541dbb9681e01e4a3d0969b7c996d7d06215a6bc0d9e32d5c958` |
| coverage.md | `829c3ce82e9b6c2e6674d05dd9da87c6af25bf1c7c30f4f2483ff5b5fa1c03ec` |

---

## Re-review of provenance fixes — REVISE

The documentary ledger correction itself is sufficient: `source-ledger.md` now
contains all 20 events, records the successful CERN, Roslin and Gandhi opens,
and preserves the honest search-body/direct-fetch limits for 015, 018 and 019.
The duplicate scan is also adequate: the older Berlin item asks only for a year,
the earlier Declaration item asks its author, and the older cloning item concerns
a 1952 frog; none duplicates a new stem.

However, final deterministic parity is currently broken. Running
`python docs/rewrite-agents/preparation-history/render_check.py --check` fails
with `AssertionError: editorial-key.md`. `authoring20.json` now says, correctly,
that CERN (016) and Roslin (017) were received by open, whereas the saved
editorial key still says `Open receipt pending` for both. The renderer includes
`q['evidence']` in the editorial-key output, so this is an actual stale rendered
artifact rather than a report-only mismatch.

Required minimal action: run the existing renderer once against the frozen
`authoring20.json` (or make the exact generated `editorial-key.md` update), then
rerun `render_check.py --check`. Candidate and legacy should remain byte-identical
because they do not serialize evidence; no question, answer or explanation edit
is required. Until that check passes, this reviewer cannot convert the prior
provenance REVISE to FINAL ACCEPT.

Current corrected inputs:

| File | SHA-256 |
|---|---|
| authoring20.json | `46552cb76461bc366814f8bd03dd5ca8594f9cd8f1ae63ccdb76e8dc4b90cbf6` |
| candidate.md | `def7de52330825e9b038f774e2f3e483b51842bf22bcb235d2b4e69e11b00a7b` |
| editorial-key.md (stale) | `35500c7789ca196412d6165e300a2981ec4315987fd20c922cf507fade927026` |
| legacy.json | `3194f2c79a78c36466149bc3d794b942441ad7b79b5f608ae20db3ee28681392` |
| source-ledger.md | `5ecb88f142ee62e626fb14a4979c3e93abac01044cd71cf5711fb7621c0b674e` |
| coverage.md | `a2d3fcaddbb2ce311375a049e07b89db8e63b55b83b7e01e8e01e16bd20b3264` |

---

## Final render re-review — ACCEPT

The existing deterministic renderer has now been run against frozen
`authoring20.json`. `render_check.py --check` passes: 20 questions, positions
5/5/5/5, unique four options, 20–45-word explanations and full
candidate/key/legacy parity. The editorial key now contains the current CERN and
Roslin received-open evidence; candidate and legacy remained unchanged, as
expected because they do not serialize evidence. The previous source-provenance
and render-parity findings are resolved. This is an independent review ACCEPT,
not publication or canonical-import approval.

Final editorial-key SHA-256:
`a8b09df882892d81bbd5f6faeeeda8ed9ac255e8b566afc450afbbf8b9330202`.

