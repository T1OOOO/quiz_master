# Exact29 adapter v2: close owned SQLite handles

This composition closes the three read-only SQLite connections owned by the exact29 cleanup flow. It does not weaken process checks or exclude its own PID. No production backup was removed, no remote command executed and no immutable v1 file changed.

Root actual Linux diagnostics established both failures before this work: fixture setUp retained a connection after a SQLite context-manager exit; the house two-group loop also retained its keeper connection and correctly triggered the own-process guard before any unlink. Root recorded oldhouse failure with two aliases intact, while an explicit-close diagnostic removed only its two temporary aliases and retained both temporary keepers. The selected production preflight contains two more owned read-only connection contexts.

## Small composition over accepted v1

The helper pins/imports the accepted v1 adapter, pins original deletion bytes29cde, pins the f36 corrected fixture and assembler, and rehashes every entry in the unchanged38-input source-review manifest8d645d8989b34afc910ee75af17f3e9e3a9a4a43ac3fde731cce600d01f9d33e. Its only production transformations wrap the exact one house keeper-integrity SQLite context and exact two preflight SQLite contexts with standard-library contextlib.closing and import contextlib. Read-only URIs, SQL statements and their bodies remain unchanged. The v1 source files are never edited or recopied as a second production framework.

Local AST comparisons verify that run_exact, no_process_use, verify_entry, verify_inventory, verify_protected, check_capacity, validate_plan, loaded_images and images_preserved are unchanged. The production shell differs from immutable v1 only by replacing its derived guard source and embedded house_source with the explicit-close versions. No own-PID exception or journal/process bypass exists.

Actual source hashes are explicit:

- Original date-adapted house source: `8ba41de0db8cb0627bd5a49d87314236bca6e59e2f5504aa97db03ae99afcfb7`.
- New closing-context house source: `c32104d26bb7f8306742341f8c78005431783986460c9fae33348097cbd57524`.
- Original current63-derived guard source: `a2c7b60630c635f869379130e47f359ae0bad23f3ed69e527a7e784d1d132ee4`.
- New closing-context guard source: `17c604f7bb718aa8e8f0af3b9cb42e24622cd1594f388805c8a94a8949e560cb`.

These are derived source strings; they are not mislabelled as the raw historical dependency hash. Immutable plan ded18e94923b44ba5a4d5dda126b4b8aeea834b10c743965e9617706f0281d3f, protection9052dc05fcf76728a1131cda567cd49c1e28c268c62f3e9dfb3a29e78e12a1bf, selection29/preserved185/states52/protected32, strict20percent+1GiB rule,64MiB growth bound, baseline63/images/PVC/full29feedback, lock and fresh loaded-identity preservation all remain unchanged.

## Meaningful isolated Linux tests

The new isolated suite reuses the frozen f36 fixture setUp connection fix and all14 prior cases. Those house cases now load the new closed house source. Two new temporary-database cases are added:

1. Two real private SQLite keepers and paired aliases run through actual house validation and the unchanged own-process/fingerprint guard. Original house must refuse with both aliases still present. The new closed house must remove exactly those two temporary aliases and retain both keeper metadata/full hashes. All tracked fixture connections are explicitly closed afterward.
2. Both exact original and revised preflight SQLite context expressions open real read-only temporary SQLite connections through an explicit fixture connector. The test confirms owned open connections trigger the unchanged process guard, original contexts retain their handles, and each revised context closes its handle (including ProgrammingError on reuse). This connector never opens the production URI; mode=ro and uri=True arguments are asserted.

The resulting16 Linux cases remain **PENDING Root execution**. This worker compiled the isolated program and checked syntax; it did not run Linux or report a fabricated successful16-test result.

## Actual local checks

- Three portable composition/binding/syntax tests passed, actual exit0; no skipped tests.
- Every pinned source/input mutation and an incorrect context count were refused. Fresh output is mandatory.
- Actual retained local render exited0.
- Both retained shell files passed explicit Bash syntax checks, actual0. Both embedded Python programs compiled, actual0.
- All38 accepted input hashes were rechecked; immutable v1/29cde and f36 files are unchanged.

Actual command receipts and raw logs: `C:\ap\quiz_master\.run\country483_remote_20261015\capacity-adapter-v2\checks.json` and `C:\ap\quiz_master\.run\country483_remote_20261015\capacity-adapter-v2\syntax.json`. Complete source/output/dependency hashes are in evidence.json and preview-v1/receipt.json.

## Caller and remaining gate

From C:/ap/quiz_master:

```powershell
C:/Python314/python.exe -B -m unittest discover -s docs/rewrite-agents/tasks/COUNTRY483_REMOTE_20261015/capacity/adapter-v2 -p test_compose_adapter.py -v
C:/Python314/python.exe -B docs/rewrite-agents/tasks/COUNTRY483_REMOTE_20261015/capacity/adapter-v2/compose_adapter.py --output-root C:/ap/quiz_master/.run/country483_remote_20261015/capacity-adapter-v2/preview-v2
```

The preview-v2 example is unexecuted. Actual preview-v1 is frozen. This CLI only renders; it has no execute option. Root may run the explicitly authorized isolated16-case Linux fixture after source inspection, retain its genuine exit/results, then submit the exact v2/f36/results/Root packet for final different-provider review before any production alias unlink. A successful fixture is not release/preparation/cleanup acceptance, and capacity peak remains uncertified.

## Frozen source and outputs

- `docs/rewrite-agents/tasks/COUNTRY483_REMOTE_20261015/capacity/adapter-v2/compose_adapter.py`: `5bebdf180218b63592c8f944b41613dc9aa90f4e35a82efc664bf839fcd75cc5`
- `docs/rewrite-agents/tasks/COUNTRY483_REMOTE_20261015/capacity/adapter-v2/linux_integration.py`: `e69062c43c0442fad78880eb570e9615834eb7f7b9f9435a9cbb0a15fba0bf16`
- `docs/rewrite-agents/tasks/COUNTRY483_REMOTE_20261015/capacity/adapter-v2/test_compose_adapter.py`: `5ce20c490bc718f0553e8b1d5f89cd91d5eb28c3e380d643366dd3a4931a1af4`
- `C:\ap\quiz_master\.run\country483_remote_20261015\capacity-adapter-v2\preview-v1\deduplicate-v2.sh`: `6be3e396697dab7966718148c61ee780a50c81f66e83d41354ddbb9f19b606eb`
- `C:\ap\quiz_master\.run\country483_remote_20261015\capacity-adapter-v2\preview-v1\linux-integration-v2.sh`: `787a2ea7d2227b63356f2e3e9641b562d05583a169f78a9e6f43968c90874d1c`
- `C:\ap\quiz_master\.run\country483_remote_20261015\capacity-adapter-v2\preview-v1\receipt.json`: `0df40198fd7ab0b381570efa0fd525a39436242dce8d1a4982aa8a1acc9620ae`

No SSH/network, Git, Beads, server, process cleanup, publication or child-agent operation was performed.
