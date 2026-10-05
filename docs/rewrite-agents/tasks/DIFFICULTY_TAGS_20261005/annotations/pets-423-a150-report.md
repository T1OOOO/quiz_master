# PETS 423-A150 annotation report

Candidate: `qm-question-annotations/v1`, 150 exact packet identities, taxonomy `qm-tags-v1` / `09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e`.

Raw coverage is 150/150: six complete batches of 25 or fewer, each containing the full stem, all options, keyed answer and explanation. No batch output was truncated. Source baseline is `e802ed21db936bdb9809bab2d137903eb0aa425e`.

Score counts: `{2: 3, 3: 15, 4: 24, 5: 52, 6: 34, 7: 20, 8: 2}`. There are 150 unique literal rationales and no low-confidence entries. Flags: `claim-needs-source` 32; `medical-claim-needs-source` 8. These are review prompts, not factual certification.

Per-pack current source SHA-256:

- `cats_breeds_man_made`: `4ad6a80bf33b7128bd952142a7a326e47dd2a60183a869575bad6d56737a9e84`
- `cats_breeds_natural_and_ancient_part_1`: `3deb462aadbdf9f50d142ba7f43fce98d223865706fa76e77c4bb3c17953005e`
- `cats_breeds_natural_and_ancient_part_2`: `d9f4ce6271f3d7c15661336489e85e29498f813d24b89c5b074d4a62850039c4`
- `cats_history_ancient_egypt`: `210daef7a394fb7f7fb4e89cb10dd996d99769ff6b20b20d63e6b3db383ce6ae`
- `cats_history_famous_and_culture`: `a45e227d6ea64933a56b0feb649c38a957ef2c1fc3b7c719cef94f5fdc7b8432`
- `cats_history_mythology`: `342779b0b56b5fa7e6c08d0a3a53d8c012513102b1d1828cb02fbac0bf03ad6a`
- `cats_history_other_eras`: `b6aab912a04224598def1029d277256524d85dab0686e060378d537f3cb709f7`
- `cats_trivia_records_and_general_part_1`: `547445d4f0d12016403cc306d34627af41fa1fc68fed3b4ba7e987874ad47194`
- `cats_trivia_records_and_general_part_2`: `6840a20001bd7d5fb4061333e03dc063dee84ce18bb13f847c82b6d816596464`

Executed check: `python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/pets-423-a150.json --partial` → `Validated 150/4078 annotations; source integrity preserved.`

Candidate SHA-256: `81ea9195d968dc6d6991c136b0df85be427adb0559e7f687bff61f36b5ce23d2`.

Ready for independent editorial review only; this report does not claim acceptance, source application, publication, or factual certification.
