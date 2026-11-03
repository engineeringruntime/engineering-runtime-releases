# Public demo release data

The demo reads a small public JSON catalog on page reload. Releases stay the
source of truth; the browser never runs the Runtime binary.

## Automatic update

`publish-demo-catalog.yml` runs after stable release publication/edits, on changes
to its publisher/generator on main, and by manual dispatch for recovery/backfill.
It always resolves actual stable Latest, verifies the published Linux amd64 archive
against SHA256SUMS.txt, checks version and unmodified build metadata, and extracts
provider metadata plus exact `engrt config init config` and `policy` output in an
isolated Home with no inherited provider credentials.

Only derived public JSON is written to `demo/latest.json` on the `demo-data` branch.
No binary or release asset is changed, and this does not authorize new releases.
The publication job has write permission; the binary-extraction job has read-only
permission. No additional token is needed. The branch must permit this workflow's
normal contents write; do not bypass repository rules if it is blocked.

Feed: https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/demo-data/demo/latest.json

## Activate and recover

Merge the demo reader and this workflow. The main-branch workflow-file change
backfills current Latest automatically. Check the Actions result, then reload
https://demo.engineeringruntime.com/ and inspect Source details on Providers,
Policies or Configurations. The tag must match stable Latest.

For a failed download, incomplete asset upload, generation failure or interrupted
publication, fix the cause and run `Publish public demo catalog` manually on main.
The old feed remains available. The browser reports saved defaults if feed and
Latest do not match. No periodic browser polling is used.

An immutable release published using the existing cross-repository
RELEASES_REPO_TOKEN triggers release events. If publishing changes to GITHUB_TOKEN,
explicitly dispatch this workflow after publishing; token-generated events generally
do not start new workflows. Verify this when changing release authentication.

## Contract

Catalog schema 2 includes `provenance.runtime`, `providers`, `compiled_defaults`
and `generated_at`. Each default has command, SHA-256 and exact YAML. No capability
list is included: capabilities follow their own public repository independently.
The demo's initial bundled fallback was generated from stable v0.13.0.

New defaults, supported schema numbers, provider names and operation counts can
flow automatically. A new catalog contract or new UI functionality requires a
reviewed reader change; publishing metadata cannot implement new features.

Run `python3 scripts/test-demo-catalog.py`. The generator can also be run locally:

```sh
python3 scripts/generate-demo-catalog.py \
  --archive /path/to/engrt-vX.Y.Z-linux-amd64.tar.gz \
  --checksums /path/to/SHA256SUMS.txt --tag vX.Y.Z --output /tmp/latest.json
```
