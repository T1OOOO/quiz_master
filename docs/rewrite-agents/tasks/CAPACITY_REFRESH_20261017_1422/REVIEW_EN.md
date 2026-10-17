# Independent capacity observation review

Verdict: accepted for observation only. Requirements pass for the saved evidence; code quality is not applicable because this packet changes no production code. No blocking arithmetic, name/allocation or scope error found.

Reviewed analysis SHA256: `1099ee064927665c7021c76d158d57c7f9ba45467a507935c17dd51ef7dcd7d0`.
Inventory SHA256: `a7d721bc8c9a42fd5587b51a66381cbfc136d324429bc252005866411234d2fe`.
Production SHA256: `be2ab602708709471c32e0acab073699ade0ce33343144658cf960eb17fdf23a`.
All three baseline file hashes match the analysis bindings; review.json records them. Both captures parse, report exit0 and empty stderr, and record no mutation.

The exact 28 unique historical basenames match DISK_HEADROOM_20261016/proposal.json. Every allocated-byte value matches both refreshed inventory and analysis. The two named October 14 rollback directories and all six October 15+ entries are excluded. This is a historical comparison set, never a cleanup allowlist.

| Independent calculation | Bytes |
| --- | ---: |
| Minimum available for strict20% |20,483,434,906|
| Inventory sample deficit |3,771,906,458|
| Health sample deficit |3,769,907,610|
|1GiB reserve +64MiB growth |1,140,850,688|
| Inventory planning target |4,912,757,146|
| Historical28 allocation total |2,231,140,352|
| Pool shortfall to inventory floor |1,540,766,106|
| Pool shortfall to planning target |2,681,616,794|
| Health free-space decline from pinned prior capture |552,423,424|

The threshold uses the next integer above 20% of 102,417,174,528 bytes. Health available space is 16.319% and fails the floor. The two fresh free-space samples differ by 1,998,848 bytes; they are non-atomic. The analysis consistently uses the inventory sample for its target and the health sample for the prior-health comparison.

Quiz Master aggregate allocation remains 7,970,795,520 bytes against its pinned baseline. The 36 listed release directories sum to 3,969,986,560 bytes, which differs from the separate release aggregate of 4,588,285,952; project allocation exceeds release+backup aggregates by 139,264 bytes. The analysis makes no claim of an exhaustive decomposition, exclusive reclaim or content identity, so these are measurement limits rather than a demonstrated error.

Saved production captures agree on revision 64/deployed, image identities, one replica, readiness 200, healthy conditions/no taints, 43 feedback rows all open and unchanged digest. The two local frozen scope pins also match. These saved observations do not constitute a live remote attestation or a release gate.

HANDOFF_EN.md and validate.py were read for consistency. Both preserve the two-sample distinction and inventory floor calculation. The validator was not executed because it writes Root's validation.json; the arithmetic and pins were independently checked directly.

No causal attribution is justified. The report correctly leaves global growth cause unestablished and grants no copy, archive, deletion, restore or cleanup authority. Genuine different-provider acceptance remains pending.

Not checked: live SSH/remote state, exclusive reclaim, file-level fingerprints, cold-copy/restore, deletion algorithm, build/UI or release approval. No remote action or source-evidence edit performed.
