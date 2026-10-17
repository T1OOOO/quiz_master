"""Serve only the task's isolated public media on loopback; stdin closes it."""
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import json
import threading

ROOT = Path(__file__).resolve().parents[4]
WEB = ROOT / ".run/flags_browser_20261017_0640/web"
assert WEB.is_dir() and len(list((WEB / "flags").glob("*.png"))) == 195
server = ThreadingHTTPServer(("127.0.0.1", 0), partial(SimpleHTTPRequestHandler, directory=str(WEB)))
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
print(json.dumps({"url": "http://127.0.0.1:" + str(server.server_port), "scope": "isolated_public_media_only"}), flush=True)
try:
    input()
finally:
    server.shutdown()
    server.server_close()
    thread.join()
