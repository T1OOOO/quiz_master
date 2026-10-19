# ANATOMY_53DF frozen contract

User asks high-quality interactive human organs map with all glands and facts.
Expand Quizipedia beyond existing six-target endocrine exercise. Root retains old
exercise through a clearly named legacy training entry; new main anatomy entry.

Asset assets/quizipedia/organ_atlas.json schema qm-organ-atlas/v1:
coverage_note_ru/en strings; sources[{id,title,url HTTPS,checked_on YYYY-MM-DD}];
organs[{id,name_ru/en,system_ids:[id],kind,region,position_ru/en,
 function_ru/en,secretions_ru/en:[strings],facts:[{text_ru/en,source_ids:[ids]}],
 note_ru/en strings (may empty),source_ids:[ids]}];
questions[{id,topic,stem_ru/en,option_ids:[four distinct organ IDs],correct_id,
 explanation_ru/en,source_ids:[ids]}]. topic=function|secretion|location|fact.
All non-note texts nonempty, lists immutable in parser; secretions may empty.
Nonempty source refs resolve; source dates real calendar, URLs nonempty host.
Organs can belong multiple systems; pancreas/ovaries/testes not falsely single-role.
kind=organ|endocrine_gland|exocrine_gland|mixed_gland|gland_group|endocrine_tissue.
region=head|neck|thorax|abdomen|pelvis|distributed.
system_ids from nervous,endocrine,digestive,respiratory,cardiovascular,urinary,
reproductive,lymphatic,integumentary,sensory,musculoskeletal.

Content target ~45-55 substantive structures, all major named endocrine glands
(hypothalamus, pituitary, pineal, thyroid, parathyroids, adrenals, pancreas, ovaries,
testes), thymus; exocrine parotid/submandibular/sublingual/lacrimal, sweat eccrine
and apocrine, sebaceous, mammary, prostate, seminal vesicles, bulbourethral,
greater vestibular, gastric and intestinal gland groups; liver/bile and mixed
pancreas explicit. Major brain/heart/lungs/airways/stomach/intestines/kidneys/
bladder/spleen/uterus/skin/eyes etc. Real primary educational/medical sources,
concise original RU/EN text, 1-2 facts each, no copied textbook chapters, per-source
word limits honored (open sources to see license). Don't claim every microscopic
gland or a definitive total number of organs. Placenta if included transient,
thyroid calcitonin not main adult calcium regulator, posterior pituitary releases
hypothalamic hormones. No clinical advice. 24+ fair source-backed authored
four-organ-choice questions across topic types and glands/other organs.

UI API OrganAtlasPage({super.key, AssetBundle? bundle, bool training=false}).
New organ_atlas.dart / organ_atlas_models.dart / organ_atlas_test.dart; no manifest
or l10n edits (owned elsewhere). RU/EN follows current atlas conventions.
Actual body schematic with recognisable organ silhouettes / regional structures,
explicit anterior patient-left/right orientation and approximate layered schematic
caption; region/system/kind filters and searchable accessible list, selected detail
functions/location/secretions/facts/source links. Paired glands and depth are
schematic, not precise diagnostic pixels. Declutter small glands via regional
callouts/insets or clear selected-system layers; do not make overlapping untappable
circles the only UI. All targets accessible through44px list. Body regions derived
from reviewed region IDs; no guessed exact anatomical coordinates as facts.
Mobile pan/pinch/+/-/fit/reset; selecting organ never changes camera. Theme colors
must be legible in dark/light. Handle text1.6x, narrow360, loading/retry/empty/back.
Local unranked frozen up-to10-question rounds clearly counted; filtered practice
uses correct organ in selection with all distractors shown, no misleading topic
filters. Stable IDs, Check-feedback+source-Next, score, restart/finite mistakes
review preserving original result. Test parser malformed cases + real asset
integration + camera/mobile/quiz paths. Test first; focused tests only per worker.

Ownership: anatomy_data only candidate.json + source-audit.md in this taskfolder;
no canonical import before independent factual review. anatomy_ui only new two
Dart files + own test + ui-notes.md. Root owns quizipedia.dart/navigation tests,
asset import, root verification, builds/browser/git. No dependency/codegen changes.
You are not alone; preserve others' edits. No worker commit/stage/spawn. Root+2
active workers maximum. Resourcequeue waits removed by project override; no
production deploy/main merge authorized. Known Claude OAuth expired, no repeated
retries or false different-provider acceptance. Prior research exists in docs/
rewrite-agents/tasks/QUESTION_ARTICLES_20261006/ANATOMY* (facts useful, asset
rights/hotspots were NOT accepted). Reuse as leads, verify original sources.
