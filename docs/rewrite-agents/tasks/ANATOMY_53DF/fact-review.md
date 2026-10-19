# Independent factual review — ANATOMY_53DF

**Packet label:** `anatomy-facts-53df`
**Reviewed candidate SHA-256:** `EBC7142A4EF26D1B7A380CB5AD7C87CC75BAC36ADC246BCD221BBD9ECF76B06A`
**Source revision:** `6a726413d3d7e56d59636e3f545e462bfab3c7ad`
**Verdict:** **REVISE — do not import this candidate yet.**

## Method and source-open evidence

I read the candidate-facing stems/options before inspecting `correct_id`. My
independent answer for every item was the first listed option; comparison then
showed that every private `correct_id` is indeed option one. That is factual
agreement, but it is also a 24/24 answer-position giveaway.

I directly opened all 20 cited URLs on 2026-10-19. The NIH/NCI pages open and
support the heart, kidney, ovary and testis claims. The 16 OpenStax pages open
and substantiate the cited broad anatomy. Particularly relevant direct text:

- OpenStax 17.3 says the **posterior** pituitary stores and releases ADH and
  oxytocin made in the hypothalamus; its anterior lobe produces hormones.
- OpenStax 23.3 identifies submandibular, sublingual and parotid locations and
  saliva delivery; 23.4 identifies gastric glands in the mucosa and their HCl,
  pepsinogen and mucus-producing cells; 23.5 identifies intestinal glands in
  both small- and large-intestinal mucosa.
- OpenStax 27.2 identifies Bartholin/greater vestibular outlets and says these
  glands secrete mucus to keep the vestibular area moist. The candidate's cited
  27 chapter review does **not** contain `vestibular` or `Bartholin`.
- OpenStax 25.2 identifies the male urethra as passing through the prostate and
  bulbourethral glands as secreting mucus into the urethra.
- OpenStax 17 chapter review supports posterior thyroid parathyroids, adrenal
  position, pineal melatonin, pancreatic endocrine/exocrine roles, and kidney
  secondary endocrine function. NIDDK supports kidney filtering, urine flow and
  hormone functions, though it does not name renin or erythropoietin on this page.

The general descriptions of brain/CNS, skeleton/muscle, respiratory tract,
heart/vessels, lymph nodes/spleen, eyes/ears/lacrimal glands, skin appendages,
digestive and urinary organs, and gonads are factually sound at this scope. The
source problem is assignment/provenance precision, not a claim that the anatomy
is false.

## Required repairs

1. **Randomize every option list.** All 24 `correct_id`s occur at index 0.
   Shuffle options with a deterministic recorded seed or an explicit balanced
   plan, preserving four distinct IDs and the existing correct IDs. Recheck that
   no position pattern is predictable.
2. **Make Q04 and its explanation say “posterior pituitary”** (and add that
   target or clearly state that it is the posterior lobe of the listed pituitary
   gland). “Pituitary” alone is imprecise because the anterior pituitary
   produces its own hormones. The present source explicitly distinguishes the
   lobes.
3. **Repair the source records to match the sources actually relied on.** The
   `source-audit.md` says `openstax-digestive` was checked at 23.6, but
   `candidate.json` points that ID to the 23 chapter review. Do not retain a
   record whose URL differs from the audit evidence. Add/use exact claim-level
   pages as follows:

   | Affected candidate content | Current problem | Concrete repair |
   |---|---|---|
   | `uterus` | It cites `openstax-endocrine`, which supports oxytocin contractions but not the uterine location/muscular anatomy. | Cite OpenStax 27.2 (or another direct reproductive anatomy primary educational page) for position/function; retain endocrine only for the oxytocin fact if wanted. |
   | `gastric_glands`, Q24 | They cite `openstax-digestive`/chapter review, while the audit names 23.4. The chapter review does not establish the microscopic gland statement or the listed secretory products. | Cite 23.4 (`openstax-stomach`) for the organ and Q24. |
   | `intestinal_glands` | It cites `openstax-digestive`; audit says the supporting page is 23.5. The candidate's cited chapter-review page does not establish the stated gland group. | Cite `openstax-intestines` for its function/fact and any question using it. |
   | Q14–Q15 | They cite generic digestive review rather than the existing `openstax-salivary` record. | Cite `openstax-salivary`; its direct text gives all three named gland locations and saliva delivery. |
   | `greater_vestibular`, Q23 | Current `openstax-reproductive` is chapter review. Direct search found no “vestibular”/“Bartholin” on it, so the thick-mucus claim and eponym are unsupported by the recorded source. | Add/cite OpenStax 27.2 for these claims (it explicitly names the glands and their mucus/moisture role). |
   | `thymus` | `openstax-lymphatic` supports its lymphoid role and T-cell maturation but not the unspecific `thymic hormones` secretion. | Either remove that secretion and classify/present it principally as lymphoid tissue, or add a directly opened authoritative source that supports the exact hormones and endocrine classification. |
   | `kidneys` | NIDDK supports hormone functions but does not name the two listed secretions. | Either change `renin; erythropoietin` to a sourced general statement or add a direct source that names both. |

4. Reconcile `source-audit.md` after candidate URLs are fixed. It currently
   reports different pages for digestive content than the candidate's source
   registry, so it is not sufficient provenance for the frozen data.

## Question-by-question verdict

All answers below were selected blind before comparing `correct_id`; all match
the existing intended key. “Fairness repair” applies to every item because the
answer is currently first.

| ID | Blind answer / current key | Verdict | Exact disposition |
|---|---|---|---|
| Q01 | heart / heart | REVISE | Factual/key match; shuffle options. |
| Q02 | pituitary / pituitary | REVISE | Factual/key match; shuffle options. |
| Q03 | pineal / pineal | REVISE | Factual/key match; shuffle options. |
| Q04 | posterior pituitary (mapped to pituitary) / pituitary | REVISE | Name the posterior lobe; then shuffle. |
| Q05 | pancreas / pancreas | REVISE | Factual/key match; shuffle options. |
| Q06 | liver / liver | REVISE | Factual/key match; shuffle options. |
| Q07 | parathyroids / parathyroids | REVISE | Factual/key match; shuffle options. |
| Q08 | thyroid / thyroid | REVISE | Factual/key match; shuffle options. |
| Q09 | adrenals / adrenals | REVISE | Factual/key match; shuffle options. |
| Q10 | kidneys / kidneys | REVISE | Factual/key match; shuffle options. |
| Q11 | ureters / ureters | REVISE | Factual/key match; shuffle options. |
| Q12 | bladder / bladder | REVISE | Factual/key match; shuffle options. |
| Q13 | urethra / urethra | REVISE | Factual/key match; shuffle options. |
| Q14 | parotid / parotid | REVISE | Correct but assign `openstax-salivary`; shuffle options. |
| Q15 | sublingual / sublingual | REVISE | Correct but assign `openstax-salivary`; shuffle options. |
| Q16 | lacrimal / lacrimal | REVISE | Factual/key match; shuffle options. |
| Q17 | eccrine sweat / eccrine sweat | REVISE | Factual/key match; shuffle options. |
| Q18 | sebaceous / sebaceous | REVISE | Factual/key match; shuffle options. |
| Q19 | ovaries / ovaries | REVISE | Factual/key match; shuffle options. |
| Q20 | testes / testes | REVISE | Factual/key match; shuffle options. |
| Q21 | seminal vesicles / seminal vesicles | REVISE | Factual/key match; shuffle options. |
| Q22 | bulbourethral / bulbourethral | REVISE | Factual/key match; shuffle options. |
| Q23 | greater vestibular / greater vestibular | REVISE | Repair source as above; shuffle options. |
| Q24 | gastric glands / gastric glands | REVISE | Repair source as above; shuffle options. |

## Taxonomy and scope checks

- The required mixed roles are correctly represented for pancreas, ovaries and
  testes. The urinary/reproductive dual role of male urethra is also correct.
- CNS, urinary, lymphatic and reproductive labels now appear anatomically
  appropriate in the reviewed structures; I found no recurrence of the earlier
  CNS-to-urinary or lymphatic-to-reproductive system-ID swap.
- Paired/distributed labels (`eyes`, `ears`, `blood_vessels`, gland groups) are
  acceptable as pedagogical selectable groups, provided the UI makes that scope
  explicit. The source audit already identifies this as a presentation choice.
- Sex-specific facts are consistently qualified: male urethra/prostate and male
  accessory glands are marked “in males”; ovaries, uterus, vagina and greater
  vestibular glands are presented as female reproductive anatomy. No claim is
  made that these structures occur in every body.
- Posterior-pituitary production/release and adult calcium-regulation cautions
  are materially correct, subject to the Q04 precision repair above.

## Acceptance condition for recheck

Return a new candidate hash after (a) option-position repair, (b) Q04 posterior
pituitary precision, and (c) the source-ID/URL corrections above. I will then
recheck the changed questions, every changed source assignment and the revised
hash. This report is a factual-review result only; it is not canonical-import,
asset-rights, UI, or publication acceptance.

---

## Final recheck — repaired candidate

**Candidate SHA-256:** `A59C98CC0ADDF036268941303D6FD741C1531E65B263C469B099BB299B520AA9`
**Final factual verdict:** **ACCEPT for the reviewed candidate facts, cited
source assignment, question keys, and option fairness.**

I rechecked the repaired records rather than relying on the repair report:

- `openstax-digestive` now points to direct OpenStax 23.6, which explicitly
  supports liver bile production, gallbladder bile storage/concentration, and
  pancreatic digestive roles. I opened that current URL during this recheck.
- `uterus` and `greater_vestibular`/Q23 now cite direct OpenStax 27.2. That
  source names Bartholin/greater vestibular glands and their mucus/moisture role;
  the uterus is no longer attributed to the pituitary page.
- `gastric_glands`/Q24 use 23.4, `intestinal_glands` uses 23.5, and Q14–Q15
  use 23.3. Those are the direct pages previously opened for the exact claims.
- Q04 now explicitly identifies the posterior pituitary, while retaining the
  selectable `pituitary` atlas target. Its wording and explanation correctly
  distinguish hypothalamic production from posterior-pituitary storage/release.
- The unsupported thymic secretion is removed and thymus is an organ with its
  supported lymphoid/T-cell-maturation role. Kidney secretion names are removed;
  its general endocrine-system role remains backed by NIDDK/OpenStax.

Fresh structural check of `candidate.json`: 21 source records, 52 organs, 24
questions; zero unresolved organ, fact, or question source IDs; every question
has four distinct options and contains its `correct_id`. The source count is now
21 because the exact 27.2 female-reproductive source was added to make the
uterus/greater-vestibular evidence traceable; it replaces no factual claim with
an unsupported shortcut.

Correct-answer positions are exactly `2,0,3,1,1,3,0,2,0,2,1,3,3,1,2,0,1,0,3,2,2,3,0,1`:
six at each of indexes 0–3. The affected question keys remain factually correct.

This acceptance does not approve canonical import, asset rights, UI behavior,
builds, or publication. Those gates remain outside this factual review.

---

## Byte-normalization recheck

**Normalized candidate/canonical SHA-256:**
`8F70FDF80309EEC92CE47F4234D0F235750B1B459816AB1EB5E704F13BFD827B`

**Verdict:** **ACCEPT — byte normalization only; the preceding factual
acceptance remains applicable.**

I compared the current LF-normalized
`docs/rewrite-agents/tasks/ANATOMY_53DF/candidate.json` and
`next/apps/quiz_app/assets/quizipedia/organ_atlas.json` as raw byte arrays.
They are byte-identical, both have no CR bytes, and each has 2,278 LF bytes.
Reconstructing CRLF from the normalized candidate by replacing every LF with
CRLF produces SHA-256
`A59C98CC0ADDF036268941303D6FD741C1531E65B263C469B099BB299B520AA9`,
the previously factually accepted candidate. Normalizing that reconstruction
back to LF produces the same text. No JSON field, source mapping, question,
key, or factual claim was changed by this normalization.
