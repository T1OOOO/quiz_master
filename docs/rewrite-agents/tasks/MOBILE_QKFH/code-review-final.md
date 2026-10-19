# Final Independent Follow-Up Review — `MOBILE_QKFH`

- **Verdict**: **ACCEPT**
- **Current Blockers**: **None**

## Verified Repairs & Evidence

1. **Qualified relation prompts, distinct child `entityId`, and `.relation`-only distractors**:
   - [`fact_practice_models.dart` lines 336–350](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L336-L350): `.relation` records use child-scoped `entityId` `'${countryEntry.key}:${asset.$1}:${itemKind.isEmpty ? 'item' : itemKind}:$itemId'`, preventing over-exclusion of sibling relations on the same country.
   - [`fact_practice_models.dart` lines 1592–1608](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L1592-L1608): `_relationFieldRu` and `_relationFieldEn` include the specific item name (`'Связь: «$name»'`, `'Культурная связь: $name'`, `'Связь с водоёмом: $name'` / `'Relation: “$name”'`, `'Cultural connection: $name'`, `'Water relation: $name'`) without leaking the answer's link `kind` in the prompt.
   - [`fact_practice_models.dart` line 1408](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L1408): `_valueKind` assigns `leaf == 'relation'` to `'relation'`, isolating relation distractors from `'label'` fields (capitals, currencies, languages).
   - [`test/fact_practice_models_test.dart` lines 179–200](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/fact_practice_models_test.dart#L179-L200): Regression test verifies non-empty `.relation` facts, `:` qualification in both locales, unique `entityId`s across all relation facts, and that every `FactChoice` on every `.relation` `FactQuestion` originates from a `.relation` `StudyFact`.
2. **`historical_project` distractor family & Russian localization**:
   - [`fact_practice_models.dart` line 1380](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L1380) and [line 1406](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L1406): `_family('historical_project')` maps to `'former_names.name'` and `_valueKind` maps it to `'historical_name'`, keeping its distractors strictly within historical names while preserving `valueRu: 'БэкРаб'`, `valueEn: 'BackRub'` ([lines 968–982](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L968-L982)) and excluding the disabled `former_names` entry and its years ([line 933](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L933), tested at [`test/fact_practice_models_test.dart` lines 217–228](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/fact_practice_models_test.dart#L217-L228)).
3. **`people.born` dataset extraction**:
   - [`fact_practice_models.dart` lines 1168–1179](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/fact_practice_models.dart#L1168-L1179) and [`test/fact_practice_models_test.dart` lines 241–246](file:///E:/Projects/quiz_master/next/apps/quiz_app/test/fact_practice_models_test.dart#L241-L246): Verified non-empty across the current `people` dataset.

## Limits
- Read-only review of the specified files only; no tests, analyzer runs, builds, or shell commands were executed by this reviewer.
