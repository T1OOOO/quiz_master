# Independent Two Towers / Silmarillion audit

Reviewer: `lotr-two-towers-review-20261004`
Candidate revision: `17470efa8031a6ca34d94317fc63154f710e632b`
Scope: `candidates/lotr_two_towers_lore_100.json`, all 100 IDs. No quiz or integration file was edited.

`blind_answers.json` was written before this reviewer opened the private key, original quiz, or any prior report. `review.json` is the complete per-ID record: verdict, blind answer, intended answer, source code, factual/ambiguity analysis, and exact replacement text/options/key/explanation for every non-accept verdict.

| Verdict | Count | IDs |
| --- | ---: | --- |
| Accept | 59 | 2, 4–6, 8–12, 15, 17–18, 23, 26–33, 36–38, 40–42, 44, 47–49, 51–54, 58–61, 65, 68–72, 77–81, 83–84, 88–91, 95–96, 98 |
| Revise | 30 | 1, 3, 7, 13–14, 16, 19–22, 24–25, 34–35, 45–46, 50, 55–57, 62–63, 66, 75–76, 82, 86, 92–93, 100 |
| Reject/replace | 11 | 39, 43, 64, 67, 73–74, 85, 87, 94, 97, 99 |

## Findings that block direct approval

- `lotr_tt_20`: the prompt asks about a second personality; its key is the pronoun “we”.
- `lotr_tt_21`: no offered answer defines mearas accurately.
- `lotr_tt_43`: Figwit is a fandom nickname, not a canonical named character.
- `lotr_tt_56`: the 43/42 tally is an intermediate extended-film moment; subsequent dialogue changes Legolas’s count.
- `lotr_tt_63`: key “Morwen” is false. Théodwyn is Éowyn and Éomer’s mother; Morwen is a film villager.
- `lotr_tt_73`, `lotr_tt_74`, `lotr_tt_99`: each confuses distinct canonical concepts, so the current key cannot be accepted.
- `lotr_tt_94`: “Нарсинг” and the claimed office have no verified Tolkien source.
- `lotr_tt_97`: Vingilot is verified, but “first ship” is not.

## Source inventory and limitations

| Code | Opened source / checked reference | Applied to |
| --- | --- | --- |
| `LTT` | J.R.R. Tolkien, *The Lord of the Rings: The Two Towers* (1955), public scholarly-text mirror: <https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_2__en.htm>; checked Book III chs. 2–10 and Book IV chs. 1–6 | Rohan, Ents, Uruks, Helm’s Deep, Faramir, Gollum |
| `LOTR` | Tolkien, *The Fellowship of the Ring* / Appendices, public text mirror: <https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_1__en.htm>; and *Return of the King*: <https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_3__en.htm> | Gandalf’s Orthanc rescue, Narsil, ancestry, languages, chronology |
| `SILM` | J.R.R. Tolkien, *The Silmarillion* (Christopher Tolkien ed.), public text mirror: <https://ae-lib.org.ua/texts-c/tolkien__the_silmarillion__en.htm>; checked Ainulindalë, Valaquenta, Quenta chapters and Akallabêth | Valar, Silmarils, First/Second Age, Beren, Númenor, Vingilot |
| `UT` / `MR` | *Unfinished Tales*, “The Istari”; *Morgoth’s Ring*, “Myths Transformed” | Blue Wizards; Orc-origin qualification; Athrabeth scope |
| `FILM` | *The Lord of the Rings: The Two Towers* screenplay/transcript: <https://imsdb.com/scripts/Lord-of-the-Rings-The-Two-Towers.html> | Film-only claims, including the red-sun line, Entmoot, fish song and extended-scene warnings |

The Tolkien mirrors are public e-text hosts, so citations in the JSON give edition/chapter anchors rather than treating the host as an authority. IMSDb identifies transcription contributors; it was used only for scene/dialogue checking and is not treated as an authoritative shooting script. The Longbottom Leaf and kill-count items need an identified extended-film source before publication.

Checks: `ConvertFrom-Json review.json` parsed; 100 unique candidate IDs were matched to 100 review records; verdict totals are 59 accept, 30 revise, 11 reject. No build was run, as the packet authorizes text research/JSON work only.
