# Editorial difficulty rubric v1

Audience: Russian-speaking adult general-knowledge quiz player, without assumed professional training or exhaustive franchise expertise. Applies across every topic. Ratings describe the existing wording/options, not the length of the question or the pack title. They are estimates, not measured response probabilities.

| Score | Anchor |
|---|---|
|1|Nearly universal everyday recognition; options make the choice straightforward.|
|2|Very familiar school/pop-culture fact, one simple recall step.|
|3|Common general-knowledge recall with plausible alternatives.|
|4|Standard school knowledge or familiar cultural detail requiring focused recall.|
|5|Moderately specialised amateur knowledge, less prominent fact or comparison.|
|6|Specific episode, terminology or regional detail a prepared amateur may know.|
|7|Specialist/fan knowledge, uncommon detail and genuinely plausible alternatives.|
|8|Fine distinctions, obscure details, or several connected facts to resolve.|
|9|Very rare specialist detail, difficult even for well-prepared enthusiasts.|
|10|Exceptional niche detail or demanding synthesis; require explicit justification.|

Bands: Easy1–3, Medium4–6, Hard7–8, Nightmare9–10. Do not force equal counts or create Nightmare questions to fill a quota. Keep score10 rare; ambiguous/wrong questions are editorial concerns, not automatically difficult ones. Obvious elimination or stem clues can lower estimated difficulty; flag them instead of silently rewriting answers.

Every annotation must inspect the stem and all alternatives, select vocabulary IDs already frozen, and keep a short private rationale and confidence. Preserve original question bytes semantically except authorised difficulty/tags/metadata fields. Shared public-safe tags describe the visible context. Editorial subject tags may additionally describe the answer/topic connection but must not appear in player payloads where they disclose the keyed choice.

Measurement reference: UT Testing and Evaluation Services, https://testingservices.utexas.edu/scanning/interpreting-test-results (opened2026-10-05), defines observed difficulty through the proportion of correct answers and notes effects of the tested group and alternatives. This proposal uses editorial estimates because a representative response sample is not available. Prior release-verification accounts/answers must not be mistaken for genuine player calibration data. ETS https://www.ets.org/research/policy_research_reports/publications/report/1950/hnuo.html (opened2026-10-05) discusses option/guessing effects; no conversion of our scores into claimed success probabilities.

Tag reference: W3C SKOS Primer https://www.w3.org/TR/skos-primer/ and Reference https://www.w3.org/TR/skos-reference/ (opened2026-10-05). Reuse the modest design principles of stable concept identifiers, preferred multilingual labels, aliases and broader concepts in plain JSON; do not add RDF/ontology infrastructure.
