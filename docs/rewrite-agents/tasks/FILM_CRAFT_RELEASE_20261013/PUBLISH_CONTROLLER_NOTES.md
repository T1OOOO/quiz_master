# Film Craft inert publisher

`publish_prepared.py` accepts a corrected evidence directory (final package v3). It rejects the failed v1 archive `e6a26225619149708c8fb2c3ac93a42cadf095efb68c9b6d9136549a20163083`. Default and preview modes only validate locally; explicit `--publish` runs the reviewed remote script.

The lead supplies `package-current.json`, `execution-packet.json`, and actual independent `execution-acceptance.json` in `--release-dir`. Package/archive/image/log hashes, accepted state, frozen source/build/assets and `132/4048/248` counts must agree. Root also added controller hash, frozen Git runtime diff, exact browser evidence, values filename and durable archive path guards after native handoff.

It derives the atomic Helm/public version/compiled Flutter output/Reader checks from the prepared identity/lock/checksum/fresh backup/copied-DB rehearsal prefix. The CLI always checks the exact reviewed shell hash and consumes the prepared image without rebuilding. Root may call the pure renderer with `verify_hash=False` to create the inert shell for review; this option is not exposed by the publication CLI.

No gate is satisfied by this controller alone. Corrected preparation, actual independent review, fresh backup/copied-DB rehearsal, capacity and Helm checks precede the authorized atomic upgrade and public verification. Historical v1 failed before image build; v2 was never run remotely because Root found a second stale rollback-history guard; v3 corrects both.
