"""Read-only deployment admission; run on the server before image preparation."""
import json
import shutil
import subprocess
import urllib.request


def validate(nodes, total, available):
    assert nodes['items'], 'No nodes returned'
    for node in nodes['items']:
        conditions = {c['type']: c['status'] for c in node['status']['conditions']}
        assert conditions.get('Ready') == 'True', 'Node is not Ready'
        assert conditions.get('DiskPressure') == 'False', 'Node has DiskPressure'
        assert not any(t['key'] == 'node.kubernetes.io/disk-pressure'
                       for t in node['spec'].get('taints', [])), 'Disk pressure taint remains'
    # Keep five percentage points above the usual 15% imagefs eviction threshold.
    assert available >= max(total // 5, 4_000_000_000), 'Insufficient disk headroom'


if __name__ == '__main__':
    nodes = json.loads(subprocess.check_output(['kubectl', 'get', 'nodes', '-o', 'json']))
    usage = shutil.disk_usage('/var/lib/rancher/k3s/agent/containerd')
    validate(nodes, usage.total, usage.free)
    with urllib.request.urlopen('https://quiz.kotopedia.org/health/ready', timeout=15) as response:
        assert response.status == 200 and response.read() == b'', 'API readiness failed'
    print(json.dumps({'disk_guard': 'PASS', 'total': usage.total, 'available': usage.free}))
