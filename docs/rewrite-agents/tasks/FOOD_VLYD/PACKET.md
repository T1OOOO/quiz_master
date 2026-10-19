# FOOD_VLYD frozen packet

User: famous dishes, classic ingredients, recipe, facts, origins and regional branches.

Schema qm-food-atlas/v1; asset assets/quizipedia/food_atlas.json.
Top: schema_version, coverage_note_ru/en, sources[], dishes[].
Source: id,title,url (HTTPS),checked_on YYYY-MM-DD.
Dish: id,name_ru/en,category_ru/en,country_ru/en,region_ru/en,
summary_ru/en,classic_note_ru/en,origin_ru/en,servings_ru/en,
ingredients:[{name_ru/en,amount_ru/en}],steps:[{text_ru/en}],
facts:[{text_ru/en,source_ids:[id]}],
variants:[{name_ru/en,region_ru/en,difference_ru/en,source_ids:[id]}],
source_ids:[id]. All named text nonempty. ingredients >=3; steps >=3; facts >=1;
variants >=1. Dish source_ids support recipe, origin and version (additional sources
allowed). Regional tradition rather than invented exact origin when disputed.
Explicitly name the reference version (institutional, regional or chef tradition).
No universal sole authentic claims, no optional modern ingredients mixed into base.
Quantities + yield must be practical; instructions include cooking cues/time/temp
when needed. Original concise paraphrases, no copied recipes. Aim 20-24 excellent
well-sourced dishes from varied cuisines rather than unsourced breadth.

Flutter API FoodAtlasPage({Key? key, AssetBundle? bundle}); parser FoodAtlas.fromJson.
Separate models/parser/question generator into food_atlas_models.dart; UI food_atlas.dart.
Search name/ingredient/region/variant, category filter, ascending/descending name sort;
source-linked detail with ingredients, numbered recipe, origin, facts, regional variants.
RU/EN follow existing local atlas conventions; no dependency or l10n manifest edits.
Local unranked training: 10-question frozen rounds, 4 unique choices, check then
feedback+sources, score, restart, finite mistakes review. Topics origin and composition;
origin prompt explicitly refers to association in this reference version, not invented
birthplace; composition prompt shows full named classic ingredients, asks dish.
Avoid duplicated ingredient signatures/ambiguous options; each correct ID exactly once.
Do not quiz on folklore dates or unsupported variants; facts visible for learning.
Loading/error-retry/empty, scrolling mobile text scaling, stable selection across filters.

Ownership: food_writer candidate+source-audit only. food_ui new Dart files and its
fixture test only. Root menu, navigation tests, final asset import/data tests and git.
Reviewers reports only. Shared checkout: do not revert/stash/stage others. No commits
by workers. No children. Direct finite work authorized by project resource override.
Write tests before behavior and capture red/green. Root alone runs full suite/build/browser.

## Editorial amendment, 2026-10-19

The draft's 20–24 breadth target was an internal aim, not a user requirement.
Independent recipe review rejected unsupported quantities and broad tourism
citations. Initial release is now 10–14 complete sourced classic references;
currently 11 dishes from eight countries. Keep rejected research drafts out of
shipped assets. No padding via almost-identical dishes.

`variants` may be an empty array: inventing a branch to satisfy a minimum is
misleading. Show genuinely sourced variants and related dishes, qualify the
relationship, and omit the section when none is verified. Recipe/origin/fact
and bilingual validation requirements remain. Check four unique answers in
both languages and validate region-label translations before training.
