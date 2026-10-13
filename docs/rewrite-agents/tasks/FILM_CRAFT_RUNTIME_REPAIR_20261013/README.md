# Film Craft runtime repair — 2026-10-13

This repair moves the accepted editorial tags into the raw Film Craft source and regenerates the canonical draft, manifest and bundle through `quizctl ImportWithTaxonomy` and `quizctl build`.

On this Windows checkout, `ImportWithTaxonomy` retains the local input spelling in each `source.uri`; production imports the same raw file from `/app/quizzes/Preparation/film_craft_20261013.json`. `normalize_runtime_uri.py` makes that single path-only substitution, rejects a source object other than URI-only, and recomputes the contract revisions with the canonical JSON algorithm before the final `quizctl build`. It neither adds a source title nor changes questions, grading, difficulty, explanations or article prose.

Reproduce the final checks from the repository root:

```powershell
python docs/rewrite-agents/tasks/FILM_CRAFT_RUNTIME_REPAIR_20261013/normalize_runtime_uri.py
go run -p=1 ./next/server/cmd/quizctl validate --in next/content/film-craft-20261013/draft.json --taxonomy metadata/tags.v1.json
go run -p=1 ./next/server/cmd/quizctl validate --in next/content/film-craft-20261013/bundle.json --taxonomy metadata/tags.v1.json
go run -p=1 ./next/server/cmd/quizctl build --in next/content/film-craft-20261013/draft.json --out docs/rewrite-agents/tasks/FILM_CRAFT_RUNTIME_REPAIR_20261013/rebuilt-final.json --version 2026.10.13.film-craft-v1 --published-at 2026-10-13T15:56:06Z --taxonomy metadata/tags.v1.json
go run -p=1 ./next/server/cmd/quizctl diff --before next/content/film-craft-20261013/bundle.json --after docs/rewrite-agents/tasks/FILM_CRAFT_RUNTIME_REPAIR_20261013/rebuilt-final.json
```

`repair-evidence.json` has the exact output hashes, new revision bindings, private/public identity proof and before/after Reader nonbinding hashes.

This is implementation evidence only. Runtime-container import, independent review, Flutter rebuild, and publication remain the release owner's gates.