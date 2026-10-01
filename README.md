# Engineering Runtime Releases

Engineering Runtime is a single binary for governed engineering operations.
See [Install Runtime](https://docs.engineeringruntime.com/get-started/installation/)
for archive selection, checksum verification and installation.

## v0.10.0 distribution

v0.10.0 is published through restricted release access. Its archives are
`engrt-v0.10.0-<os>-<arch>`: macOS/Linux use `.tar.gz`; Windows amd64/arm64
use `.zip`. Each contains a versioned directory with `engrt` or `engrt.exe`.
All six published archives match their successful native qualification bytes.

The shell installer installs only `engrt` on macOS/Linux, retaining an existing
`runtime` executable without creating an alias. It requires anonymous artifact
access, which is not enabled for this private release. Authorized operators can
obtain archives with `gh release download v0.10.0 -R engineeringruntime/engineering-runtime-releases`
and follow the checksum-verified [manual installation guide](https://docs.engineeringruntime.com/get-started/installation/).
Windows uses checksum-verified manual ZIP installation;
use `Get-Command engrt -All` to verify PATH. No binaries or checksums are committed
in the repository; they remain GitHub Release assets.

<!-- latest-release:start -->
## Latest release — v0.10.0

Published **2026-10-01**. Read the [technical release notes](https://docs.engineeringruntime.com/release-notes/).

**What changed:** Capability contracts, engrt naming, bounded safety and six native platforms.

| Platform | Architecture | Archive |
|---|---|---|
| Linux | amd64 | `engrt-v0.10.0-linux-amd64.tar.gz` |
| Linux | arm64 | `engrt-v0.10.0-linux-arm64.tar.gz` |
| macOS | amd64 | `engrt-v0.10.0-darwin-amd64.tar.gz` |
| macOS | arm64 | `engrt-v0.10.0-darwin-arm64.tar.gz` |
| Windows | amd64 | `engrt-v0.10.0-windows-amd64.zip` |
| Windows | arm64 | `engrt-v0.10.0-windows-arm64.zip` |

Verify your archive with `SHA256SUMS.txt`. For release access, [contact the project](https://engineeringruntime.com/contact/).
<!-- latest-release:end -->

## Supported platforms

v0.10.0 supports macOS, Linux and Windows on amd64 and arm64.
v0.9.9 retains its historical macOS/Linux-only support scope.

Verify the SHA-256 checksum for the exact archive before installation.
If you have trouble accessing the release or installation artifacts, please
[contact the Engineering Runtime project](https://engineeringruntime.com/contact/).

[Upgrade guidance](https://docs.engineeringruntime.com/get-started/upgrading/) ·
[Community](https://github.com/orgs/engineeringruntime/discussions) ·
[Report an Issue](https://github.com/engineeringruntime/engineering-runtime-releases/issues)

### Homebrew (macOS and Linux) — deferred

The v0.10.0 formula is prepared from the published checksums in tap PR #4, but
its activation and four-platform install verification are deferred until the
owner enables the distribution path. Use authorized manual installation for now.
A GitHub CLI login does not authenticate Homebrew's archive downloads. Windows
uses manual ZIP installation and is outside the formula.

## Distribution access and source

This release repository remains private. Authenticated operator/CI downloads
have been verified; anonymous installation, Homebrew activation and public
launch are separate owner decisions. Repository visibility does not change as
a side effect of publishing a new version. For access, [contact the project](https://engineeringruntime.com/contact/).

Engineering Runtime itself is **proprietary software**. Its source code is
maintained separately and remains **private**.

Making compiled artifacts available does **not** make Engineering Runtime open source.

Use of the Engineering Runtime binaries is subject to the terms in
[`LICENSE`](./LICENSE).

The v0.10.0 shell installer supports only v0.10.0 and later. A pre-0.10.0
`VERSION` pin exits 1 with explicit rollback guidance before asset downloads or
destination writes. Older releases retain `engineering-runtime-*` archives and
`runtime`; use their checksum-verified manual installation in a separate
destination and Home. No automatic downgrade or migration is performed.
