#!/usr/bin/env python3
"""Publish derived demo metadata on the dedicated demo-data branch only."""
import base64
import hashlib
import json
from pathlib import Path
import subprocess
import sys

REPO = 'engineeringruntime/engineering-runtime-releases'
BRANCH = 'demo-data'
PATH = 'demo/latest.json'

def api(path, method='GET', payload=None, optional=False):
    args = ['gh', 'api', f'repos/{REPO}/{path}', '--method', method]
    if payload is not None:
        args += ['--input', '-']
    result = subprocess.run(args, input=json.dumps(payload) if payload is not None else None,
                            text=True, capture_output=True)
    if result.returncode:
        if optional and '(HTTP 404)' in result.stderr:
            return None
        raise RuntimeError(result.stderr)
    return json.loads(result.stdout) if result.stdout.strip() else None

def main(path):
    raw = Path(path).read_bytes()
    catalog = json.loads(raw)
    runtime = catalog['provenance']['runtime']
    latest = api('releases/latest')
    if latest['draft'] or latest['prerelease'] or latest['tag_name'] != runtime['ref']:
        raise ValueError('Latest changed or is not stable; refusing stale publication')
    if catalog['schema_version'] != 2 or runtime['source'] != REPO or runtime['modified']:
        raise ValueError('invalid catalog source')
    for doc in catalog['compiled_defaults'].values():
        if hashlib.sha256(doc['yaml'].encode()).hexdigest() != doc['sha256']:
            raise ValueError('default hash mismatch')
    ref = api(f'git/ref/heads/{BRANCH}', optional=True)
    if ref is None:
        main_ref = api('git/ref/heads/main')
        api('git/refs', 'POST', {'ref': f'refs/heads/{BRANCH}', 'sha': main_ref['object']['sha']})
    existing = api(f'contents/{PATH}?ref={BRANCH}', optional=True)
    if existing:
        previous = json.loads(base64.b64decode(existing['content']))
        # Generation time is not a data change. Avoid a redundant commit on edited releases.
        if {k:v for k,v in previous.items() if k != 'generated_at'} == {k:v for k,v in catalog.items() if k != 'generated_at'}:
            print('Published catalog already matches Latest')
            return
    if api('releases/latest')['tag_name'] != runtime['ref']:
        raise ValueError('Latest changed before write')
    payload = {'message': f"data: refresh demo defaults for {runtime['ref']}", 'branch': BRANCH,
               'content': base64.b64encode(raw).decode()}
    if existing:
        payload['sha'] = existing['sha']
    api(f'contents/{PATH}', 'PUT', payload)
    print(f"Published demo defaults for {runtime['ref']}")

if __name__ == '__main__':
    main(sys.argv[1])
