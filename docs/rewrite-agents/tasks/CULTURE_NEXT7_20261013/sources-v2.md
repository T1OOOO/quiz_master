# Next7 source and self-check ledger

Accessed 2026-10-13 through direct institutional-page opens: BFI pages for *In the Mood for Love* and *Beau travail*; Rock & Roll Hall of Fame pages for Chaka Khan, Dionne Warwick and Celia Cruz. The BFI film card identifies Wong Kar-wai, Tony Leung and Maggie Cheung; its feature identifies Chow Mo-wan and Su Li-zhen. BFI identifies Claire Denis as director of *Beau travail*. Rock Hall supports the named Chaka/Rufus/Chaka and “I'm Every Woman” relationship, Warwick’s Bacharach–David context and “Walk On By”, and Cruz’s Sonora Matancera period.

Each item records two URLs in `writer-v1.json`; for three compact Rock Hall profiles the same directly opened institutional profile is intentionally repeated, because it is the one page that directly establishes both the question fact and article context. This is a source-strength limitation for independent review.

## Structural checks

- IDs: cinema-people-025..028 and music-people-025..028, exactly once.
- Intended correct indexes per cinema pack: 0, 1, 2, 3; music pack: 0, 1, 2, 3.
- Manual key equality: each `correct_answer_text` equals `options[correct_answer]`.
- Each question has four distinct, plausible choices.
- Article word counts (Russian alphanumeric tokens): cinema-people-025 112; 026 118; 027 112; 028 110; music-people-025 114; 026 113; 027 116; 028 131.
- `writer-v1.json` SHA-256 at final check: `AB2973CAC130FAB187AD2AC651CB8061D90023E02369C32BBFD9CBA0AE057D72`.
- Duplicate screen: compared the proposed names/titles/stems against the Next6 root screen (131 legacy JSON packs / 4032 questions / 230 reader entries) and current People/Next6 draft material. No exact stem or answer-fact duplicate found. The cinema pair 027/028 deliberately share a film but test different performer-to-character links; reviewer should decide whether that within-batch concentration is desirable.

## Review limits

This is a draft-only author self-check. It does not certify facts, sources, taxonomy, whole-bank uniqueness, publication, or acceptance. Independent different-provider source and option review remains required.
