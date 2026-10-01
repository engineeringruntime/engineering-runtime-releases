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

## Install

The release repository is currently **private**. Use the authenticated steps
below with [GitHub CLI](https://cli.github.com/) and an account that has access.
Before upgrading from `runtime`, follow the [upgrade guide](https://docs.engineeringruntime.com/get-started/upgrading/)
to update environment variables and preserve your earlier Runtime Home.

### macOS / Linux

This selects your native platform, verifies the archive checksum and installs
`engrt` in `~/.local/bin`:

```sh
# Authenticate once, if needed.
gh auth login

# Install the pinned release (macOS / Linux, amd64 / arm64).
set -eu
VERSION=v0.10.0
case "$(uname -s)" in Darwin) OS=darwin ;; Linux) OS=linux ;; *) echo 'Unsupported OS'; exit 1 ;; esac
case "$(uname -m)" in arm64|aarch64) ARCH=arm64 ;; x86_64|amd64) ARCH=amd64 ;; *) echo 'Unsupported architecture'; exit 1 ;; esac
ARCHIVE="engrt-$VERSION-$OS-$ARCH.tar.gz"
ENGRT_INSTALL_WORK=$(mktemp -d)
gh release download "$VERSION" -R engineeringruntime/engineering-runtime-releases \
  --pattern "$ARCHIVE" --pattern SHA256SUMS.txt --dir "$ENGRT_INSTALL_WORK"
(
  cd "$ENGRT_INSTALL_WORK"
  awk -v name="$ARCHIVE" '$2 == name { print; count++ } END { if (count != 1) exit 1 }' \
    SHA256SUMS.txt > selected-checksum.txt
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c selected-checksum.txt
  else
    shasum -a 256 -c selected-checksum.txt
  fi
  tar -xzf "$ARCHIVE"
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "engrt-$VERSION-$OS-$ARCH/engrt" "$HOME/.local/bin/engrt"
)
export PATH="$HOME/.local/bin:$PATH"
engrt version
```

The expected version is `engrt 0.10.0`. Keep the PATH setting in your shell profile for future terminals. The earlier
`runtime` executable is not removed, and no `runtime` alias is created.

### PowerShell 7 / Windows

Select `amd64` for x64 Windows or `arm64` for Windows on Arm. This downloads and
verifies the published ZIP before installing `engrt.exe`:

```powershell
$ErrorActionPreference = 'Stop'
# Authenticate once, if needed.
gh auth login

$version = 'v0.10.0'
$arch = 'amd64' # Change to 'arm64' for Windows on Arm.
$package = "engrt-$version-windows-$arch"
$archive = "$package.zip"
$work = Join-Path ([IO.Path]::GetTempPath()) ('engrt-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
gh release download $version -R engineeringruntime/engineering-runtime-releases `
  --pattern $archive --pattern SHA256SUMS.txt --dir $work
if ($LASTEXITCODE -ne 0) { throw 'Release download failed' }
$entries = @(Get-Content (Join-Path $work 'SHA256SUMS.txt') | Where-Object {
  $_ -match ('^[0-9a-fA-F]{64} [ *]' + [regex]::Escape($archive) + '$')
})
if ($entries.Count -ne 1) { throw 'Missing or ambiguous checksum entry' }
$zip = Join-Path $work $archive
if ((Get-FileHash -Algorithm SHA256 $zip).Hash -ine $entries[0].Substring(0, 64)) {
  throw 'Checksum mismatch'
}
Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $work 'extracted')
$bin = Join-Path $HOME '.local\bin'
New-Item -ItemType Directory -Force -Path $bin | Out-Null
Copy-Item -LiteralPath (Join-Path $work "extracted/$package/engrt.exe") -Destination (Join-Path $bin 'engrt.exe')
$env:PATH = "$bin;$env:PATH"
engrt version
if ($LASTEXITCODE -ne 0) { throw 'Installed executable did not run' }
```

The expected version is `engrt 0.10.0`. Add `%USERPROFILE%\.local\bin` to your **user PATH** for future terminals.
Windows currently uses checksum-verified ZIP installation; there is no published
`install.ps1` shortcut yet.

### Public installation shortcuts — available after owner activation

These are the short commands for when repository/artifact access becomes public.
**They do not work anonymously while the repositories remain private.** Homebrew
also requires the prepared v0.10.0 tap update and its installation checks to be
activated; it is not enabled by making this README available.

```sh
# Homebrew (macOS / Linux) — after tap activation.
brew install engineeringruntime/tap/engineering-runtime
engrt version
```

```sh
# Shell installer (macOS / Linux) — after public artifact access.
curl -fsSL https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.sh | sh
engrt version
```

Binary downloads, checksum verification, Windows PATH setup, migration and rollback
are covered in the [Installation Guide](https://docs.engineeringruntime.com/get-started/installation/).

## Supported platforms

v0.10.0 supports macOS, Linux and Windows on amd64 and arm64.
v0.9.9 retains its historical macOS/Linux-only support scope.

Verify the SHA-256 checksum for the exact archive before installation.
If you have trouble accessing the release or installation artifacts, please
[contact the Engineering Runtime project](https://engineeringruntime.com/contact/).

[Upgrade guidance](https://docs.engineeringruntime.com/get-started/upgrading/) ·
[Community](https://github.com/orgs/engineeringruntime/discussions) ·
[Report an Issue](https://github.com/engineeringruntime/engineering-runtime-releases/issues)

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
