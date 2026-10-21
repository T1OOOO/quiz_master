import tarfile
import unittest
import linux_restore_probe as p


class RestoreSafetyTest(unittest.TestCase):
    def test_remote_program_compiles(self):
        compile(p.REMOTE, '<bounded-linux-restore>', 'exec')

    def test_member_paths_and_unsupported_types_fail_closed(self):
        for name in ('/etc/passwd', 'release/../escape', 'other/file'):
            with self.subTest(name=name), self.assertRaises(ValueError):
                p.member_path(tarfile.TarInfo(name), 'release')
        for kind in (tarfile.LNKTYPE, tarfile.FIFOTYPE, tarfile.CHRTYPE):
            item = tarfile.TarInfo('release/file')
            item.type = kind
            with self.assertRaises(ValueError):
                p.member_path(item, 'release')
        self.assertEqual(p.member_path(tarfile.TarInfo('release/file'), 'release'), 'file')

    def test_file_budget_refuses_an_oversized_single_entry(self):
        item = tarfile.TarInfo('release/large')
        item.size = p.MAX_FILE_BYTES + 1
        with self.assertRaises(ValueError):
            p.member_path(item, 'release')

    def test_directory_size_is_not_a_portable_metadata_constraint(self):
        entry = dict(path='.', type='dir', mode=0o750, uid=0, gid=0,
                     mtime_ns=123, xattrs={}, size=4096)
        self.assertNotIn('size', p.projection(entry))
        entry.update(type='file', sha256='a' * 64)
        self.assertEqual(p.projection(entry)['size'], 4096)


if __name__ == '__main__':
    unittest.main()
