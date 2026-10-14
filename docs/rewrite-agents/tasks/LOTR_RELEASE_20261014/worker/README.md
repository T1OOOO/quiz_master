# LOTR release controller

`prepare_lotr_release.py` is a fail-closed validator adapted for the verified
ScreenSong52 baseline. It has no execution path for deployment, SSH, Docker,
Flutter, browser work, database work, Git mutation, or Helm.

It requires Root's later `qm-lotr-release-pins/v1` file to bind the frozen
source, both actual Flutter receipts, source/export review, browser proof,
runtime bundle, exact Reader snapshot bundle and public baseline. It checks the immutable ScreenSong52
archive/image/API/nginx/PVC identity, safe tar member paths, 12-to-13 cache
append-only behavior, 135/4064/266 targets, 98 unchanged public LOTR question
projections, the two repaired revision hashes, `/app` source URI, retained
`lotr-rk-95-opt-5`, key `lotr-rk-95-opt-2`, and Reader revision bindings.

The included tests read the frozen real runtime/public/snapshot/browser and
ScreenSong52 baseline inputs, then apply narrowly scoped synthetic mutations to
prove the guards reject changed inputs. Passing them is not an approval,
package, build, browser test, database rehearsal, or release.
