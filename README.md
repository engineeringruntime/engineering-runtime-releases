# Engineering Runtime Releases

Engineering Runtime is a single binary for governed engineering operations.
See [Install Runtime](https://docs.engineeringruntime.com/get-started/installation/)
for archive selection, checksum verification and installation.

## v0.10.0 candidate distribution preparation

v0.10.0 is not released. Its intended archives are `engrt-v0.10.0-<os>-<arch>`:
macOS/Linux use `.tar.gz`; Windows amd64/arm64 use `.zip`. Each contains a
versioned directory with `engrt` or `engrt.exe`. The candidate shell installer
installs only `engrt` on macOS/Linux, retaining an existing `runtime` executable
without creating an alias. Windows installation is manual after verifying the
unique matching archive checksum; use `Get-Command engrt -All` to verify PATH.

This branch's installer must ship together with the qualified v0.10.0 release;
it is not the installer for the current stable v0.9.9 archives below. Keep the
candidate branch unpublished until native six-platform qualification and owner
publication approval. See the [candidate Windows instructions](https://docs.engineeringruntime.com/get-started/installation/#v0100-windows-candidate-preparation)
when the matching documentation is published. No binaries or generated release
metadata are committed by this preparation.

<!-- latest-release:start -->
## Latest release — v0.9.9

Published **2026-09-23**. Read the [technical release notes](https://docs.engineeringruntime.com/release-notes/).

**What changed:** Engineering Runtime v0.9.9 provides governed execution hardening for macOS and Linux.

| Platform | Architecture | Archive |
|---|---|---|
| Linux | amd64 | `engineering-runtime-v0.9.9-linux-amd64.tar.gz` |
| Linux | arm64 | `engineering-runtime-v0.9.9-linux-arm64.tar.gz` |
| macOS | amd64 | `engineering-runtime-v0.9.9-darwin-amd64.tar.gz` |
| macOS | arm64 | `engineering-runtime-v0.9.9-darwin-arm64.tar.gz` |

Verify your archive with `SHA256SUMS.txt`. [Download v0.9.9](https://github.com/engineeringruntime/engineering-runtime-releases/releases/tag/v0.9.9). If you have trouble accessing the artifacts, [contact the project](https://engineeringruntime.com/contact/).
<!-- latest-release:end -->

## Supported platforms

v0.9.9 supports macOS and Linux on amd64 and arm64.
Windows support is not yet available in this release and remains under validation.

Verify the SHA-256 checksum for the exact archive before installation.
If you have trouble accessing the release or installation artifacts, please
[contact the Engineering Runtime project](https://engineeringruntime.com/contact/).

[Upgrade guidance](https://docs.engineeringruntime.com/get-started/upgrading/) ·
[Community](https://github.com/orgs/engineeringruntime/discussions) ·
[Report an Issue](https://github.com/engineeringruntime/engineering-runtime-releases/issues)

### Homebrew (macOS and Linux)

```bash
brew install engineeringruntime/tap/engineering-runtime
runtime version
```

The [`engineeringruntime/homebrew-tap`](https://github.com/engineeringruntime/homebrew-tap)
formula downloads the same versioned archives listed above and verifies the
same published SHA256. It supports macOS (Apple Silicon and Intel) and Linux
(amd64 and arm64); Windows is not yet available.

## Public artifacts, private source

The **artifacts** published in this repository are publicly available so that
anyone — or their AI assistant — can install and run Engineering Runtime
without repository credentials.

Engineering Runtime itself is **proprietary software**. Its source code is
maintained separately and remains **private**.

Public availability of the compiled artifacts does **not** make Engineering
Runtime open source.

Use of the Engineering Runtime binaries is subject to the terms in
[`LICENSE`](./LICENSE).
