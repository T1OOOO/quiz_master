# Public question revision snapshots

`gastronomy-traditions-and-etiquette.json` was captured read-only on 2026-10-06
from https://quiz.kotopedia.org/v1/catalog?quiz_id=gastronomy-traditions-and-etiquette.
It contains the public question DTOs and exact question revisions, not grading keys.
Use it to bind articles to the actual published question IDs/revisions when there
is no tracked canonical bundle for a legacy pack. The reader requires exact revision
matches; an older article is not automatically attached to a newer question.

Known wording risks requiring separate question review before article acceptance:
Ushuaia described as the world's southernmost city, an undated largest restaurant
chain claim, overly broad origin claims for sushi/ketchup, and generalizations about
national etiquette. Do not manufacture article facts to justify an existing key.


The 2026-10-11 repair also captured lotr, prep-ballet, prep-musicals, `theme-harry-potter`, and `theme-terminator` from their public catalog endpoints. These exact served DTOs take precedence over legacy canonical bundles when resolving non-Study question references; canonical bundles remain the fallback when no snapshot is tracked.
