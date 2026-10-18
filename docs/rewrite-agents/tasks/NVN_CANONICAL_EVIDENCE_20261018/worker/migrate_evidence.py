"""Write the one fixed evidence migration; never execute a captured command."""
import copy
import json
from pathlib import Path
import verify_historical as v


def save(path, record):
    path.write_bytes((json.dumps(record, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))


def migrate():
    n, original, runtime = v.historical()
    v.require(not v.EVIDENCE.exists() and not v.EVIDENCE.is_symlink()
              and not v.EVIDENCE.is_junction(), 'migration destination must not exist')
    v.require(v.PACKET == v.PACKET.resolve() and v.PACKET.is_dir()
              and all(not p.is_symlink() and not p.is_junction() for p in (v.PACKET, *v.PACKET.parents)),
              'canonical packet root and ancestors required')
    v.EVIDENCE.mkdir()
    known = {v.REPO / relative: entry['sha256'] for relative, entry in original['proofs'].items()}
    known.update({v.REPO / relative: digest for relative, digest in runtime.items()})
    generated = {v.OLD / name for name in ('release-inputs.json', 'runtime-proof.json', 'runtime-evidence-inputs.json')}
    known[v.OLD / 'release-inputs.json'] = v.OLD_INPUT_SHA
    rows = []
    for old, digest in known.items():
        new = v.destination(old)
        v.checked_file(old, digest)
        if new != old and old not in generated:
            new.parent.mkdir(parents=True, exist_ok=True)
            new.write_bytes(old.read_bytes())
        rows.append(dict(old_path=str(old), new_path=str(new), old_raw_byte_sha256=digest,
                         kind='canonical_binding_metadata' if old in generated else 'unchanged_bytes'))
    manifest = {v.destination(v.REPO / relative).relative_to(v.REPO).as_posix(): digest
                for relative, digest in runtime.items()}
    save(v.EVIDENCE / 'runtime-evidence-inputs.json', manifest)
    proof = copy.deepcopy(v.read(v.OLD / 'runtime-proof.json'))
    proof['sha256_semantics'] = 'raw file bytes in all new path/hash bindings'

    def rebind(value):
        if isinstance(value, dict):
            if set(value) == {'path', 'sha256'}:
                old = Path(value['path']).resolve()
                v.require(old in known and known[old] == value['sha256'], 'unknown nested historical binding')
                value['path'] = str(v.destination(old))
                value['sha256'] = v.sha(v.destination(old))
            else:
                for child in value.values():
                    rebind(child)
        elif isinstance(value, list):
            for child in value:
                rebind(child)

    rebind(proof)
    for label in ('production', 'qa'):
        proof['builds'][label]['root'] = str(v.REPO / f'.run/nvn_footer_20261016/{label}-web')
    save(v.EVIDENCE / 'runtime-proof.json', proof)
    inputs = copy.deepcopy(original)
    inputs['sha256_semantics'] = 'raw file bytes in all new path/hash bindings'
    for relative, entry in inputs['proofs'].items():
        entry['path'] = str(v.destination(v.REPO / relative))
        entry['sha256'] = v.sha(entry['path'])
    for label in ('production', 'qa'):
        inputs['web_roots'][label] = str(v.REPO / f'.run/nvn_footer_20261016/{label}-web')
    inputs['prior_archive']['path'] = str(n.BASE_ARCHIVE)
    save(v.EVIDENCE / 'release-inputs.json', inputs)
    for row in rows:
        row['new_raw_byte_sha256'] = v.sha(row['new_path'])
    save(v.EVIDENCE / 'migration-map.json', dict(
        historical_input_raw_sha256=v.OLD_INPUT_SHA,
        scope='historical evidence only; no release acceptance', files=rows,
        fixture_source_hash_note='Original server.py.sha256 is normalized UTF-8 text; raw bytes use the runtime manifest. Old captures remain unchanged.',
    ))
    print(json.dumps({'canonical_input_raw_sha256': v.sha(v.EVIDENCE / 'release-inputs.json'),
                      'mapping_raw_sha256': v.sha(v.EVIDENCE / 'migration-map.json'),
                      'runtime_files': len(manifest), 'logical_direct_pins': len(inputs['proofs'])}, indent=2))


if __name__ == '__main__':
    migrate()
