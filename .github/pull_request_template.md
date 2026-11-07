## What

<!-- This repository holds the README, LICENSE and the installers (install.sh, install.ps1).
     Binaries and checksums are release assets and are never committed. -->

## How it was tested

<!-- For an installer change: platforms, the release version installed, and the result.
     install.sh: test-install.sh. install.ps1: scripts/test-install.ps1 (the Windows workflow runs it). -->

## Checklist

- [ ] No binaries, archives or checksum files are committed.
- [ ] The generated block between `latest-release:start` and `latest-release:end` is unchanged.
- [ ] Installer changes still verify `SHA256SUMS.txt` and refuse a mismatch.
- [ ] Install commands in the README were run as written.
