"""Online backup + isolated restore check of the verified quiz PVC only."""
import pathlib
import sqlite3
import sys

source = pathlib.Path('/var/lib/rancher/k3s/storage/pvc-7fc2428f-4146-4c78-a26d-2347d9f3b7bf_quiz-master_quiz-data/quiz.db')
destination = pathlib.Path(sys.argv[1]).resolve()
assert source.is_file() and not source.is_symlink()
assert destination.parent == pathlib.Path('/opt/quiz-master/backups')
assert not destination.exists()
destination.touch(mode=0o600, exist_ok=False)
with sqlite3.connect(source.as_uri() + '?mode=ro', uri=True) as live, sqlite3.connect(destination) as backup:
    live.backup(backup)
    assert backup.execute('pragma integrity_check').fetchone() == ('ok',)
    expected = [backup.execute('select count(*) from ' + table).fetchone()[0]
                for table in ('participants', 'attempts', 'attempt_bundles')]
    # An independent restored DB, not merely a copy of the live file or WAL.
    restored_path = destination.with_suffix('.restore-proof.sqlite')
    restored_path.touch(mode=0o600, exist_ok=False)
    with sqlite3.connect(restored_path) as restored:
        backup.backup(restored)
        assert restored.execute('pragma integrity_check').fetchone() == ('ok',)
        actual = [restored.execute('select count(*) from ' + table).fetchone()[0]
                  for table in ('participants', 'attempts', 'attempt_bundles')]
        assert actual == expected
print({'backup': str(destination), 'integrity': 'ok', 'restore': 'ok', 'counts': expected})
