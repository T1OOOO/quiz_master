# Film Craft release-package controller

`prepare_film_craft_release.py` is a preparation-only controller. It does not run during the current Flutter build and it does not publish, deploy, invoke Helm, contact a server, or alter repository content.

The release lead may run it only after both fresh output directories exist and their embedded assets match the frozen commit:

```powershell
python docs\rewrite-agents\tasks\FILM_CRAFT_RELEASE_20261013\worker\prepare_film_craft_release.py `
  --repo C:\ap\quiz_master `
  --frozen-commit c74253fe16e7ddf50d81fd884a2606483808448d `
  --production-web C:\ap\quiz_master\.run\film_craft_integration_20261013\production-web `
  --qa-web C:\ap\quiz_master\.run\film_craft_integration_20261013\qa-web `
  --prior-archive C:\ap\quiz_master\.run\home_alone_release_20261013\package-v2\quiz-2026.10.13-article-only-ffa2716.tar.gz `
  --output-root C:\ap\quiz_master\.run\film_craft_release_20261013\worker\package-v1
```

Frozen inputs and guards:

- Commit: `c74253fe16e7ddf50d81fd884a2606483808448d`.
- Helm48 archive: `quiz-2026.10.13-article-only-ffa2716.tar.gz`, SHA-256 `009e3c09fb72d82ddc9775b31e2774bc21f39da157607ba78732abb61eda7bf5`.
- Baseline image: `docker.io/library/quiz-master@sha256:8e3c6bd77ab94945093e2ca4394d8364cca9e306b91c791ce2b4461d2a0f0018`.
- Catalog/Reader source SHA-256: `9196ca0592034e2a5f8e02099c1f3a8f5a10a60e8ee81222427cbe682034927e` / `d06e01e33e8343951f48c7aa131a763128f216ad92bd2ab07717e4462f0870fc`.
- Expected release ID: `quiz-2026.10.13-film-craft-c74253f`.

The controller fail-closes on source byte hashes, template-anchor cardinality, baseline target/image/PVC/nginx guards, 132/4048/248 counts, exact four Film Craft Reader refs, all 131 old catalog rows, all 244 old Reader objects, eight unchanged cache entries, and 25 unchanged Home Alone questions. It appends only the Film Craft bundle as runtime cache entry nine.

Lightweight checks only:

```powershell
python -m py_compile docs\rewrite-agents\tasks\FILM_CRAFT_RELEASE_20261013\worker\prepare_film_craft_release.py
python docs\rewrite-agents\tasks\FILM_CRAFT_RELEASE_20261013\worker\prepare_film_craft_release.py --repo . --frozen-commit c74253fe16e7ddf50d81fd884a2606483808448d --production-web ignored --qa-web ignored --output-root .run\film_craft_release_20261013\worker\self-test-output --prior-archive ignored --self-test
```

Local packaging needs the frozen source and fresh Flutter outputs so Root can obtain a concrete package for review. Remote preparation and publication remain gated on independent review, copied-DB rehearsal and rollback, image/Helm/server checks, browser verification and the existing user authorization.

The controller's no-write self-test prints static configuration only; it does not independently test actual asset counts. Root executed the real package producer and verified its archive/checksum/content preservation plus three rejection cases in the adjacent package-root-verification.json.
