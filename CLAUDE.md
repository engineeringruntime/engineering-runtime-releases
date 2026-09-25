# CLAUDE.md — engineering-runtime-releases

**Owner scope revision, 2026-09-20:** v0.9.9 supports only macOS/Linux amd64 and
arm64. WINDOWS QUALIFICATION DEFERRED — NOT QUALIFIED FOR V0.9.9. Run
35501553316 is FAILED / HISTORICAL; it is not a passing qualification. Production
behavior/tests are unchanged. Release-metadata/workflow/docs changes require a
new source freeze and fresh artifacts if Runtime SHA changes. Public product
docs omit internal distribution topology and unavailable Homebrew guidance;
access problems use the project contact page. No merge/tag/publication/Latest
change, deployment, release-gate closure or Windows qualification is authorized.


**Release, installation, Discussions and Issues home for Runtime.** The release
repository is currently private in GitHub organization metadata; anonymous
installation is therefore unavailable until the owner restores public artifact
access. Do not describe authenticated operator access as customer install proof.
Supportive child of the Runtime product hub.

Product hub: [`../CLAUDE.md`](../CLAUDE.md).
ER map: [`../../engineering-runtime-workspace/CLAUDE.md`](../../engineering-runtime-workspace/CLAUDE.md).

---

## What this repo is

The **artifacts live in GitHub Releases, not in git**. The tracked tree contains
distribution documentation, `install.sh`, and verification scripts/tests — never
build outputs or binaries.

| Carried by a GitHub Release | Not in this repo |
|---|---|
| Versioned `runtime` binaries per platform | Runtime source code (→ `../engineering-runtime`) |
| `SHA256SUMS.txt` checksums | Build/staging scratch (ephemeral in the Runtime release workflow) |
| Release notes on the Release itself | Customer upgrade guides (→ `../engineering-runtime-docs`) |

The latest published non-draft, non-prerelease Release is the source of truth
for "what a user can install". The README's marked latest-release block mirrors
that release; the Runtime release workflow owns that block and no other README
content. Check with
`gh release list -R engineeringruntime/engineering-runtime-releases`.

This repository is also the source repository for organization Discussions and
the canonical public Issue tracker. Use the stable organization URL for
conversation links:

<https://github.com/orgs/engineeringruntime/discussions>

---

## Hard rules

1. **Never commit binaries, archives, or checksums into git.** They are Release
   assets. This repo owns distribution documentation and installer tooling, not
   Runtime source or generated release bytes.
2. **This repo does not decide what ships** — `../engineering-runtime` source,
   tests, version metadata and release tag do. Publishing here only distributes
   what that binary already is.
3. **Do not write release notes that claim behavior the binary lacks.** Ground
   every note in the core repo's changes for that version.
4. **Tag naming is not free-form.** Match the existing series. Note that both
   `v0.5.3` and `0.5.3` style tags exist historically, and consumers resolve the
   **latest Release** rather than a tag pattern — do not break that assumption.
5. Publishing is a deliberate act. Do not cut, retag, or delete a Release as a
   side effect of another task.
6. Do not hand-edit content between `latest-release:start` and
   `latest-release:end`; it is generated from the published GitHub Latest
   Release. Discussion titles, bodies and categories remain owner-managed and
   are not release artifacts.

---

## Who consumes this repo

| Consumer | How |
|---|---|
| `../engineering-runtime-ci` | Downloads the release archive, verifies `SHA256SUMS.txt`, puts `runtime` on `PATH` (`.github/actions/setup-runtime/`) |
| `../engineering-runtime-series` | `releases.md` records reviewed publication data and private-access requirements |
| `../engineering-runtime-docs` | Install + upgrade instructions point users here |
| End users | Authenticated direct download while private; anonymous installer only when archive access is public |

CI reads this repository during installation. The public site keeps a static
publication/access summary because anonymous API requests currently return 404.

The intended repository contract is public artifacts and private source. Current
visibility must be checked at release time; authenticated `gh release download`
is not anonymous proof. Downloads should require no GitHub token once visibility
is corrected; `RUNTIME_GITHUB_TOKEN` is only for later governed GitHub operations.

The unreleased v0.9.9 installer hardening verifies exactly one checksum entry
for the selected archive, rejects unexpected/traversal/symlink/special archive
members, requires the expected versioned executable and reports the requested
version before install. It stages the executable in the destination and atomically
renames it into place, preserving an existing install when download, checksum,
archive or staging validation fails. `test-install.sh` is an offline fixture only;
it does not publish, contact GitHub or replace a user's binary. Windows amd64 and arm64 are deferred and not published for v0.9.9.

Stable preparation additionally uses a private random destination-side staging
directory, cleans partial files on failure/signals, rejects duplicate executable
members and streams only the exact executable. A failed-copy regression first
reproduced an orphan with the previous predictable staging filename; the fix must
pass that control before member 10 can close. No authenticated installer mode is
added; private CI downloads remain in the CI repository.

---

## Same-effort updates

When a new version is published here, check in the same effort:

| Also update | Why |
|---|---|
| `../engineering-runtime-docs` release notes | Upgrade impact for existing users |
| `../engineering-runtime-series` releases landing | Public download story |
| `../engineering-runtime-ci` pinned version (if pinned) | Keep install proofs on a real asset |

## Internal distribution reference (retained from README)

The following is historical operator guidance, not public installation copy.
For v0.9.9 the publication set is only macOS/Linux amd64 and arm64; Windows
is deferred and not qualified. Existing v0.9.8 metadata below remains historical.

# Engineering Runtime Releases

This repository is the release home for Engineering Runtime releases,
installation, Discussions and issue reporting. Runtime source is maintained
privately; binary/checksum access follows this repository's visibility. The
intended public distribution path is not yet anonymous while it remains private.

<!-- latest-release:start -->
## Latest release — v0.9.8

Published **2026-09-05**. [Open the full GitHub release](https://github.com/engineeringruntime/engineering-runtime-releases/releases/tag/v0.9.8) or read the [technical release notes](https://docs.engineeringruntime.com/release-notes/).

**What changed:** A Community Runtime can now enroll into an Enterprise Control Plane without changing binaries or weakening local governance.

| Platform | Architecture | Archive |
|---|---|---|
| Linux | amd64 | [`engineering-runtime-v0.9.8-linux-amd64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/engineering-runtime-v0.9.8-linux-amd64.tar.gz) |
| Linux | arm64 | [`engineering-runtime-v0.9.8-linux-arm64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/engineering-runtime-v0.9.8-linux-arm64.tar.gz) |
| macOS | amd64 | [`engineering-runtime-v0.9.8-darwin-amd64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/engineering-runtime-v0.9.8-darwin-amd64.tar.gz) |
| macOS | arm64 | [`engineering-runtime-v0.9.8-darwin-arm64.tar.gz`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/engineering-runtime-v0.9.8-darwin-arm64.tar.gz) |
| Windows | amd64 | [`engineering-runtime-v0.9.8-windows-amd64.zip`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/engineering-runtime-v0.9.8-windows-amd64.zip) |
| Windows | arm64 | [`engineering-runtime-v0.9.8-windows-arm64.zip`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/engineering-runtime-v0.9.8-windows-arm64.zip) |

[Verify every archive with `SHA256SUMS.txt`](https://github.com/engineeringruntime/engineering-runtime-releases/releases/download/v0.9.8/SHA256SUMS.txt).
<!-- latest-release:end -->

## Install

### Homebrew (macOS and Linux)

```bash
brew install engineeringruntime/tap/engineering-runtime
"$(brew --prefix)/bin/runtime" version
```

The public [`engineeringruntime/homebrew-tap`](https://github.com/engineeringruntime/homebrew-tap)
formula supports arm64 and amd64 and verifies the release archive checksum.
Its archive URLs are currently private: anonymous Homebrew install/upgrade fails
with 404. A GitHub CLI login does not authenticate Homebrew downloads. Use an
authorized manual download until anonymous archive access is restored; see
[installation access requirements](https://docs.engineeringruntime.com/get-started/installation/#current-private-distribution-access).

### Verification script

```bash
curl -fsSL https://raw.githubusercontent.com/engineeringruntime/engineering-runtime-releases/main/install.sh | sh
runtime version
```

**The intended release contract is anonymous download**, but this repository is
currently private in GitHub organization metadata (verified 2026-09-20). Until
visibility/access is corrected, unauthenticated users receive 404 and the
installer cannot download a release. Authorized operators may use `gh release
download` with repository read access. CI uses the setup action's `release_token`
input, passed internally as `RUNTIME_RELEASES_TOKEN`; standalone `install.sh`
does not accept that token. Once the release repository is public,
the installer detects your OS and architecture, verifies the published
SHA256 **before** extracting, and fails closed if it does not match.

The unreleased v0.9.9 installer additionally requires exactly one checksum entry,
accepts only the expected versioned archive member tree, rejects traversal and
special/link members, verifies the embedded binary's version, and atomically
stages the replacement. An existing binary is left in place when any check
fails. Run `./test-install.sh` in this repository for offline fixture coverage;
it performs no network or release operation.

Before a public release decision, run the read-only anonymous publication gate:

```bash
scripts/check-anonymous-assets.sh v0.9.9 darwin arm64
```

It checks the selected archive and `SHA256SUMS.txt` with unauthenticated HEAD
requests. A 404 is a publication/visibility failure, not an installer failure;
the current private repository is expected to fail this gate until access is
corrected.

| Variable | Effect |
|---|---|
| `VERSION=<release-tag>` | Install a specific tag instead of the latest, for example `v0.9.8` |
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

The **artifacts** are intended to be public so that anyone — or their AI
assistant — can install and run the runtime without credentials. The Engineering
Runtime **source** repository is maintained separately and remains **private**.
A public artifact is not open source.

[latest]: https://github.com/engineeringruntime/engineering-runtime-releases/releases/latest
