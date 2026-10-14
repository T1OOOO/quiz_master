import copy
import unittest
from release_disk_guard import validate


class DiskGuardTests(unittest.TestCase):
    def setUp(self):
        self.nodes = {'items': [{'spec': {}, 'status': {'conditions': [
            {'type': 'Ready', 'status': 'True'},
            {'type': 'DiskPressure', 'status': 'False'}]}}]}

    def test_healthy_headroom(self):
        validate(self.nodes, 100_000_000_000, 20_000_000_000)

    def test_old_four_gigabyte_guard_is_insufficient(self):
        with self.assertRaises(AssertionError):
            validate(self.nodes, 100_000_000_000, 5_000_000_000)

    def test_pressure_not_ready_missing_and_taint(self):
        for kind, value in [('DiskPressure', 'True'), ('Ready', 'False'), ('Ready', 'Unknown')]:
            nodes = copy.deepcopy(self.nodes)
            next(c for c in nodes['items'][0]['status']['conditions'] if c['type'] == kind)['status'] = value
            with self.assertRaises(AssertionError):
                validate(nodes, 100_000_000_000, 30_000_000_000)
        self.nodes['items'][0]['spec']['taints'] = [{'key': 'node.kubernetes.io/disk-pressure'}]
        with self.assertRaises(AssertionError):
            validate(self.nodes, 100_000_000_000, 30_000_000_000)
        with self.assertRaises(AssertionError):
            validate({'items': []}, 100_000_000_000, 30_000_000_000)


if __name__ == '__main__':
    unittest.main()
