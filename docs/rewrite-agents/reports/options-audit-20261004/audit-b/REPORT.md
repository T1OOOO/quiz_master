# Options audit B — keyed review

Date: 2026-10-04. Scope: frozen `.run/option-audit-20261004/batch-b.blind.json` (468 candidate rows).

## Coverage and method

- Reviewed: 468; unreviewed: 0; keyed rows: 468.
- This was a compact pattern-based wording audit, not factual validation. Each row was inspected structurally; the first flagged parenthetical option (or longest length-outlier option) was recorded as `signal_index`. Parentheticals matching translations, aliases, alternate names, units, or version labels were treated as necessary qualifiers. Parentheticals with explanatory plot/fact detail were treated as cues; mixed cases were uncertain. Long options without explanatory text were not called cues solely for length.
- Blind verdict counts: {'cue': 62, 'necessary_qualifier': 356, 'uncertain': 21, 'balanced': 29}. Signal matched a keyed correct index in 360/468 rows. Keyed confirmed cues: 59. Priority counts: {'high': 59, 'low': 385, 'medium': 24}.

## Common patterns

Most flagged rows use parentheticals for translations, original-language names, alternate titles, or disambiguating versions; these are usually useful qualifiers. The stronger risk pattern is a correct option that appends a causal, plot-specific, or explanatory clause while distractors remain short. Length outliers without explanatory content remain uncertain rather than automatic edits.

## Strong examples for root adjudication

- `ranked/home-alone-1-part-1/q_ha1_p1_8` — confirmed cue at option 0: Скобки добавляют объяснение или сюжетную деталь, делая вариант заметно авторитетнее. Proposed: Сократить до краткого ответа; пояснение вынести в explanation.
- `ranked/home-alone-1-part-1/q_ha1_p1_17` — confirmed cue at option 2: Длинный вариант содержит существенно больше утверждений, чем отвлекающие ответы. Proposed: Сократить вариант до проверяемого ответа.
- `ranked/home-alone-1-part-2/q_ha1_p2_7` — confirmed cue at option 1: Длинный вариант содержит существенно больше утверждений, чем отвлекающие ответы. Proposed: Сократить вариант до проверяемого ответа.
- `ranked/home-alone-1-part-2/q_ha1_p2_12` — confirmed cue at option 2: Скобки добавляют объяснение или сюжетную деталь, делая вариант заметно авторитетнее. Proposed: Сократить до краткого ответа; пояснение вынести в explanation.
- `ranked/home-alone-1-part-4/q_ha1_p4_16` — confirmed cue at option 0: Длинный вариант содержит существенно больше утверждений, чем отвлекающие ответы. Proposed: Сократить вариант до проверяемого ответа.
- `ranked/home-alone-1-part-4/q_ha1_p4_23` — confirmed cue at option 0: Скобки добавляют объяснение или сюжетную деталь, делая вариант заметно авторитетнее. Proposed: Сократить до краткого ответа; пояснение вынести в explanation.
- `ranked/home-alone-1-part-5/q_ha1_p5_18` — confirmed cue at option 0: Скобки добавляют объяснение или сюжетную деталь, делая вариант заметно авторитетнее. Proposed: Сократить до краткого ответа; пояснение вынести в explanation.
- `ranked/home-alone-2-part-2/q_ha2_p2_6` — confirmed cue at option 0: Длинный вариант содержит существенно больше утверждений, чем отвлекающие ответы. Proposed: Сократить вариант до проверяемого ответа.
- `ranked/home-alone-2-part-3/q_ha2_p3_6` — confirmed cue at option 0: Длинный вариант содержит существенно больше утверждений, чем отвлекающие ответы. Proposed: Сократить вариант до проверяемого ответа.
- `ranked/lotr-two-towers-lore-100/lotr_tt_46` — confirmed cue at option 0: Скобки добавляют объяснение или сюжетную деталь, делая вариант заметно авторитетнее. Proposed: Сократить до краткого ответа; пояснение вынести в explanation.
- `ranked/lotr-two-towers-lore-100/lotr_tt_75` — confirmed cue at option 0: Скобки добавляют объяснение или сюжетную деталь, делая вариант заметно авторитетнее. Proposed: Сократить до краткого ответа; пояснение вынести в explanation.
- `ranked/tf-animation-series/51ffb6df-1ba8-47ef-b553-a9d9089f59f1` — confirmed cue at option 0: Длинный вариант содержит существенно больше утверждений, чем отвлекающие ответы. Proposed: Сократить вариант до проверяемого ответа.

## False positives and limits

Parenthetical translations and aliases can look conspicuous but often preserve answer integrity, especially for fictional proper names and technical terms. A keyed match only says the flagged option is intended correct; it does not establish factual correctness or prove a player would exploit the wording. The first-flagged-option rule can miss additional signals in the same row, and this pass does not replace root's independent semantic adjudication. Do not automatically delete necessary qualifiers.

## Proposals

Root should manually inspect high-priority confirmed cues and any mixed/uncertain rows. Where explanation is pedagogically useful, move it to the explanation field or rebalance distractor specificity; preserve translations, aliases, units, and required version qualifiers when they prevent ambiguity.

## Manual semantic sample (separate evidence)

The 468-row result above is **structural coverage only**. It used the frozen candidate flags and compact pattern treatment; it does not claim that all 468 stems and options received semantic editorial inspection.

A separate 42-question sample was then inspected item by item, including every stem and every option, before opening the private cross-key. Blind evidence is in `manual.blind.json`; keyed evidence is in `manual.review.json`.

- Manual coverage: 42 reviewed, 0 unreviewed.
- Manual verdicts: cue 33, necessary qualifier 4, balanced 5, uncertain 0.
- Keyed confirmed cues: 32.
- Manual method: direct reading of complete questions and options in manageable chunks. Judgments cite a short option phrase and explain why peer options weaken or identify the answer. Checks included absurd distractors, one-option translations, parallel grammar, exact-quote ambiguity, and long proper names versus explanatory clauses.

Representative manual findings include `study-nature/study-nature-001` (the correct option bundles population, generations, heredity, and advantage, making a definition-like cue), `ranked/home-alone-1-part-2/q_ha1_p2_10` (editorial “Нет, просто birdseed” inside an option), and `study-history/study-history-008` (balanced condition/trigger alternatives retained). The manual sample is still an editorial audit, not factual validation; root should independently adjudicate the 42 findings and must not generalize their counts to the remaining 3,956 rows.
