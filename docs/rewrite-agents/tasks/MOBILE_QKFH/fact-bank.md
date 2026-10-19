# MOBILE_QKFH fact bank

`fact_practice_models.dart` reads only existing Quizipedia JSON assets. It
creates no new asset claims: each `StudyFact` retains an entity ID, localized
card value, field path, and an existing HTTPS source. The sole separately
qualified BackRub record uses the existing Google source reference and the
independent review's permitted wording: it is a pre-Google research project,
not a former legal company name. The disabled `former_names` entry remains
excluded, including its 1996/1997 years.

The loader currently emits 12,146 facts across the frozen scopes:

| Scope | Facts |
|---|---:|
| countries | 7,015 |
| sky | 2,988 |
| endocrine | 6 |
| landmarks | 18 |
| music | 285 |
| organs | 361 |
| greek | 184 |
| religions | 72 |
| food | 247 |
| brands | 619 |
| history | 88 |
| works | 103 |
| people | 160 |

Country coverage includes actual `country_facts.neighbors` relationships,
separate source and official languages, currencies, population with its
visible year context, region/subregion, religion shares qualified with group
and dataset year, typed links/culture/waters, and current office holders.
`country_links` kinds are named as resources, deserts, landmarks, bridges,
scientists, foods, or teams as supplied; they are never labelled neighbours.
Source checked dates are metadata and do not become questions.

Nested fact labels carry the item needed for a fair prompt: star metrics name
the star; ingredient amounts name the ingredient; variant fields name the
variant; former-name notes and dates name the historical name; logo narratives
include their entry year; belief-edge context names the relation; country link,
culture, and water relations name the linked item; and cast roles name the actor. Brand `owner_id` is resolved through the existing owners
list; work cast and person credit IDs resolve through the existing people and
works lists. BCE and approximate dates are localized instead of exposing raw
negative integers. Russian source captions use known localized captions or a
publisher/category caption, never a raw internal source ID.

`buildFactQuestions` emits one question per record. The fact ID is the only
correct choice ID. It normalizes whitespace, non-breaking spaces, case, and
Russian `ё/е`; excludes every value belonging to the target entity; and uses
two to four distinct choices. Distractors first use a typed family that strips
indices and entity IDs while preserving the leaf/kind (including link kind),
then only a same-scope compatible value kind. Relation values are their own
compatible kind, so they never fall back to capitals, currencies, or other
labels. It never uses the former broad scope fallback. Dates, numbers,
percentages, amounts, prose, and labels stay separate. A missing localized value, missing/non-HTTPS source, or fewer than
two fair choices throws rather than silently omitting a record.

Focused verification:

- The new reviewed-regression test was RED before the repair because no true
  neighbour records existed; it then passed after extraction changed.
- `flutter test test/fact_practice_models_test.dart --reporter compact` passed
  **4/4**. It covers all frozen scopes, 95 music entries, 52 organ structures,
  food steps/ingredients/facts, actual neighbours, typed link labels, nested
  qualifications (including item-qualified relation prompts and relation-only
  options), disabled former-name handling plus qualified BackRub,
  resolved owner/cast/credit data, no raw-negative history date, source-caption
  ID leakage, canonical correct IDs, fair alternatives, target-entity
  exclusion, and deterministic order.
- `dart analyze lib/fact_practice_models.dart test/fact_practice_models_test.dart`
  reported **No issues found**.

This is focused data-contract evidence. It does not claim an independent
review, full application test, build, release, or publication.