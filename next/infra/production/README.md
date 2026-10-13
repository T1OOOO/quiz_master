# Production static asset validation

`nginx.conf` is the canonical production configuration. Immutable Web packages normalize mtimes for reproducibility. Because Nginx's default ETag depends on mtime and length, different equal-length assets can share a validator. The server disables ETag generation and If-Modified-Since handling, while preserving `Cache-Control: no-cache`. Conditional requests therefore fetch the current bytes. Last-Modified can still appear in responses, but Nginx does not use it to return 304.

The policy follows the official [ETag](https://nginx.org/en/docs/http/ngx_http_core_module.html#etag) and [If-Modified-Since](https://nginx.org/en/docs/http/ngx_http_core_module.html#if_modified_since) directives. The tradeoff is additional transfer during revalidation, with existing gzip compression retained.

`check_cache_validators.py` exercises both the original and corrected configuration in disposable Nginx containers. It requires an existing local image and Docker on a Linux host. It publishes only random loopback ports, starts no API, and cleans up only its own containers and temporary files.

```sh
python3 check_cache_validators.py --image EXISTING_IMAGE --baseline ORIGINAL_CONF --fixed nginx.conf
```

`Dockerfile.cache-hotfix` supports a configuration-only release from an already verified application image. The release controller must check the base image ID before and after the build, prohibit pulls, prove all application files remain identical, preserve the application build metadata, and prepare a separate immutable image plus reviewed Helm cutover/rollback. A later full package must copy this configuration from its frozen Git source. No database migration or application rebuild is implied by this image layer.

The article-only release `quiz-2026.10.13-article-only-ffa2716` was published as Helm revision 48 with 244 Reader articles. Its reviewed controller is `docs/rewrite-agents/tasks/HOME_ALONE_BINDING_20261013/prepare_article_package.py`; preparation, independent review and published verification are recorded in `docs/rewrite-agents/tasks/HOME_ALONE_RELEASE_20261013/`. The application remains Flutter/Dart, and `main.dart.js` is compiled Flutter Web output.

That controller copies the approved configuration from its frozen Git source, rejects missing or changed configuration and absent Dockerfile copy instructions, and checks staged and built-image configuration hashes before Helm actions. It pins the previous Helm47 image, approved configuration and reviewed 244-article Reader bytes. It preserves all 25 Home Alone questions, checks exactly two new article bindings, retains the other full-pack binding checks, and rejects missing or duplicated build-prefix template anchors. These historical pins must be reviewed and updated for a future release; do not rerun this controller against the now-published Helm48 deployment. Retained regression packages use older compiler outputs solely to test packaging and must not be deployed. Future publication still requires fresh builds and all release gates.
