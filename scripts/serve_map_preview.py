"""Serve a local Flutter preview without retaining an older build in cache."""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class PreviewHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8880)
    parser.add_argument(
        "--directory",
        default=str(Path(__file__).resolve().parents[1] / "next/apps/quiz_app/build/web"),
    )
    args = parser.parse_args()
    handler = partial(PreviewHandler, directory=args.directory)
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
