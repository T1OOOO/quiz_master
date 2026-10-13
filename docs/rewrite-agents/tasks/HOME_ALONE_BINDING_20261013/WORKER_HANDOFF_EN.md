# Home Alone Reader binding preparation handoff

## Scope and source state

`prepare_reader.py` is a source-preparation tool, not an importer or a
publication mechanism. It writes only a caller-selected new JSON file and
refuses to overwrite an existing path. It does not change the runtime Reader,
canonical content, Git state, build outputs, or release package.

The tool hard-pins these inputs before it produces anything:

| Input | Required SHA-256 | Guard |
| --- | --- | --- |
| Current Reader baseline | `1eec259aa70e73dab9b3b357d4f05d274136c5a13ef023f5917fd63547590aa0` | Exactly 242 already-accepted rows and `qm-question-articles/v1` |
| Accepted writer V3 | `b734f5c0b06d29d1607b6d62098ee85c854953e960ce47b4b80b96268292c7ff` | Exactly the two expected draft rows |
| Independent V3 review | `f7c92eeec001f981cf06419bf8b8d59cd3e6afe8418032d188d95e61646be199` | `ACCEPT`, exit 0, hash pin, and delivered Claude verdict message `36692` |
| Immutable published Home Alone bundle | `58540f20607cf0d4294788a9e039b9797a9861ed3375e0aefcbd680461bf3746` | Quiz identity and all 25 released repaired questions |

The two draft bindings must exactly match the immutable published bundle:

| Article | Question | Published revision SHA-256 |
| --- | --- | --- |
| `question:q-ha1-p1-1` | `q-ha1-p1-1` | `b0f0047c659e193d6790f6cc209cb1135650cab8f8a2f716fda3c20d0a6e787f` |
| `question:q-ha1-p1-2` | `q-ha1-p1-2` | `0c4a99cddbb490c34f4918bac8f7ed1588b50acbd1ed6378fc8212ed5bf6005d` |

The older Git `next/content/home-alone-1-part-1/bundle.json` is deliberately
not an accepted binding input. Its first two revisions differ from the released
canonical bundle and the script rejects a wrong immutable baseline by hash.

## Output behavior

The output has the current approved `qm-question-articles/v1` shape with 244
unique, accepted rows. Its first 242 article objects are compared directly with
the input baseline and remain semantically unchanged, including their existing
question references and source links. The two new rows retain every draft field
except their `status`, which becomes `accepted` only in the generated output.
The tool validates unique article IDs, unique question-revision references,
source-link metadata, the output schema, and all published Home Alone question
revisions.

Historical workflow limit: V1 was rejected for filler; V3 was independently
accepted as the exact reviewed source hash. The original native Hub task could
not be formally resubmitted because of its owner/running mismatch. The V3
review records that limitation explicitly, and this new offered-and-accepted
worker assignment is the only task state represented by this preparation
handoff. This does not claim
publication, runtime integration, or historical task acceptance.

## Root-owned pre-review preparation commands

Run these non-runtime preparation checks before the independent
different-provider review, so the reviewer can assess the script and fresh
execution evidence together. They produce a new artifact under Root-controlled
`.run`; the final command can run only once for that filename.

```powershell
Set-Location C:\ap\quiz_master
$outDir = 'C:\ap\quiz_master\.run\home-alone-reader-binding-20261013'
$output = Join-Path $outDir 'question-articles-244.json'
if (Test-Path -LiteralPath $output) { throw "Refusing to reuse existing output: $output" }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
python docs\rewrite-agents\tasks\HOME_ALONE_BINDING_20261013\prepare_reader.py --output $output --dry-run
python docs\rewrite-agents\tasks\HOME_ALONE_BINDING_20261013\prepare_reader.py --output $output
Get-FileHash -Algorithm SHA256 -LiteralPath $output
```

After independent review, Root must perform the separate integration/package
checks, copied-data rehearsal, and release gates before copying that result
anywhere. Runtime asset edits, builds, browser checks, image/Helm work, and
deployment are outside this worker assignment.
