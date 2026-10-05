# Initial independent design review — root relay

Reviewer: /root/difficulty_review (qm_reviewer); hub READY #702. Verdict REWORK. This is the root's faithful summary of actual returned findings, not a fabricated reviewer-owned file or implementation acceptance.

- Freeze exact optional numeric difficulty_level and four bands, retain compatibility for old canonical archives without the number.
- Unify naming: editorial_tag_ids private, context_tag_ids public only with affirmative visible-context support.
- Add dictionary identity/hash and player_safe gate; reject unknown/duplicate tags.
- Replace ambiguous collection members with explicit all/any/excluded predicates. Italy must not include all world cheese; rice must not include all Italian/Japanese cuisine. Root clarifies rice spans cultures without any intended cuisine exclusion.
- Include six published Study modules (120 questions), giving 4078 total, but preserve their local unranked projection and exclude Wave3/new ranked mixed routes.
- Filter full immutable pack before 20-question rounds; preserve absent-filter request/URL behavior.
- Editorial estimates must not be described as measured player difficulty.

These corrections are incorporated in CONTRACT.md and metadata/tags.v1.json. A recheck and actual implementation review are still required.
