# Engineering Runtime Releases

This repository contains the official binary releases for Engineering Runtime.

## Install

### Homebrew (macOS and Linux)

```bash
brew install engineeringruntime/tap/engineering-runtime
"$(brew --prefix)/bin/runtime" version
```

The public [`engineeringruntime/homebrew-tap`](https://github.com/engineeringruntime/homebrew-tap)
formula supports arm64 and amd64 and verifies the release archive checksum.

### Verification script

```bash
curl -fsSL https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.sh | sh
runtime version
```

**No GitHub account or token is required** — the release artifacts here are
public. The installer detects your OS and architecture, verifies the published
SHA256 **before** extracting, and fails closed if it does not match.

| Variable | Effect |
|---|---|
| `VERSION=v0.8.0` | Install a specific tag instead of the latest |
| `INSTALL_DIR=/path` | Install here instead of `/usr/local/bin`, else `~/.local/bin` |

### Exit codes

Distinct on purpose, so an automated caller can branch on them:

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Usage or unexpected internal error |
| `2` | Unsupported platform (OS or architecture) |
| `3` | Required tool missing (`curl`, `tar`, `shasum`/`sha256sum`) |
| `4` | Download failed (release, asset or checksum unreachable) |
| `5` | **Checksum verification failed — nothing is installed** |
| `6` | No writable install directory |

### Manual install

If piping to a shell is not acceptable in your environment, download the
archive and `SHA256SUMS.txt` from the [latest release][latest], verify, then
extract:

```bash
shasum -a 256 -c SHA256SUMS.txt --ignore-missing
```

`--ignore-missing` matters: `SHA256SUMS.txt` covers **all six** archives, so
without it the five you did not download are reported as failures.

The archive expands to a **versioned directory** (for example
`engineering-runtime-v0.8.0-darwin-arm64/`) containing the `runtime` binary —
not a bare `./runtime`.

Windows is not covered by the installer: download the `.zip` from the
[latest release][latest] and put `runtime.exe` on your `PATH`.

## Contents

- Versioned Runtime binaries
- Release notes
- SHA256 checksums
- `install.sh`

Full documentation: <https://docs.engineeringruntime.com>

## Public artifacts, private source

The **artifacts** published here are public so that anyone — or their AI
assistant — can install and run the runtime without credentials. The Engineering
Runtime **source** repository is maintained separately and remains **private**.
A public artifact is not open source.

[latest]: https://github.com/engineeringruntime/engineering-runtime-releases/releases/latest
