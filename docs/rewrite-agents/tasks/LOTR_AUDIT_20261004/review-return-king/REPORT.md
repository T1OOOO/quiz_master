# Independent Return of the King / production-100 review

Status: `DONE_WITH_CONCERNS`. This review examined all 100 candidate-facing cards independently, then the private key. It does not modify, publish, import, or accept the production quiz.

The blind pass is preserved in `blind_answers.json`. It was written before opening the key or another report. `review.json` has one record per stable ID, the blind and intended answer, a verdict, option check, actual source basis, and exact replacement text/options/key/explanation for every revision or rejection. `sources.json` is the inventory of sources actually opened, including inaccessible and insufficient sources.

## Result

| Verdict | Cards |
| --- | ---: |
| Accept | 55 |
| Revise | 27 |
| Reject / source-verifiable replacement required | 18 |

Nine cards have a false intended premise or no valid keyed answer: `lotr_rk_27`, `30`, `42`, `53`, `54`, `67`, `83`, `84`, and `99`. The strongest immediate errors are the Nimloth/White Tree conflation (`3`), the incoherent Monaghan/Merry book-production mix-up (`30`), Gwaihir described as female (`53`), the non-existent Gimli death quotation (`67`), and the claim that Bilbo, Sam, and Tom are “a human” (`84`).

The review explicitly rejects the unverified production folklore in `22`, `24`, `26`, `46`, `48`, `49`, and `100`. These are not approved on a wiki-memory basis. `21`, `25`, `47`, and `91` were narrowed where an opened firsthand interview provides limited support.

## Evidence scope

The primary book text was opened for all three volumes, with Return of the King passages used for the White Tree (the text calls it a sapling *of the line of Nimloth*), the King of the Mountains/Dead, the Mouth of Sauron, Gollum and the Ring, Arwen’s unnamed white gem, the Scouring, and the Grey Havens. The October 2003 screenplay on IMSDb was also opened to distinguish film claims; it is a final-revision screenplay/transcript and not proof of the released cut or book canon. The Academy’s official record verified the Oscar item. The Tolkien Estate biography verified the biography items. Firsthand Jackson, Mortensen, Serkis, and Lee material was used only within its demonstrated scope.

The complete source URLs, textual locations, transcript limitations, and failed/insufficient evidence are in `sources.json`.

## Remaining risk

The recommendations need an editor’s decision about whether to retain 18 rejected slots as replacements. No later editorial revision was supplied for recheck. Film-credit-only questions should be rechecked against final on-screen credits before import, and the screenplay must not overwrite book/film distinctions.
