"""Run the existing immutable API and Flutter build with local-only media fixtures."""
from pathlib import Path
import hashlib, http.server, json, os, re, socket, subprocess, threading, time
import urllib.request, urllib.error

ROOT = Path(__file__).resolve().parents[4]
WORK = ROOT / '.run/flutter_flags_20261017_0916'
WEB = ROOT / '.run/nvn_footer_20261016/qa-web'
API = ROOT / '.run/country483_runtime_20261015/fixture/qa-api.exe'
BANK = ROOT / '.run/deploy-practice/next/content/prep-flags-world'
FLAGS = ROOT / '.run/flags-pilot'
DB = WORK / 'flags-qa.sqlite'
assert not DB.exists(), 'never reuse a local identity database'
assert hashlib.sha256(API.read_bytes()).hexdigest() == '28995a288b5c2c27ae5740b4e36f25a87f3c5a3cd8b1b028fc5004cf226450f0'
assert WEB.is_dir() and BANK.is_dir()

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB), **kwargs)

    def proxy(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', '0'))) if self.command == 'POST' else None
        headers = {k: v for k, v in self.headers.items() if k.lower() in ['authorization', 'content-type']}
        request = urllib.request.Request('http://127.0.0.1:19093' + self.path, data=body, headers=headers, method=self.command)
        try:
            response = urllib.request.urlopen(request, timeout=15)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            raw = response.read()
            self.send_response(response.code)
            self.send_header('Content-Type', response.headers.get('Content-Type', 'application/json'))
            self.send_header('Content-Length', str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)
        with (WORK / 'requests.jsonl').open('a', encoding='utf-8') as stream:
            stream.write(json.dumps({'method': self.command, 'path': self.path, 'status': response.code}) + '\n')

    def do_GET(self):
        if self.path.startswith(('/v1/', '/health/')):
            return self.proxy()
        media = re.fullmatch(r'/qa-media/(broken|restored)/([a-f0-9]{64})\.png', self.path)
        if media:
            mode, digest = media.groups()
            raw = (WORK / 'broken.html').read_bytes() if mode == 'broken' else (FLAGS / (digest + '.png')).read_bytes()
            mime = 'text/html' if mode == 'broken' else 'image/png'
            if mode == 'restored':
                assert hashlib.sha256(raw).hexdigest() == digest
            self.send_response(200)
            self.send_header('Content-Type', mime)
            self.send_header('Content-Length', str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)
            with (WORK / 'media.jsonl').open('a', encoding='utf-8') as stream:
                stream.write(json.dumps({'mode': mode, 'requested_sha256': digest, 'body_sha256': hashlib.sha256(raw).hexdigest(), 'mime': mime, 'status': 200}) + '\n')
            return
        if self.path.split('?')[0].startswith('/quiz/'):
            self.path = '/index.html'
        return super().do_GET()

    def do_POST(self):
        assert self.path.startswith('/v1/')
        return self.proxy()

    def log_message(self, *args):
        pass

server = http.server.ThreadingHTTPServer(('127.0.0.1', 19090), Handler)
with socket.socket() as probe:
    probe.bind(('127.0.0.1', 19093))
env = os.environ.copy()
env.update(QM_LISTEN_ADDR='127.0.0.1:19093', QM_DATABASE_URL='sqlite:' + DB.as_posix(), QM_CONTENT_BUNDLE_PATH=str(BANK / 'bundle.json'), QM_CONTENT_MANIFEST_PATH=str(BANK / 'manifest.json'), QM_CONTENT_TAXONOMY_PATH='metadata/tags.v1.json')
env.pop('QM_FEEDBACK_ADMIN_TOKEN', None)
with (WORK / 'api.log').open('w') as log:
    api = subprocess.Popen([str(API)], cwd=ROOT, env=env, stdout=log, stderr=log, creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        deadline = time.monotonic() + 30
        while True:
            assert api.poll() is None, 'owned API exited; inspect api.log'
            try:
                with urllib.request.urlopen('http://127.0.0.1:19093/health/ready', timeout=2):
                    break
            except urllib.error.URLError:
                assert time.monotonic() < deadline
                time.sleep(.2)
        with urllib.request.urlopen('http://127.0.0.1:19093/v1/catalog?quiz_id=prep-flags-world') as response:
            catalog = json.load(response)
        assert len(catalog['quiz']['questions']) == 195
        assert not any('grading' in q for q in catalog['quiz']['questions'])
        (WORK / 'local-catalog.json').write_text(json.dumps(catalog, ensure_ascii=False), encoding='utf-8')
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        print('Owned Flutter QA ready at http://127.0.0.1:19090', flush=True)
        input()
        server.shutdown()
        thread.join()
    finally:
        server.server_close()
        api.terminate()
        code = api.wait(timeout=10)
        (WORK / 'cleanup.json').write_text(json.dumps({'api_pid': api.pid, 'api_exit': code, 'intentional_stop': True}), encoding='utf-8')
