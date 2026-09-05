# Engineering Runtime Releases

This repository is the public home for Engineering Runtime releases,
installation, Discussions and issue reporting. Runtime source is maintained
privately; the binaries and checksums published here are public.

<!-- latest-release:start -->
## Latest release — v0.9.7

Published **2026-09-05**. [Open the full GitHub release](https://github.com/engineeringruntime/engineering-runtime-releases/releases/tag/v0.9.7) or read the [technical release notes](https://docs.engineeringruntime.com/release-notes/).

**What changed:** A Community Runtime can now enroll into an Enterprise Control Plane without changing binaries or weakening local governance.

| Platform | Architecture | Archive |
|---|---|---|
| Linux | amd64 | [`engineering-runtime-v0.9.7-linux-amd64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/engineering-runtime-v0.9.7-linux-amd64.tar.gz) |
| Linux | arm64 | [`engineering-runtime-v0.9.7-linux-arm64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/engineering-runtime-v0.9.7-linux-arm64.tar.gz) |
| macOS | amd64 | [`engineering-runtime-v0.9.7-darwin-amd64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/engineering-runtime-v0.9.7-darwin-amd64.tar.gz) |
| macOS | arm64 | [`engineering-runtime-v0.9.7-darwin-arm64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/engineering-runtime-v0.9.7-darwin-arm64.tar.gz) |
| Windows | amd64 | [`engineering-runtime-v0.9.7-windows-amd64.zip`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/engineering-runtime-v0.9.7-windows-amd64.zip) |
| Windows | arm64 | [`engineering-runtime-v0.9.7-windows-arm64.zip`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/engineering-runtime-v0.9.7-windows-arm64.zip) |

[Verify every archive with `SHA256SUMS.txt`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.7/SHA256SUMS.txt).
<!-- latest-release:end -->

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
| `VERSION=<release-tag>` | Install a specific tag instead of the latest, for example `v0.9.6` |
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
`engineering-runtime-<version>-darwin-arm64/`) containing the `runtime` binary —
not a bare `./runtime`.

Windows is not covered by the installer: download the `.zip` from the
[latest release][latest] and put `runtime.exe` on your `PATH`.

## Contents

- Versioned Runtime binaries
- Release notes
- SHA256 checksums
- `install.sh`

## Project links

- [Product website](https://engineeringruntime.com/)
- [Technical documentation](https://docs.engineeringruntime.com/)
- [GitHub Discussions](https://github.com/orgs/engineeringruntime/discussions)
- [Report an Issue](https://github.com/engineeringruntime/engineering-runtime-releases/issues)
- [Report a security concern](mailto:support@engineeringruntime.com?subject=Security%20report)

## Public artifacts, private source

The **artifacts** published here are public so that anyone — or their AI
assistant — can install and run the runtime without credentials. The Engineering
Runtime **source** repository is maintained separately and remains **private**.
A public artifact is not open source.

[latest]: https://github.com/engineeringruntime/engineering-runtime-releases/releases/latest
