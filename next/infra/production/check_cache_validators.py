"""Exercise real Nginx conditional responses in two disposable loopback containers.

Run on a Docker host with an already available Quiz Master image:
python3 check_cache_validators.py --image IMAGE --baseline OLD_CONF --fixed NEW_CONF
No production files, volumes, databases or running services are modified.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.error
import urllib.request
import uuid


def command(*args):
    return subprocess.check_output(args, stderr=subprocess.STDOUT, text=True, timeout=30)


def request(url, headers=None):
    try:
        response = urllib.request.urlopen(urllib.request.Request(url, headers=headers or {}), timeout=3)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        return response.status, dict(response.headers.items()), response.read()


def check_headers(headers):
    expected = {
        "Cache-Control": "no-cache", "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "SAMEORIGIN", "Referrer-Policy": "strict-origin-when-cross-origin",
        "Strict-Transport-Security": "max-age=31536000",
    }
    for name, value in expected.items():
        assert headers.get(name) == value, (name, headers)


def exercise(image, config, fixed):
    name = "qm-cache-test-" + uuid.uuid4().hex
    started = False
    results = []
    with tempfile.TemporaryDirectory(prefix="qm-cache-test-") as directory:
        root = Path(directory)
        root.chmod(0o755)
        web = root / "web"
        web.mkdir(mode=0o755)
        conf = root / "nginx.conf"
        conf.write_bytes(config.read_bytes())
        conf.chmod(0o644)
        fixtures = {"version.json": (b'{"value":1}', b'{"value":2}'),
                    "main.dart.js": (b'var quiz=1;', b'var quiz=2;')}
        for path, (old, new) in fixtures.items():
            assert len(old) == len(new) and old != new
            (web / path).write_bytes(old)
            os.utime(web / path, (0, 0))
        common = ["docker", "run", "--pull=never", "--read-only", "--tmpfs", "/tmp",
                  "--mount", f"type=bind,src={web},dst=/usr/share/nginx/html,readonly",
                  "--mount", f"type=bind,src={conf},dst=/etc/nginx/nginx.conf,readonly",
                  "--entrypoint", "nginx"]
        syntax = command(*common, "--rm", "--network=none", image, "-t")
        try:
            command(*common, "--name", name, "-d", "-p", "127.0.0.1::8080", image, "-g", "daemon off;")
            started = True
            address = command("docker", "port", name, "8080/tcp").strip()
            assert address.startswith("127.0.0.1:"), address
            base = "http://" + address + "/"
            deadline = time.monotonic() + 15
            while True:
                try:
                    assert request(base + "version.json")[0] == 200
                    break
                except (OSError, AssertionError):
                    if time.monotonic() >= deadline:
                        raise
                    time.sleep(0.1)
            for path, (old, new) in fixtures.items():
                status, headers, body = request(base + path)
                assert status == 200 and body == old
                check_headers(headers)
                if fixed:
                    assert "ETag" not in headers, headers
                    old_tag = '"0-' + format(len(old), 'x') + '"'
                else:
                    old_tag = headers["ETag"]
                modified = headers["Last-Modified"]
                assert modified == "Thu, 01 Jan 1970 00:00:00 GMT", modified
                (web / path).write_bytes(new)
                os.utime(web / path, (0, 0))
                checks = []
                for conditional in ({"If-None-Match": old_tag}, {"If-Modified-Since": modified},
                                    {"If-None-Match": old_tag, "If-Modified-Since": modified}):
                    code, response_headers, response_body = request(base + path, conditional)
                    check_headers(response_headers)
                    assert code == (200 if fixed else 304), (path, conditional, code, response_body)
                    assert response_body == (new if fixed else b""), (path, response_body)
                    checks.append({"request_headers": conditional, "status": code,
                                   "body_sha256": hashlib.sha256(response_body).hexdigest()})
                # Control: the old configuration serves the new bytes without conditionals.
                code, _, body = request(base + path)
                assert code == 200 and body == new
                results.append({"path": path, "length": len(old), "mtime": 0,
                                "initial_headers": headers, "conditional_checks": checks})
            return {"mode": "fixed" if fixed else "baseline", "config_sha256": hashlib.sha256(config.read_bytes()).hexdigest(),
                    "syntax_check": syntax.strip(), "fixtures": results}
        finally:
            if started:
                command("docker", "rm", "-f", name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--fixed", type=Path, required=True)
    args = parser.parse_args()
    # Inspect only: never pull or replace a Docker image on this shared host.
    image_id = command("docker", "image", "inspect", "--format", "{{.Id}}", args.image).strip()
    result = {"image": args.image, "docker_image_id": image_id,
              "checks": [exercise(args.image, args.baseline, False), exercise(args.image, args.fixed, True)],
              "limits": ["Synthetic equal-length static fixtures; no API, database or browser interaction",
                         "Disposable loopback containers only; production deployment unchanged"]}
    print(json.dumps(result, indent=2))
