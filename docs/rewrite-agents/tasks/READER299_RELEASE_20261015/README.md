# Reader299 and result-feedback release preparation

Frozen app source: `9c670e90ac0547eb9d276d6190a87a71680b7fd2`.
Target build: `quiz-2026.10.15-reader299-9c670e9`.

Source review accepted the result-feedback fix and eight independently fact-checked actor articles. The library now contains 299 articles, 180 question references, 178 playable references and two known non-catalog references. All prior 291 article objects are identical; question wording, options and grading were preserved.

Both actual Flutter release builds exited zero. Frozen production and QA file trees each contain 74 files. The production JavaScript hash is `9ca6e91bc7c94ea0ac4b421d008885438f0909bb175a1e07b296a580249063cc`; the separate QA hash is `cd6e392b7bcdb2a70b15385691dd3785de65a549db5ebf7943a1b473a0a25647`.

`local-browser/browser-proof.json` records actual compiled Flutter and isolated Go API checks at 361×738. All eight exact public questions 013–020 were answered incorrectly to expose their articles. Each article had four readable sections, two source controls and no editable text areas. Root inspected all eight footers and the result screenshot. The inline result feedback dialog opened/cancelled; History retained its global feedback button; browser errors were empty. This is an eight-question subset fixture with its own quiz revision, not a full-20-question or immutable Linux image test.

Official browser close exited one. Only the captured named daemon was stopped after exact PID-file, creation-time and command-line validation. A subsequent audit confirmed all 13 captured identities inactive and ports 19090, 19093 and 19098 closed; unrelated processes were preserved. The isolated Go API returned one after intentional Windows termination with its stop file observed; its server wrapper exited zero. One stale History ref failed after dialog cancellation; a fresh snapshot and click succeeded, with both artifacts retained.

The first generic preparation prototype omitted required safeguards and was never executed remotely. Its four exact-hash untracked files were archived outside tracked source and removed. See `controller/prototype-disposition.json`. A separate bounded helper owns fresh target-specific preparation adapters. Source, exact package, remote rehearsal, current capacity/backup/rollback checks and execution review remain release gates.

Production is still the accepted Helm61 Reader291 baseline. All 29 real feedback rows remain open; feedback5nc stays in progress until published verification. No Reader299 publication, Android or physical screen-reader certification is claimed.
