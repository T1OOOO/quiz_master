# Editorial question metadata

The predefined vocabulary is `tags.v1.json`. Every concept has a stable ID, Russian/English label and aliases, a facet, optional parents and a public-context safety flag. Countries reuse the existing 195-country preparation registry. A tag is attached only when the actual question is about that subject; distractor mentions do not create tags.

Scores are editorial estimates for adult Russian-speaking general quiz players. Easy = 1–3, Medium = 4–6, Hard = 7–8, Nightmare = 9–10. They are not measured correct-answer percentages. Per-question rationale, confidence and flags are retained privately.

Country, place, ingredient, cuisine and person tags remain editorial-only because they may identify a correct answer. Public context tags additionally require visible stem/media or announced quiz-context support. The private index is never copied into Flutter assets or a public API response.

After validated annotation, `question-index.v1.json` includes every published quiz and the six accepted Study modules. Study remains local unranked self-check and is not an API attempt provider. Search supports cross-theme all/any/excluded tags, text including labels/aliases, and exact difficulty ranges:

```powershell
python metadata/quiz_metadata.py search --all ingredient:rice --min 2 --max 6 --ids-only
python metadata/quiz_metadata.py search --any country:it --any cuisine:italian --band medium
python metadata/quiz_metadata.py search --text "Италия" --output .run/italy-selection.json
```

Exported IDs include provider and pack ID so a future collection cannot confuse Study and ranked quiz questions. Current play filters difficulty inside one quiz; creating ranked mixed-pack collections requires a separate immutable composite bundle implementation.

Private annotation artifacts use a `records` array with the exact fields defined in the task CONTRACT.md. `check` supports a partial pilot; `apply` and `build` require full coverage and unchanged semantic source hashes. Source application edits only authorized difficulty/tags/taxonomy fields and verifies every original stem, option, answer, explanation and other non-metadata field.
