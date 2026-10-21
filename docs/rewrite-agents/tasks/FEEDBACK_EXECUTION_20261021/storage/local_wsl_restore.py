#!/usr/bin/env python3
"""Transport the frozen bounded Linux restore verifier into an owned WSL2 distro."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import pathlib
import shutil
import subprocess

DESTINATION = pathlib.Path('E:/Backups/quiz-master/server-20261021').resolve()
BASE_PATH = pathlib.Path(__file__).resolve().with_name('linux_restore_probe.py')
FROZEN_BASE = DESTINATION / 'controller-source/linux_restore_probe-v1.py'
BASE_SHA = '9fc8086461f673e5720055cee6eeb0478494433d63e759a5f242539f97df0dc6'
DISTRO = 'QuizArchiveVerify21'


def digest(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def load_base():
    if digest(BASE_PATH) != BASE_SHA or digest(FROZEN_BASE) != BASE_SHA:
        raise ValueError('frozen base verifier differs')
    spec = importlib.util.spec_from_file_location('frozen_linux_restore_probe', BASE_PATH)
    base = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(base)
    old_assertion = "assert socket.gethostname()=='racknerd-f0269d5'"
    new_assertions = (
        "assert os.environ.get('WSL_DISTRO_NAME')=='QuizArchiveVerify21'\n"
        "assert 'microsoft-standard-WSL2' in os.uname().release"
    )
    if base.REMOTE.count(old_assertion) != 1:
        raise ValueError('base hostname assertion replacement is not exact')
    base.REMOTE = base.REMOTE.replace(old_assertion, new_assertions, 1)
    old_result = "'hostname':socket.gethostname(),'scratch_fstype':'tmpfs'"
    new_result = (
        "'hostname':socket.gethostname(),'wsl_distro':os.environ.get('WSL_DISTRO_NAME'),"
        "'kernel_release':os.uname().release,'scratch_fstype':'tmpfs'"
    )
    if base.REMOTE.count(old_result) != 1:
        raise ValueError('base proof output replacement is not exact')
    base.REMOTE = base.REMOTE.replace(old_result, new_result, 1)
    return base


def local_send(base, chunk: pathlib.Path, entries: list[dict], basename: str) -> dict:
    request = {'entries': entries, 'basename': basename,
               'logical_bytes': sum(e['size'] for e in entries if e['type'] == 'file')}
    child = subprocess.Popen(
        ['wsl.exe', '-d', DISTRO, '-u', 'root', '--', 'python3', '-c', base.REMOTE],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    try:
        assert child.stdin is not None
        child.stdin.write(json.dumps(request, separators=(',', ':')).encode() + b'\n')
        with chunk.open('rb') as stream:
            shutil.copyfileobj(stream, child.stdin, 1024 * 1024)
        child.stdin.close()
        child.stdin = None
        out, err = child.communicate(timeout=360)
    except BaseException:
        child.kill()
        child.wait(timeout=15)
        raise
    if child.returncode:
        raise RuntimeError('local Linux restore refused: ' + err.decode(errors='replace')[-2500:])
    result = json.loads(out)
    wanted = sorted((base.projection(e) for e in entries), key=lambda x: x['path'])
    expected = hashlib.sha256(json.dumps(wanted, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    if (result.get('verdict') != 'ACCEPT' or result.get('entry_count') != len(entries)
            or result.get('restored_sha256') != expected or result.get('scratch_cleaned') is not True
            or result.get('wsl_distro') != DISTRO
            or 'microsoft-standard-WSL2' not in result.get('kernel_release', '')):
        raise ValueError('local Linux proof differs from frozen verifier requirements')
    return dict(result, chunk_sha256=digest(chunk), expected_sha256=expected,
                transport='wsl2', base_verifier_sha256=BASE_SHA)


def verify(archive: pathlib.Path, manifest: pathlib.Path, receipt: pathlib.Path) -> dict:
    for p in (archive, manifest, receipt):
        if not p.resolve().is_relative_to(DESTINATION):
            raise ValueError('evidence must remain under persistent backup root')
    base = load_base()
    original = base.send_chunk
    base.send_chunk = lambda chunk, entries, basename: local_send(base, chunk, entries, basename)
    try:
        return base.verify(pathlib.Path(archive), pathlib.Path(manifest), pathlib.Path(receipt))
    finally:
        base.send_chunk = original


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', required=True, type=pathlib.Path)
    parser.add_argument('--manifest', required=True, type=pathlib.Path)
    parser.add_argument('--receipt', required=True, type=pathlib.Path)
    a = parser.parse_args()
    print(json.dumps({k: v for k, v in verify(a.archive, a.manifest, a.receipt).items() if k != 'chunks'}, sort_keys=True))


if __name__ == '__main__':
    main()
