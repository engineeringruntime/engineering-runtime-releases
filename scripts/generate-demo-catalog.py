#!/usr/bin/env python3
"""Extract public demo metadata from a checksum-verified stable release binary."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
import tempfile
from datetime import datetime, timezone

SOURCE = 'engineeringruntime/engineering-runtime-releases'

def digest(raw):
    return hashlib.sha256(raw).hexdigest()

def verified_binary(archive, checksums, tag, destination):
    name = f'engrt-{tag}-linux-amd64.tar.gz'
    if archive.name != name:
        raise ValueError('unexpected archive name')
    matches = [line.split() for line in checksums.read_text().splitlines()
               if len(line.split()) == 2 and line.split()[1].lstrip('*') == name]
    if len(matches) != 1 or not re.fullmatch('[0-9a-f]{64}', matches[0][0]) or digest(archive.read_bytes()) != matches[0][0]:
        raise ValueError('archive checksum missing, duplicate or mismatched')
    expected = f'engrt-{tag}-linux-amd64/engrt'
    with tarfile.open(archive, 'r:gz') as tar:
        members = tar.getmembers()
        for item in members:
            path = PurePosixPath(item.name)
            if path.is_absolute() or '..' in path.parts or not (item.isfile() or item.isdir()):
                raise ValueError('unsafe archive member')
        binaries = [m for m in members if m.name == expected and m.isfile()]
        if len(binaries) != 1 or binaries[0].size > 200_000_000:
            raise ValueError('expected exactly one bounded Runtime executable')
        output = destination / 'engrt'
        output.write_bytes(tar.extractfile(binaries[0]).read())
        output.chmod(0o700)
    return output, matches[0][0]

def generate(archive, checksums, tag):
    if not re.fullmatch(r'v\d+\.\d+\.\d+', tag):
        raise ValueError('only stable version tags are supported')
    with tempfile.TemporaryDirectory(prefix='engrt-demo-') as scratch:
        root = Path(scratch)
        binary, archive_hash = verified_binary(archive, checksums, tag, root)
        home = root / 'home'
        home.mkdir()
        # No inherited credentials/configuration. Only explicit local CLI calls.
        env = {'PATH': os.environ.get('PATH', '/usr/bin:/bin'), 'HOME': str(home),
               'ENGRT_HOME': str(home), 'RUNTIME_HOME': str(home), 'LANG': 'C.UTF-8'}
        def run(*args):
            result = subprocess.run([str(binary), *args], env=env, cwd=root,
                                    capture_output=True, text=True, timeout=60, check=True)
            return result.stdout
        version = run('version').strip()
        if not re.match(r'^engrt\s+' + re.escape(tag[1:]) + r'(?:\s|$)', version):
            raise ValueError('binary version does not match stable release')
        manifest = json.loads((home / 'manifest.json').read_text())
        if manifest.get('runtime_version') != tag[1:] or manifest.get('runtime_modified', False) is not False:
            raise ValueError('manifest must match an unmodified stable release')
        providers = []
        seen = set()
        for item in manifest.get('providers', []):
            key = item.get('id', '')
            if not re.fullmatch('[a-zA-Z0-9_-]+', key) or key in seen:
                raise ValueError('invalid or duplicate provider')
            seen.add(key)
            count = item.get('operations', 0)
            if type(count) is not int or count < 0:
                raise ValueError('invalid operation count')
            providers.append({'id': key, 'name': item.get('name') or key,
                              'auth': item.get('auth') or '', 'operations': count,
                              'status': 'available', 'scope': 'Released Runtime', 'capabilities': 0})
        if not providers:
            raise ValueError('empty provider manifest')
        defaults = {}
        for surface in ('config', 'policy'):
            output = root / (surface + '.yaml')
            run('config', 'init', surface, '--output', str(output))
            raw = output.read_bytes()
            if len(raw) > 1_000_000 or not re.search(rb'^schema_version:\s*\d+\s*$', raw, re.M):
                raise ValueError('invalid default document')
            defaults[surface] = {'command': f'engrt config init {surface} --output ./{output.name}',
                                 'sha256': digest(raw), 'yaml': raw.decode()}
        payload = {'schema_version': 2, 'generated_at': datetime.now(timezone.utc).isoformat(),
                   'provenance': {'runtime': {'source': SOURCE, 'ref': tag, 'version': tag[1:],
                      'commit': manifest.get('runtime_commit', ''), 'modified': False,
                      'archive': archive.name, 'archive_sha256': archive_hash}},
                   'providers': providers, 'compiled_defaults': defaults}
        return payload

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--archive', type=Path, required=True)
    p.add_argument('--checksums', type=Path, required=True)
    p.add_argument('--tag', required=True)
    p.add_argument('--output', type=Path, required=True)
    args = p.parse_args()
    catalog = generate(args.archive, args.checksums, args.tag)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(catalog, indent=2) + '\n')
    print(f'Generated public demo defaults for {args.tag}')
