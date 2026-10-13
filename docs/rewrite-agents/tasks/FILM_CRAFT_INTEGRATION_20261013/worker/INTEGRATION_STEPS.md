# Film Craft preparation handoff

`prepare_film_craft.py` is a staging controller. It is deliberately unable to
write canonical content, Flutter assets, manifests, or Reader runtime data.
It accepts only a new directory below
`.run/film_craft_integration_20261013/worker/` and refuses an existing target.

Run from `C:\ap\quiz_master`:

```powershell
python docs\rewrite-agents\tasks\FILM_CRAFT_INTEGRATION_20261013\worker\prepare_film_craft.py --self-test
python docs\rewrite-agents\tasks\FILM_CRAFT_INTEGRATION_20261013\worker\prepare_film_craft.py --output-dir .run\film_craft_integration_20261013\worker\staging-v1
```

The controller pins the accepted source files by SHA-256, preserves all four
candidate stems, options, answer mappings and source articles, and produces:

- `legacy.json`: isolated legacy-format source used only by the current
  `quizctl import` migration path.
- `canonical/draft.json`: private `quiz-contract/v1` source for the separate
  `film-craft-20261013` Preparation mini quiz.
- `canonical/bundle.json`: `quizctl`-built staged bundle. Its private grading is present
  only under `private_grading`; public quiz records contain no grading field.
- `reader-draft.json`: four source-backed Reader articles at `draft` status,
  each tied to the staged immutable question revision.
- `provenance.json` and `validation.json`: frozen source hashes, mappings,
  command results and artifact hashes.

The package is preparation-only. Before any integration, the lead must obtain
an independent Reader-article review for the generated article hashes, freeze a
canonical destination, run `quizctl validate` on the copied files, then run the
lead-owned Reader catalog build. Those steps must use repository paths selected
by the lead; this controller never supplies or writes them.

`--self-test` writes nothing. It invokes the real frozen-source guard with a
deliberately wrong digest and confirms that an outside-scratch destination is
rejected. A repeat invocation with the same output directory is the separate
existing-destination refusal check.
