"""Unlink only frozen, hash-verified old package files after off-server copying."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import os
import re
import stat

ROOT = PurePosixPath('/opt/quiz-master/releases')
PROTECTED = {
    'quiz-2026.10.14-library-09b19cc.tar.gz',
    'quiz-2026.10.14-reader-17be4ce.tar.gz',
    'quiz-2026.10.15-reader-06dfa0b.tar.gz',
    'quiz-2026.10.15-actors-d204f9b.tar.gz',
}
PATTERN = re.compile(r'quiz-2026[.]10[.](0[2-9]|1[0-4])-[a-z0-9-]+-[0-9a-f]{7}[.]tar[.]gz')


def marker(st):
    return (st.st_dev, st.st_ino, st.st_size, st.st_mtime_ns)


def verify(entry, root):
    logical = PurePosixPath(entry['path'])
    assert logical.parent == ROOT and logical.name not in PROTECTED
    assert PATTERN.fullmatch(logical.name) and str(logical) == entry['path']
    assert re.fullmatch('[0-9a-f]{64}', entry['sha256']) and entry['size'] > 0
    path = root / logical.name
    assert not path.is_symlink()
    before = path.lstat()
    assert stat.S_ISREG(before.st_mode)
    expected = (entry['dev'], entry['ino'], entry['size'], entry['mtime_ns'])
    assert marker(before) == expected
    fd = os.open(path, os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0))
    with os.fdopen(fd, 'rb') as stream:
        assert marker(os.fstat(stream.fileno())) == expected
        assert hashlib.file_digest(stream, 'sha256').hexdigest() == entry['sha256']
        assert marker(os.fstat(stream.fileno())) == expected
    assert marker(path.lstat()) == expected and not path.is_symlink()
    return path


def remove_verified(entries, root=Path(str(ROOT))):
    assert entries and len({e['path'] for e in entries}) == len(entries)
    root = Path(root)
    assert root.is_dir() and not root.is_symlink() and root.resolve() == root.absolute()
    # Validate every file before removing any, then recheck at each unlink.
    for entry in entries:
        verify(entry, root)
    removed = []
    for entry in entries:
        path = verify(entry, root)
        path.unlink()
        removed.append(entry['path'])
        print(json.dumps({'removed': entry['path'], 'bytes': entry['size']}), flush=True)
    return removed
