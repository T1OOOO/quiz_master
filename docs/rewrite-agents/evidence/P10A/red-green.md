# P10A RED/GREEN evidence

All commands ran sequentially from `C:\ap\quiz_master` with `-p=1`.

- RED: `go test -p=1 -count=1 ./next/server/internal/config` exited 1 because `Config.ContentManifestPath` did not exist. GREEN: the same command exited 0 after explicit local/nonlocal manifest configuration was added.
- RED: `go test -p=1 -count=1 ./next/server/internal/attempts` exited 1 because `loadManifest` and `buildReveal` did not exist. GREEN: the same command exited 0 after exact manifest coverage and contract-shaped answer display construction were implemented.
- RED: `go test -p=1 -count=1 ./next/server/internal/httpapi` exited 1 because `IdentityRoutes` and `identity.GuestSession` did not exist. GREEN: the package exited 0 after closed guest bootstrap, expiry metadata and non-leaking validation were implemented.
- RED: the HTTP package then failed because the new reveal path returned 404 instead of requiring authentication; the tagged attempts package also failed to compile because `Service.Reveals` did not exist. GREEN: HTTP tests exited 0 and tagged integration packages compiled after the owner-scoped finished-attempt reveal route was implemented.
- RED: the route-composition test failed to compile because `Routes` did not exist. GREEN: HTTP and API command tests exited 0 after exact identity and attempt patterns were registered on one mux.

The PostgreSQL behavior tests could not be executed because `QM_TEST_DATABASE_URL` is unset and the approved P09 disposable target was removed. No replacement container was started.
