# Production static asset validation

`nginx.conf` is the canonical production configuration. Immutable Web packages normalize mtimes for reproducibility. Because Nginx's default ETag depends on mtime and length, different equal-length assets can share a validator. The server disables ETag generation and If-Modified-Since handling, while preserving `Cache-Control: no-cache`. Conditional requests therefore fetch the current bytes. Last-Modified can still appear in responses, but Nginx does not use it to return 304.

The policy follows the official [ETag](https://nginx.org/en/docs/http/ngx_http_core_module.html#etag) and [If-Modified-Since](https://nginx.org/en/docs/http/ngx_http_core_module.html#if_modified_since) directives. The tradeoff is additional transfer during revalidation, with existing gzip compression retained.

`check_cache_validators.py` exercises both the original and corrected configuration in disposable Nginx containers. It requires an existing local image and Docker on a Linux host. It publishes only random loopback ports, starts no API, and cleans up only its own containers and temporary files.

```sh
python3 check_cache_validators.py --image EXISTING_IMAGE --baseline ORIGINAL_CONF --fixed nginx.conf
```

`Dockerfile.cache-hotfix` supports a configuration-only release from an already verified application image. The release controller must check the base image ID before and after the build, prohibit pulls, prove all application files remain identical, preserve the application build metadata, and prepare a separate immutable image plus reviewed Helm cutover/rollback. A later full package must copy this configuration from its frozen Git source. No database migration or application rebuild is implied by this image layer.

For the next full release using the existing V8 archive template, use the reviewed controller in `docs/rewrite-agents/tasks/CACHE_POLICY_3RX_20261013/prepare_next_package.py`. It copies the approved configuration from the supplied frozen Git commit, rejects a missing/changed configuration or absent Dockerfile copy instruction, and checks the staged and built-image configuration hashes before Helm actions. Historical controllers are preserved as evidence and must not be reused directly. This controller pins the current Helm47 baseline and the current approved configuration; changing either requires review. The retained regression packages reuse older compiler outputs solely to test packaging and must not be deployed. An actual release still requires fresh builds and all existing release gates.
