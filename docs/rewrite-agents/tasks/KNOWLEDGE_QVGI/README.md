# Knowledge atlas

The local `knowledge_atlas.json` is a bilingual starter corpus for unranked
learning: 44 world-history entries, 30 works and 39 linked people. History is
sorted chronologically and grouped by period. A record can mark its date as
approximate or as a range; the interface says so and its practice prompt asks
“about when”, rather than presenting an invented exact date.

Works include books, films, opera, oratorio, ballet, plays and music. Each
work records creator IDs and optional actor-role credits. Every credit is
reciprocal: a person lists every included work, and the parser rejects an
orphaned relation. Local generated practice covers dates, order, creator and
actor-role questions. Order rounds reject a group with tied dates; all answers
have distinct choices.

Each record has a clickable institutional or collection source. This corpus
contains concise original summaries and facts, not copied articles. The
independent fact review is in `fact-review.md`; its source repairs and taxonomy
corrections were incorporated before integration. Remaining scope is explicit:
this is a curated learning spine, not a complete history or film database.

Validation:

```powershell
cd next/apps/quiz_app
flutter test test/knowledge_atlas_test.dart
flutter analyze lib/knowledge_atlas.dart test/knowledge_atlas_test.dart
```
