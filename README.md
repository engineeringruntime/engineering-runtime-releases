# Engineering Runtime Releases

[![Latest release](https://img.shields.io/github/v/release/engineeringruntime/engineering-runtime-releases?label=engrt)](https://github.com/engineeringruntime/engineering-runtime-releases/releases/latest)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-blue)](#install)
[![Windows installer](https://github.com/engineeringruntime/engineering-runtime-releases/actions/workflows/windows-installer.yaml/badge.svg?branch=main)](https://github.com/engineeringruntime/engineering-runtime-releases/actions/workflows/windows-installer.yaml)

Engineering Runtime is a single binary, `engrt`, for governed engineering
operations. This repository is where its releases are published: archives for
macOS, Linux and Windows on `amd64` and `arm64`, each with `SHA256SUMS.txt`.
Downloads are public and need no GitHub account.

<!-- latest-release:start -->
## Latest release — v0.13.0

Published **2026-10-21**. Read the [technical release notes](https://docs.engineeringruntime.com/release-notes/).

**What changed:** Destructive effects are refused on every transport, and every refusal says why — truthfully.

| Platform | Architecture | Archive |
|---|---|---|
| Linux | amd64 | `engrt-v0.13.0-linux-amd64.tar.gz` |
| Linux | arm64 | `engrt-v0.13.0-linux-arm64.tar.gz` |
| macOS | amd64 | `engrt-v0.13.0-darwin-amd64.tar.gz` |
| macOS | arm64 | `engrt-v0.13.0-darwin-arm64.tar.gz` |
| Windows | amd64 | `engrt-v0.13.0-windows-amd64.zip` |
| Windows | arm64 | `engrt-v0.13.0-windows-arm64.zip` |

Verify your archive with `SHA256SUMS.txt`. For release access, [contact the project](https://engineeringruntime.com/contact/).
<!-- latest-release:end -->

## Install

Pick one way. Each one verifies the archive against the release's
`SHA256SUMS.txt` before installing, and installs only `engrt`.

### Homebrew (macOS and Linux)

```bash
brew install engineeringruntime/tap/engineering-runtime
engrt version
```

Upgrade with `brew update && brew upgrade engineeringruntime/tap/engineering-runtime`. Use the full name: Homebrew 7
refuses a short name from a third-party tap until it is trusted, and naming the
formula in full trusts it.

### Install script (macOS and Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.sh | sh
engrt version
```

The script detects your OS and architecture, downloads the archive and
`SHA256SUMS.txt` from the latest release, stops without installing anything if
the checksum does not match, and installs `engrt` in `/usr/local/bin` when that
is writable, otherwise in `~/.local/bin`. It needs `curl`, `tar` and `shasum`
or `sha256sum`.

- Set `VERSION` to an explicit tag from [published releases](https://github.com/engineeringruntime/engineering-runtime-releases/releases) when you need a reproducible, pinned install (v0.10.0 or later). Omit it for the latest published release.
- `INSTALL_DIR=/path` installs into that directory.

```bash
curl -fsSL https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.sh \
  | INSTALL_DIR="$HOME/.local/bin" sh
```

If it prints `NOTE: … is not on your PATH`, add that directory to your shell
profile and open a new terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### By hand (macOS and Linux)

Run this in an empty directory. Select the exact published tag from the
[releases page](https://github.com/engineeringruntime/engineering-runtime-releases/releases/latest)
first: manual installs intentionally pin a version so the archive and checksum
refer to the same release. The commands detect your OS and architecture:

```bash
VERSION=vX.Y.Z                  # replace with an actual published tag
OS=$(uname -s | tr '[:upper:]' '[:lower:]')                        # darwin or linux
ARCH=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')  # amd64 or arm64
NAME=engrt-$VERSION-$OS-$ARCH
BASE=https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/$VERSION

curl -fsSLO "$BASE/$NAME.tar.gz"
curl -fsSLO "$BASE/SHA256SUMS.txt"
grep "$NAME.tar.gz" SHA256SUMS.txt | shasum -a 256 -c -     # Linux without shasum: sha256sum -c -
tar -xzf "$NAME.tar.gz"
mkdir -p ~/.local/bin && install -m 0755 "$NAME/engrt" ~/.local/bin/engrt
export PATH="$HOME/.local/bin:$PATH"                         # add this line to ~/.zshrc or ~/.bashrc
engrt version
```

The checksum line must print `$NAME.tar.gz: OK` for your selected release. If it
prints `FAILED`, stop and download again: the archive is not the published one.

### Windows (PowerShell 7, x64 or Arm64)

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.ps1 -OutFile install.ps1
./install.ps1
$env:PATH = "$HOME\.local\bin;$env:PATH"
engrt version
```

The script selects x64 or Arm64, verifies the ZIP checksum and the executable's
version, and installs only `engrt.exe` in `%USERPROFILE%\.local\bin`. Add that
directory to your **user PATH** for new terminals; the script does not change
it. Options: `-Version <published-tag>`, `-InstallDirectory C:\Tools\engrt`, and for
an offline install `-Version <tag> -ArchiveDirectory <folder>` with the ZIP and
`SHA256SUMS.txt` in that folder.

By hand: download `engrt-<version>-windows-<amd64|arm64>.zip` and
`SHA256SUMS.txt` from the release, check that `Get-FileHash <zip>` matches the
ZIP's line, extract it and put `engrt.exe` on your `PATH`.

## Next: run your first capability

Installing gives you the binary; capabilities are what it runs.
[engineering-runtime-capabilities](https://github.com/engineeringruntime/engineering-runtime-capabilities#quick-start-from-install-to-your-first-run)
takes you from here to a first run in a few minutes: `git` and `gh`, a sample
`config.yaml` and `policy.yaml`, GitHub authority, and running a read-only
capability with `validate`, `plan` and `execute`.

Runtime creates its home (`~/.engrt`) on the first command you run. It does
not create a policy for you: until you supply one, the safety profile compiled
into the binary governs.

## Supported platforms

From v0.10.0: macOS, Linux and Windows, each on `amd64` and `arm64`. The
installers support v0.10.0 and later only.

Releases before v0.10.0 ship a `runtime` binary in `engineering-runtime-*`
archives. The installers refuse them and change nothing; install an older
release by hand, in a separate directory and Runtime Home. Upgrading from
`runtime` to `engrt`: follow the
[upgrade guide](https://docs.engineeringruntime.com/get-started/upgrading/) to
update environment variables and keep your earlier Runtime Home. The installers
neither remove `runtime` nor create a `runtime` alias.

## Help

Report a problem with `engrt` in [this repository's issues](https://github.com/engineeringruntime/engineering-runtime-releases/issues/new/choose),
and a problem with a capability in
[engineering-runtime-capabilities](https://github.com/engineeringruntime/engineering-runtime-capabilities/issues/new/choose).
Ask questions in [Discussions → Q&A](https://github.com/orgs/engineeringruntime/discussions/categories/q-a) and share ideas in
[Discussions → Ideas](https://github.com/orgs/engineeringruntime/discussions/categories/ideas). Report security vulnerabilities privately with
[Report a vulnerability](https://github.com/engineeringruntime/engineering-runtime-releases/security/advisories/new)
or by email to support@engineeringruntime.com, never in a public issue; see
[SECURITY.md](SECURITY.md).
See [CONTRIBUTING.md](CONTRIBUTING.md).

[Installation guide](https://docs.engineeringruntime.com/get-started/installation/) ·
[Release notes](https://docs.engineeringruntime.com/release-notes/) ·
[Community](https://github.com/orgs/engineeringruntime/discussions) ·
[Report an issue](https://github.com/engineeringruntime/engineering-runtime-releases/issues) ·
[Contact](https://engineeringruntime.com/contact/)

## Licence and source

Engineering Runtime is **proprietary software**. Its source code is maintained
separately and is private; publishing compiled releases does **not** make it
open source. Use of the binaries is subject to the terms in
[`LICENSE`](./LICENSE). No binaries or checksums are committed to this
repository; they are GitHub Release assets.
