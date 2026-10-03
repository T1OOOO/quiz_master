# Independent BOOKS60 review — `review-books60-oct3`

Status: IN PROGRESS. Blind solve of all candidate questions precedes access to
the editorial key, legacy records, source evidence and checker.

## Blind solve (candidate only)

Classic 01–15: `A B C D A B C D A B C D A B C`.

Classic 16–30: `A B C D A B C D A B C D A B C D C D A`.

Modern 01–15: `B C D A B D B A D C B A D A C`.

Modern 16–30: `B C D A B C D A B C D A B C D`.

All 60 independent answers identify the named author; for Classic-28 this is
Homer under the candidate’s explicit traditional-attribution qualifier.

## Verdict — REVISE

The 30 added candidate answers, Russian explanations (40–65 words), author
facts and named distractor distinctions are substantively sound. The additions
are 7/7/8/8 by answer letter and non-cyclic. However final ACCEPT is blocked by
an unsafe checker/snapshot workflow and several source-date records which remain
pending, contradictory or not linked from the private key.

| New ID(s) | Verdict | Review result / minimal correction |
|---|---|---|
| classic-16, 18–23, 25, 27–30 | ACCEPT | Hugo, Stevenson, Stoker, Doyle, Twain, Tolstoy, Gogol, Chekhov, Dante, qualified Homer, Verne and Barrie are correctly answered; explanations name a meaningful work-specific cue and a defensible wrong author. |
| classic-17 | REVISE source date | LoC source is an 1888 catalogue record. It supports a pre-1945 upper bound and Dumas/Maquet qualification, but not the private claim of original 1844 publication. Add an original-edition/library source or state only the supported upper-bound classification. |
| classic-24 | REVISE source date | The cited Gutenberg text is a 1917 edition, while the record asserts 1862 original metadata. Add a source for original publication or remove the unsupported precise-date assertion. |
| classic-26 | REVISE source date | The cited Gutenberg biographical text supports Pushkin and Pugachev research but not the asserted 1836 original-publication record. Add a direct bibliographic source. |
| modern-16, 18, 23–30 | ACCEPT | Herbert, Morrison, McCarthy, Mitchell, Martel, Tartt (both works), Kundera, Pasternak and Solzhenitsyn are correctly attributed; each explanation distinguishes a real author/work cue. |
| modern-17 | REVISE evidence link | WorldCat’s live library record confirms Atwood, McClelland & Stewart/Toronto/1985, but the editorial key links only a PRH reading-resource PDF. Put the actual WorldCat URL in the record/key source list and remove the stale authoring “verification remains required” text. |
| modern-19 | REVISE source contradiction | The cited Pan Macmillan page currently identifies a 2007 ebook, not the claimed original 2005 edition. The author’s own [books page](https://www.markuszusak.com/books) gives *The Book Thief* 2005; replace the date evidence with that direct source (or another actual 2005 first-edition catalogue), and update the key URL. |
| modern-20 | REVISE evidence link | [Ian McEwan’s bibliography](https://www.ianmcewan.com/books/atonement) directly gives London: Jonathan Cape, 2001, while the key links a PRH edition page. Link the evidence actually used for original publication. |
| modern-21 | REVISE pending classification | The final key still says original 2001 Spanish publication “requires primary-edition verification”. Official [Grupo Planeta](https://planeta.es/en/history) records *La Sombra del Viento* published in 2001; substitute it and clear the pending status. |
| modern-22 | REVISE pending classification | The final key still says original German 1985 publication “requires” verification. Official [Diogenes](https://www.diogenes.ch/factsheet2/rights?titleID=56b9e489-d4c9-4b04-9e6d-ccef3f0ae91a) says *Das Parfum* was originally published in 1985; substitute it and clear the pending status. |

The resolved date facts themselves are correct: WorldCat confirms Atwood 1985,
McEwan’s official bibliography confirms 2001, and Zusak’s own bibliography
records 2005. The issue is exact, auditable evidence linkage, not author-answer
accuracy.

## Preservation/checker blocker

`render_draft60.py` and `freeze_accepted30.py` both ignore `--check` and execute
their write paths. During the requested check invocation the latter rebuilt
`accepted30-snapshot.json` from the current 60-record files: it now declares
`question_count: 30` but contains 60 questions (SHA-256
`a1e345ab86d81f119ba1a15bd89a7f5eab55fd82e81cdf33314fc339ec1920c0`).
Consequently it cannot prove the prior accepted 30 are byte-identical. Restore
the original accepted30 snapshot from hub #403 evidence, add real read-only
`--check` behavior, then compare the saved first 15 classic plus first 15 modern
records to that restored snapshot. Do not treat the current generated outputs as
proof of frozen-30 preservation.

This reviewer accidentally exposed the unsafe behavior while attempting the
specified check and reported it promptly in hub #426/#428; no further author-file
writes were made by this review.

## Current evidence

The writer helper itself has no `--check` branch, so its successful process exit
is not validation. Current render artifacts have these SHA-256 values:

| File | SHA-256 |
|---|---|
| candidate.md | `307af9ebee260dbee249db3803a6835200c2bd379d885ec7cc841c22ae1a1cac` |
| editorial-key.md | `00e69340c2bfd8dd7d8d24ad69266c391e90d40b3c5f9000a98745cbff6c4942` |
| legacy-classic.json | `337e78a2bc3ee817f768abf85748ca27a1c2774bc440adea9738a0e74e709229` |
| legacy-modern.json | `dbd94cadf086253fa0cf0178412130a2ef4f617975c854e077464e6903d21e13` |
| working-source-ledger.md | `4de7990c0eed3b7b3a0dbcd080c58131bc0cd7dbf1b0c8ca262f5d89fe49c923` |
| render_draft60.py | `dee28d3979c404c489a299423815452bc9e5a8eb5db7ef379e84826ad93d5d15` |

## Re-review after source/check repair — FINAL REVISE

This section supersedes the provisional checker/snapshot disposition above.
The repaired `--check` modes are genuinely read-only: before and after both
checks, the SHA-256 values were identical for candidate, key, both legacy
files and the reconstituted snapshot.  Both commands printed PASS.  The
current 30 legacy records equal the 30 records in
`accepted30-reconstituted-snapshot.json`; that is a current-content
comparison, **not** historical byte proof.  The snapshot explicitly sets
`historical_byte_proof: false`, so the old accepted-byte SHA cannot honestly
be reconstructed.  That limitation alone is not a fact-quality rejection.

The factual re-review is positive for all 60 IDs: every blind-solved answer
matches the current intended author; explanations remain in the requested
40–65-word range with a work-specific cue and a real wrong-author distinction.
The repaired current links support the previously questioned classifications:
classic-17 (LoC 1888 upper bound, not an asserted 1844 first edition),
classic-24 (Gutenberg 1917 upper bound), classic-26 (no unsupported exact
original year), modern-17 (WorldCat: Atwood/McClelland & Stewart, Toronto,
1985), modern-19 (Zusak official bibliography: 2005), modern-20 (McEwan
official bibliography: Jonathan Cape, 2001), modern-21 (Grupo Planeta: 2001),
and modern-22 (Diogenes: original 1985).  Thus the answer/explanation fact
gate is ACCEPT for classic-01–30 and modern-01–30, subject to the two release
defects below.

| Scope | Verdict | Concrete evidence / required correction |
|---|---|---|
| classic-01–15 and modern-01–15 key source rows | REVISE | All 30 current rows say `см. accepted30-snapshot.json`. That reconstituted snapshot has no source URLs and expressly is not historical proof. The extant prior authoring materials retain the sources (`render_draft30.py` covers ten; the classic/modern step JSONs cover the rest). Render those actual URLs and classification notes into the current key/ledger; do not use the damaged snapshot as evidence. |
| new classic-16–30 and modern-16–30 positions | REVISE | The 30 positions are `0,1,2,3,0,1,2,3,0,1,2,3,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3`: balanced 7/7/8/8 and max run 1, but the first twelve are an obvious A-B-C-D cycle. Replace with a deterministic non-cyclic shuffle (the lead supplied a candidate sequence) and regenerate only after preserving source evidence. |
| current record parity | ACCEPT (limited) | `legacy-classic.json` + `legacy-modern.json` contain 60 unique IDs, 15 correct answers at each total position. The current first 30 exactly equal the reconstituted snapshot (30/30); this does not establish equality to the unrecoverable historical snapshot. |

`render_draft60.py --check` currently validates only the reconstituted input,
not saved candidate/key/legacy parity; `check_60.py` checks key ID presence but
not answer, explanation or source parity.  These are insufficient as release
evidence until the two defects above are corrected and independently
re-checked.  No authoring files were modified in this review.

### Fresh read-only check evidence

```
render_draft60.py --check  -> PASS: 60 renderer inputs valid; --check is read-only.
freeze_accepted30.py --check -> PASS: reconstituted snapshot has exactly 30 records; --check is read-only.
```

| Current input | SHA-256 |
|---|---|
| candidate.md | `307af9ebee260dbee249db3803a6835200c2bd379d885ec7cc841c22ae1a1cac` |
| editorial-key.md | `1f5780da3e59356dd97348a3aedc00656b89cbb8a1eb89c14750174efb397890` |
| legacy-classic.json | `337e78a2bc3ee817f768abf85748ca27a1c2774bc440adea9738a0e74e709229` |
| legacy-modern.json | `dbd94cadf086253fa0cf0178412130a2ef4f617975c854e077464e6903d21e13` |
| accepted30-reconstituted-snapshot.json | `9870a2398bb79eb59f2ab05ef96de300b7aadef6bc911f80638c922c19fdf189` |

## Final documentary re-review — ACCEPT

Both prior release defects are resolved.  The editorial key now contains 60
actual HTTPS source rows: the restored first-30 publisher/library URLs replace
the non-evidentiary snapshot placeholders.  The new-30 position order is
`2,0,3,1,2,2,1,3,0,1,3,0,2,1,3,0,3,2,1,0,2,3,0,1,2,3,1,2,0,3`:
7/7/8/8, maximum run 2, and non-cyclic.  The total 60 remains 15/15/15/15
with 60 unique IDs.

`render_draft60.py --check` was inspected before execution and then passed:
it compares current legacy records, all candidate texts/options, all 60 key
answers/explanations, and all 60 HTTPS source rows.  Before/after SHA-256
values were identical.  The historical snapshot is still honestly marked
`historical_byte_proof: false`; this review makes no historical-byte-equivalence
claim, only the checked current-content assertion and the restored evidence
links.

Final scoped verdict: **ACCEPT prep-books-classic-01–30 and
prep-books-modern-01–30**.  This is independent content/documentary acceptance
only, not publication.

Current final inputs: candidate `a402419fd2588e7d44a8aacc00c1cf14932a8517494e9a8a60505ae4f883a614`; key
`87e835ce1e105e836c3afe208146475b2c6a40c623a27e2f75c9f1015d00a519`;
legacy classic/modern `3ab9d9d04e424d42724e4e543cd4f32c59f0c27349c30c37c7d26d66425f8a8a`,
`c70a2f5a88601baefc3d201bc48988978b253c3d9282df88c10ca33ff8d06107`;
reconstituted snapshot `9870a2398bb79eb59f2ab05ef96de300b7aadef6bc911f80638c922c19fdf189`.

