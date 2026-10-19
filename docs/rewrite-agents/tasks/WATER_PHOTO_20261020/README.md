# Water and photograph follow-up, 2026-10-20

Source work: actual Natural Earth1:110m water polygons/lines,63 names in Russian, lazy water layer and isolatedretry, searchable picker, local6-choice checked/manual-next map practice. Camera remains manual; explicit focus handles split and polar objects. Existing country-water relationship practice stays available.

Photos were expanded6→36 in release73. This patch keeps all36 original image bytes and old6 catalog rows, adds Russian/English country display names to the newer30 rows (Singapore is absent from map geometry), and bundles36small previews151158bytes. Original photographs remain the detail/practice source.

Verification:302Fluttertests, analyzerclean; source reviewer Google ACCEPT; controller/storageplan Google ACCEPT. Widget tests exercise320×568,1.5text,280keyboard inset; browser361×738 verifies real preview request, Singapore and Baikal. No physical Android device attached. Full release image/public acceptance is a separate gate; not yet published at this source checkpoint.

Source generation: obtain the3 GeoJSONs named in water-source-manifest.json from the primary repository, then run next/apps/quiz_app/tool/build_waterways.py SOURCE_DIRECTORY. The generator rejects source hashes differing from the reviewed snapshot. Preview provenance records exact original and generated hashes; originals unchanged.

Storage archive only7 literal redundant release73 stage copies,287253881bytes. Runtimeimages/livePVC/allserverbackups/metadata/receipts/chart/support retained. Local archive is restricted and ignored by Git. Use absolute paths for storage helper arguments (SQLite file URI validation requires them). Independent plan SHA74c1ffc4e530c8d01ac59f6ac9c973738417adb943cdcade55d6a5f27b2d080f. Pending final public acceptance and report status updates; no user report marked resolved here.
