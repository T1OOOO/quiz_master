# Cinema annotation report

Status: `DONE_WITH_CONCERNS` — this is a validated editorial subset, not full cinema coverage or acceptance.

## Scope read and annotated

- Frozen source revision: `e802ed21db936bdb9809bab2d137903eb0aa425e`.
- Completed `80/718` cinema questions: the complete eight-pack `quizzes/Cinema/Thematic80/**` scope, ten records in each of `theme-dreamworks`, `theme-game-of-thrones`, `theme-game-worlds`, `theme-harry-potter`, `theme-pixar`, `theme-star-wars`, `theme-terminator`, and `theme-tv-series`.
- Every completed source row was read with its complete `text`, four `options`, keyed answer index, and `explanation`. The read was deliberately split into twenty-record groups; Terminator/Harry Potter and DreamWorks were re-read using the `text` field after an initial extraction used the wrong stem field.
- Frozen inventory hashes for the eight read packs: `e13cafc8693797cd9f389adf2946a7a696d01602229a96ffe515c1afc5f4dced`, `104736270f2f641483435a97180922a3c7f7b004e5a578e0d6ad7f3af04e7afd`, `4461749dab49217a186e35d1ae402d6039029627fc8e71d438c56bf51c0106eb`, `306c65e20dca4bd35b4bc2fbb2041b6cd6d323dbc848d6d223958cacc61da1bc`, `f3dba1d7a85cb03bb5c9f9bbfc762646fcda8ff8d3b8b728c2a5baf1b0779be3`, `fb1d3a46fe0b6a6f0b0c6c30572e6e1cd6eb7a43bc0a940723fdf47d73657ad8`, `4267915feb8af31298e2e29e1051116e28dcc266ee65196afcdb849aa66d6d5d`, and `2451ef97e5bf0a7e91dbcd77cd75ffb23ae20607d0a60efb4a2d10805ac814c9` respectively.

## Decisions and metadata

- [cinema.json](cinema.json) uses `qm-question-annotations/v1` and the frozen `qm-tags-v1` taxonomy hash `2ff002603ad7794957962c89c9ccd32a5ddb7a43c72b0b17ae3d6c5e50ae6bf1`.
- Difficulty distribution: `2=15`, `3=17`, `4=23`, `5=19`, `6=4`, `7=2`; no score was copied from source data and no generic level-5 default was used. Each Russian rationale states the recall/comparison burden created by that question and its alternatives.
- All records have one domain and one topic/franchise tag. Private editorial tags retain game/franchise classification where it is specific to the fact; context omits unannounced Nintendo, Pokémon, and Star Wars affiliation in heterogeneous packs. All context tags are safe, sorted subsets.
- Ten Harry Potter records carry `book-vs-film-canon-boundary`, reflecting the pack's explicit seven-books scope inside the Cinema tree. Ten Star Wars records carry `screen-canon-scope`; the Andor row additionally carries `canon-origin-vs-upbringing-distinction`. These are scope flags, not factual re-verification claims.

## Evidence

```text
cwd: C:\ap\quiz_master
python metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/cinema.json --partial
Validated 80/4078 annotations; source integrity preserved.

git diff --check -- docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/cinema.json
exit 0
```

- Annotation SHA-256: `c05b529b03205fac6bd255ef01b517234497ef40a1db53cfe4079a62fa9d4c76`.
- Sorted `provider|pack_id|question_id` identity-list SHA-256: `47cc002c6db30292fbb91190341abc180860a8748a96e2d8466c62c43fb108b5`.

## Remaining coverage and risks

- Unread/unannotated cinema source coverage is exactly `638/718`: Home Alone `185`, LOTR `253`, Transformers `200`. No records for those packs are present in this file.
- The subset has not received independent editorial/fact review. Difficulty remains an editorial estimate for the specified Russian adult audience, not observed calibration.
- No source JSON, taxonomy, shared index, or production content was changed.
